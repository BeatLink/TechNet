# Performance
#
# Tuning for a 2972MB, 1.15GHz A53 phone rather than a laptop or a server: memory, the governor, heat and the session's priority.
#
{
    pkgs,
    ...
}:
{
    # vm.vfs_cache_pressure is lowered from the default 100, because every
    # measurement of what makes an app slow to start on this phone came back
    # dominated by per-file cost rather than by bytes. Reading a directory tree
    # cold, after drop_caches:
    #
    #   eMMC  /nix, 807 files,    3 MiB   1040 ms   1288 us per file
    #   SD    HA profile, 5500 files, 53 MiB  16657 ms   3028 us per file
    #
    # Throughput is about 3 MiB/s either way, so the medium is not what is being
    # measured -- the dentry and inode lookups are. 50 asks the kernel to hold
    # that metadata rather than reclaim it at the same rate as page cache, which
    # is the difference between resolving 5500 dentries off the card again and
    # not.
    #
    # Left well above the aggressive end people use for this. The cache is not
    # free and the phone has 2972MB; the intent is to stop it being thrown away
    # early, not to pin it.
    #
    # swappiness stays at 100 rather than going higher. Swap only ever takes
    # anonymous pages -- clean file pages are dropped and re-read from origin,
    # never written to swap -- so raising it does nothing for the caches above,
    # while zram costs lz4 on a phone whose measured constraint is CPU (pressure
    # 63-72, against io at 3.44).
    boot.kernel.sysctl = {
        "vm.swappiness" = 100;
        "vm.vfs_cache_pressure" = 50;
    };

    # This kernel builds only the lz4 zram backend, so the zstd 0-common asks for silently never applied
    zramSwap.algorithm = "lz4";

    # ibus arrives via services.gnome.core-os-services, which the phosh module
    # turns on -- the same route as the tour and avahi. It is the largest CPU
    # consumer on the phone: ibus-extension held 63-73% across repeated samples
    # and had burned 48 seconds of CPU in the 82 it had been alive, which is a
    # busy loop rather than work.
    #
    # Nothing here uses it. Text entry on screen is stevia, and the keyboard
    # case's Pine layer is xkb. It was removed once before on the theory that it
    # was blocking the on-screen keyboard, which an A/B disproved -- the OSK
    # works either way -- and put back for that reason. The performance case is
    # separate and much stronger.
    i18n.inputMethod.enable = false;

    # schedutil rather than performance, which held all four cores at 1152MHz and top voltage whenever the phone was awake, idle or not
    powerManagement.cpuFreqGovernor = "schedutil";

    # Raise the passive thermal trip from 75C to 80C.
    #
    # Measured idle on this phone, nothing running: 57-59C, throttle state 0 for
    # every sample, full 1152MHz. So there is no thermal problem at rest and 17C
    # of headroom before the trip -- the throttling only appears once sustained
    # load closes that gap, which is what a passively cooled phone does.
    #
    # Under load it crosses 75C, step_wise drops a frequency step, the die cools,
    # the throttle releases, and it does that every few seconds. Five more
    # degrees is five degrees of load before that cycle starts, and after it
    # starts, longer between steps.
    #
    # Deliberately modest against the trips above it, which are unchanged:
    #
    #   80C  passive    this
    #   90C  hot        emergency notification
    #   110C critical   hardware shutdown
    #
    # Ten degrees of margin to `hot` is the point. The reports of PinePhones
    # shutting down without warning and discolouring their screens came from
    # throttling being effectively disabled and the die reaching the 90s, not
    # from a trip moved five degrees.
    #
    # The cost is real and is heat in the hand. This is a v1.2 board, which
    # predates the thermal pads and graphene foil that v1.2a added between the
    # SoC shield and the screen -- so it has less help moving that heat out than
    # a newer unit does. If it becomes unpleasant to hold, this is the knob that
    # did it, and 75000 puts it back.
    #
    # A service rather than a kernel patch because the trip lives in the device
    # tree and sysfs accepts the change at runtime -- the file is 0644 and the
    # write takes effect immediately.
    systemd.services.thermal-trip = {
        description = "Raise the CPU passive thermal trip point";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "thermal-trip" ''
                zone=/sys/class/thermal/thermal_zone0
                # Only if it really is the passive trip -- a kernel change that
                # reorders the trips should not silently move `critical`.
                if [ "$(cat "$zone/trip_point_0_type")" = "passive" ]; then
                    echo 80000 > "$zone/trip_point_0_temp"
                else
                    echo "thermal-trip: trip_point_0 is not passive, leaving it alone" >&2
                fi
            '';
        };
    };

    # The compositor should be the last thing to stall. phoc runs as a child of
    # phosh.service, so it inherits all of this and needs no unit of its own.
    #
    # Worth being clear about what each part actually fixes, because they are
    # not the same freeze:
    #
    #   Nice, CPUWeight, IOWeight  help when something is competing for CPU or
    #                              the card -- a nix copy. Real here, and what
    #                              these are for.
    #
    #   MemoryMin, MemoryLow       help when the stall is memory reclaim, which
    #                              priority cannot touch at all: a high-priority
    #                              process waits on a page fault exactly as long
    #                              as a low-priority one. These reserve memory
    #                              the kernel will not reclaim from the session.
    #
    # Nice = -5 rather than -10. Four 1.15GHz cores do not have the headroom for
    # the compositor to monopolise them, and starving everything else shows up
    # as the session being responsive while nothing it launches ever starts.
    #
    # Negative Nice works despite User = beatlink because systemd applies it in
    # the child before dropping privileges.
    #
    # MemoryMin is a hard floor and MemoryLow best-effort above it. 192M against
    # 2972M total is deliberately modest -- phoc and phosh together sit around
    # 160M measured -- because a floor the system cannot satisfy trades a freeze
    # for an OOM kill.
    systemd.services.phosh.serviceConfig = {
        Nice = -5;
        CPUWeight = 1000;
        IOWeight = 1000;
        OOMScoreAdjust = -500;
        MemoryMin = "192M";
        MemoryLow = "512M";
    };

    # High, not Max: Max OOM-kills the app instead of pushing it to zram
    systemd.user.slices.app.sliceConfig.MemoryHigh = "1800M";

    # GTK4 draws through software Vulkan on this phone unless told otherwise,
    # and cairo is four times faster.
    #
    # The Mali-400 is Utgard: GLES 2.0 hardware, confirmed by phoc, which does
    # get the GPU --
    #
    #   [render/egl.c:376] EGL driver name: lima
    #   [render/gles2/renderer.c:539] Using OpenGL ES 2.0 Mesa 26.1.5
    #   [render/gles2/renderer.c:541] GL renderer: Mali400
    #
    # GTK4's `ngl` renderer wants GLES 3.0, so it cannot start at all here --
    # `gtk4-rendernode-tool benchmark --renderer=gl` answers "Unable to create a
    # GL context" every time. There is no lima Vulkan driver either (panfrost is
    # Midgard/Bifrost), so the only ICD that binds is lavapipe. GSK's selection
    # rejects it, fails to find GL, then comes back and takes it anyway:
    #
    #   Not using Vulkan: device is CPU
    #   Not using GL: Unable to create a GL context
    #   Using renderer 'GskVulkanRenderer' for surface 'GdkWaylandToplevel'
    #
    # So the default path is an LLVM-JIT software rasteriser pretending to be a
    # GPU. Measured with gtk4-demo's paintable_animated -- fixed workload,
    # continuous repaint, 20s, three runs each:
    #
    #                  fps    median paint   p90 paint   first frame
    #   lavapipe    13.8-15.1     ~62ms        ~535ms       ~2460ms
    #   cairo       56.8-57.8     ~10ms         ~11ms          26ms
    #
    # The p90 column is the one that is felt: lavapipe is not uniformly slow, it
    # stalls for half a second periodically, which reads as stutter rather than
    # sluggishness. Independently, gtk4-rendernode-tool on a 720x1441 scene of
    # gradients, rounded clips, borders, text and a blur gave 0.19s per render
    # against 0.47s, with a 5.9-7.8s penalty on lavapipe's first render for
    # pipeline compilation -- paid once per process, so every window that opens.
    #
    # Not a case of cairo skipping work: the same scene rendered through both and
    # compared came out visually identical, blur included.
    #
    # Scope worth knowing. This reaches GTK4 only. phosh is still GTK3
    # (libgtk-3.so.0, libhandy-1.so.0 in the running shell) and GTK3 rasterises
    # with cairo already, so the shell, the lock screen and stevia are unaffected
    # either way -- which also means this cannot destabilise the session.
    #
    # environment.sessionVariables rather than a home-manager variable because
    # phosh.service runs with PAMName = "login", so pam_env applies
    # /etc/pam/environment to the session and everything the app grid launches
    # inherits it. A shell-profile variable would reach an ssh login and nothing
    # the user actually taps.
    #
    # The cairo renderer has thinner feature coverage than the Vulkan one, so the
    # thing to watch is an app that leans on blend modes or masks looking wrong
    # rather than slow. Unsetting this puts lavapipe back.
    environment.sessionVariables.GSK_RENDERER = "cairo";
}
