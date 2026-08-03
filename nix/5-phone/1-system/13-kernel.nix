# Kernel
#
# megi's tree rather than mainline. This is the same source postmarketOS ships,
# and it carries the drivers mainline does not:
#
#   CONFIG_TYPEC_ANX7688=y     the USB-C controller. Without it there is no role
#                              detection, so the UDC never attaches, no Type-C
#                              port registers, and DisplayPort alt mode and
#                              USB-PD are both impossible. One missing driver
#                              costs all three.
#   CONFIG_RTL8723CS=y         WiFi. megi's driver, not mainline's rtw88.
#   CONFIG_IP5XXX_POWER=y      the keyboard case's battery.
#
# It also brings the PinePhone device trees, which describe hardware mainline's
# do not -- the keyboard accessory among them. That is why there is no device
# tree patching here any more: the tree that ships with this kernel is written
# for these drivers, and reshaping it to look like mainline's would be wrong.
#
# Built with nixpkgs' linuxManualConfig, taking only the source, config and
# patches from mobile-nixos' device directory rather than its kernel-builder.
# That builder cannot work here:
#
#   - Its postInstall deletes lib/modules/*/build and lib/modules/*/source, and
#     it produces no `dev` output, so there is no build tree to compile
#     out-of-tree modules against. Reasonable for a phone with everything built
#     in; fatal here, because Thor's root is ZFS and ZFS is out-of-tree.
#   - It omits `features`, `config` and `commonMakeFlags`, each of which NixOS
#     reads at evaluation time. linuxManualConfig supplies all three.
#   - Its full device import would also bring mobile.* options, a u-boot system
#     type and its own stage-1, which would fight disko, impermanence and
#     systemd-boot.
#
# mobile-nixos' firmware package is still used, from 1-hardware-configuration.nix.
# It takes only stock nixpkgs arguments, so no overlay is needed for it.
#
# Not in any binary cache -- not in nixpkgs, not in cache.nixos.org -- so this is
# a full aarch64 kernel build, and ZFS builds against it afterwards. Ragnarok is
# the only native aarch64 host; 9-remote-builder.nix on that side caps
# parallelism for the 2GB it has.
#
{
    pkgs,
    lib,
    inputs,
    ...
}:
let
    kernelDir = "${inputs.mobile-nixos}/devices/pine64-pinephone/kernel";
    baseConfig = "${kernelDir}/config.aarch64";

    # Options added on top of megi's config.
    #
    # megi ships `# CONFIG_EFI is not set`, which suits the extlinux boot
    # postmarketOS uses. Thor goes through Tow-Boot's UEFI into systemd-boot,
    # which loads the kernel as an EFI application and so needs the stub. On
    # arm64 EFI selects EFI_STUB itself, and the dependencies EFI does have --
    # OF, KERNEL_MODE_NEON, and not CPU_BIG_ENDIAN -- are already met.
    #
    # Single source of truth: this drives the generated config file, the
    # assertion that the options survived oldconfig, and the evaluation-time
    # `config` below, so the three cannot drift apart.
    injected = {
        CONFIG_EFI = "y";
        CONFIG_EFI_STUB = "y";
    };

    injectedLines = lib.mapAttrsToList (name: value: "${name}=${value}") injected;

    # Matches what nixpkgs' own readConfig does: only `=y` and `=m` lines are
    # parsed, and `# ... is not set` is simply absent, which is what isDisabled
    # leans on. Passed explicitly because `configfile` below is a derivation
    # rather than a path, which would otherwise force import-from-derivation.
    readConfig =
        file:
        lib.listToAttrs (
            lib.concatMap (
                line:
                let
                    m = lib.match "(CONFIG_[^=]+)=([ym])" line;
                in
                lib.optional (m != null) {
                    name = lib.elemAt m 0;
                    value = lib.elemAt m 1;
                }
            ) (lib.splitString "\n" (builtins.readFile file))
        );

    configfile = pkgs.runCommand "pinephone-kernel-config" { } (
        ''
            cat ${baseConfig} > $out
        ''
        + lib.concatMapStrings (line: ''
            echo '${line}' >> $out
        '') injectedLines
    );

    kernel = pkgs.linuxManualConfig {
        inherit configfile;
        version = "6.17.5";

        src = pkgs.fetchFromGitea {
            domain = "codeberg.org";
            owner = "megi";
            repo = "linux";
            rev = "orange-pi-6.17-20251026-1441";
            hash = "sha256-SoHvTjmdZb2m3tY5pK60d64d35wc5apOiYzzep3X7wM=";
        };

        config = readConfig baseConfig // injected;

        # The systemd-boot module asserts `features ? efiBootStub` and fails with
        # "This kernel does not support the EFI boot stub" otherwise. It is a
        # claim about the kernel rather than a switch, so it has to agree with
        # the CONFIG_EFI injection above or the assertion is a lie that surfaces
        # at boot instead of at evaluation.
        features = {
            efiBootStub = true;
        };

        kernelPatches = [
            {
                name = "pinephone-default-on-and-panic-leds";
                patch = "${kernelDir}/0001-dts-pinephone-Setup-default-on-and-panic-LEDs.patch";
            }
            {
                # Reserves 128MiB of CMA, documented as required for the cameras.
                name = "pinephone-128mib-cma";
                patch = pkgs.fetchpatch {
                    url = "https://github.com/mobile-nixos/linux/commit/372597b5449b7e21ad59dba0842091f4f1ed34b2.patch";
                    sha256 = "1lca3fdmx2wglplp47z2d1030bgcidaf1fhbnfvkfwk3fj3grixc";
                };
            }
            {
                # Drops modem-power from the DT so eg25-manager has full control.
                name = "pinephone-drop-modem-power";
                patch = pkgs.fetchpatch {
                    url = "https://gitlab.com/postmarketOS/pmaports/-/raw/164e9f010dcf56642d8e6f422a994b927ae23f38/device/main/linux-postmarketos-allwinner/0007-dts-pinephone-drop-modem-power-node.patch";
                    sha256 = "nYCoaYj8CuxbgXfy5q43Xb/ebe5DlJ1Px571y1/+lfQ=";
                };
            }
        ];
    };
in
{
    boot.kernelPackages = pkgs.linuxPackagesFor (
        kernel.overrideAttrs (old: {
            # Regmap debugfs writes, to reach the AXP803's charger registers from
            # userspace. Deliberately not a Kconfig option -- regmap-debugfs.c
            # carries an `#undef` above the guard and a comment saying anyone who
            # wants it must edit the source, singling out PMICs as the reason, so
            # -D on the command line is discarded before it is read. Flipping it
            # to `#define` covers both the write fop and the 0600 mode on
            # `registers`, which is otherwise 0400.
            #
            # This is what makes the battery thermistor threshold testable
            # without a rebuild per attempt -- see docs/thor.md. replace-fail so
            # the build breaks loudly if that line ever moves.
            postPatch = (old.postPatch or "") + ''
                echo ":: Allowing regmap register writes through debugfs"
                substituteInPlace drivers/base/regmap/regmap-debugfs.c \
                    --replace-fail \
                        "#undef REGMAP_ALLOW_WRITE_DEBUGFS" \
                        "#define REGMAP_ALLOW_WRITE_DEBUGFS"
            '';

            # oldconfig drops options whose dependencies are unmet *silently*, so
            # the result is checked rather than assumed. A wrong guess should cost
            # two minutes here instead of a full kernel build on a 2GB machine.
            postConfigure = lib.concatMapStrings (opt: ''
                if ! grep -q '^${opt}=${injected.${opt}}$' "$buildRoot/.config"; then
                    echo "error: ${opt} did not survive oldconfig"
                    exit 1
                fi
            '') (lib.attrNames injected);
        })
    );
}
