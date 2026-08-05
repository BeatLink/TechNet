{ pkgs, ... }:
let
    # callaudiod dereferences info->active_port->name in four places without
    # checking it, and PulseAudio is entitled to hand back a sink with no active
    # port. When it does, callaudiod dies:
    #
    #     #0  init_sink_info (callaudiod + 0x9c9c)
    #     #1  context_get_sink_info_callback (libpulse.so.0)
    #
    # 17 crashes across the boots recorded on this phone. Not startup noise
    # either -- the most recent was 100 seconds in, while the session was idle.
    #
    # Upstream has not fixed it. 0.1.99, four releases ahead of the 0.1.10 in
    # nixpkgs, has the same four unguarded dereferences and no guarded ones, so
    # bumping the package would change nothing.
    #
    # g_strcmp0 already treats NULL as a value rather than a fault, and the one
    # remaining use is a g_debug format argument, so a NULL-safe expression is
    # the whole fix at every site.
    callaudiod = pkgs.callaudiod.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../../1-system/patches/callaudiod-speaker-profile.patch ];

        postPatch = (old.postPatch or "") + ''
            substituteInPlace src/cad-pulse.c \
                --replace-fail \
                    "info->active_port->name" \
                    "(info->active_port ? info->active_port->name : NULL)"
        '';
    });
in
{
    programs.calls.enable = true;

    # Optional but recommended. https://github.com/NixOS/nixpkgs/pull/162894
    systemd.services.ModemManager.serviceConfig.ExecStart = [
        "" # clear ExecStart from upstream unit file.
        "${pkgs.modemmanager}/sbin/ModemManager --test-quick-suspend-resume"
    ];

    # Routes call audio between earpiece, speaker and headset. gnome-calls asks
    # for it over the session bus but does not depend on it, so without this a
    # call connects and stays on whatever sink the desktop was already using --
    # audible from the speaker rather than the earpiece, with no way to switch.
    # It ships only a D-Bus service file, so being in the profile is all the
    # session bus needs to activate it on demand.
    environment.systemPackages = [ callaudiod ];

}
