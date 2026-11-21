# Rock64 #############################################################################################################################################
#
# The Pine64 Rock64 SBC that was Ragnarok until the backup server moved to the Acer. A basic system with no services, kept so the board can be
# brought back up for whatever it does next.
#

{
    technet.secrets.directory = "6-rock64";

    imports = [
        ./1-system
    ];
}
