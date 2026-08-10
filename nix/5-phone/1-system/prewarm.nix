# Prewarm ############################################################################################################################################
{ inputs, ... }:
{
    imports = [ inputs.prewarm.nixosModules.default ];

    services.prewarm = {
        enable = true;
        group = "beatlink";
        # Overrunning this drops pages by path order, not by usefulness
        maxLocked = 384 * 1024 * 1024;

        # Watch --------------------------------------------------------------------------------------------------------------------------------------
        watch = {
            enable = true;
            interval = 300;
            retention = 86400;
            settle = 20;
            minGap = 60;
        };

        # Profiles -----------------------------------------------------------------------------------------------------------------------------------
        profiles = {
            weblaunch.dirs = [
                "/home/beatlink/.local/share/weblaunch"
            ];
        };
    };

    # Persistence ------------------------------------------------------------------------------------------------------------------------------------
    environment.persistence."/persistent".directories = [ "/var/lib/prewarm" ];
}
