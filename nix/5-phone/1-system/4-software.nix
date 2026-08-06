# Software
#
# Configures software settings
#
# htop is off here and on everywhere else. 0-common is composed into all four
# hosts, so the opt-out lives at the host end rather than as a removed import --
# see 0-common/4-apps/7-htop.nix.

{
    system.stateVersion = "25.05";                                                  # Sets the system state version

    technet.htop.enable = false;
}
