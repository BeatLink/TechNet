# Mission Center
#
# Odin's system monitor: CPU, memory, disks, network and GPU, plus a process
# list. Replaces stacer and GNOME System Monitor.
#
# The persistence below covers the app's own files. Its preferences — which
# performance pages are shown, column order, window size — are GSettings and
# live in dconf, so they are exported into this folder by
# `nixtool run maintenance/export-dconf` and loaded back by
# 0-common/1-system/desktop/dconf.nix.
#
# Its "Enabling Additional Values" dialog offers a setup script that cannot work
# here: it setcaps nethogs in place and drops a udev rule calling /usr/bin/chmod.
# Both are done declaratively below instead. The script's third step,
# `sensors-detect --auto`, finds no sensors on this laptop, whose fans the EC
# drives over ACPI, so there is nothing to carry over for fans.
#
# Links:
#     - https://gitlab.com/mission-center-devs/mission-center/-/wikis/Home/CPU
#     - https://gitlab.com/mission-center-devs/mission-center/-/wikis/Home/Nethogs
{ pkgs, ... }:
{
    # Per-process network usage: Mission Center runs nethogs by name, so a wrapper carrying its capabilities in /run/wrappers/bin is the one it finds.
    security.wrappers.nethogs = {
        source = "${pkgs.nethogs}/bin/nethogs";
        capabilities = "cap_net_admin,cap_net_raw,cap_dac_read_search,cap_sys_ptrace+ep";
        owner = "root";
        group = "root";
    };

    # CPU power draw: the RAPL energy counters are root-only, because reading them fast enough leaks secrets (PLATYPUS).
    # Opened to wheel rather than to everyone, since this host also runs the tang server that unlocks the others.
    services.udev.extraRules = ''
        SUBSYSTEM=="powercap", KERNEL=="intel-rapl*", RUN+="${pkgs.coreutils}/bin/chgrp wheel /sys/%p/energy_uj", RUN+="${pkgs.coreutils}/bin/chmod g+r /sys/%p/energy_uj"
    '';

    home-manager.users.beatlink =
        { pkgs, ... }:
        {
            home = {
                packages = with pkgs; [ mission-center ];
                persistence."/Storage/Apps/System/Mission-Center" = {
                    directories = [
                        ".config/MissionCenter"
                        ".local/share/MissionCenter"
                    ];

                };
            };
        };
}
