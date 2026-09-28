# ActivityWatch ######################################################################################################################################
#
# Gathers the window and idle history of every monitored host into one web UI, by importing the aw-sync exports they leave in the shared folder.
# It only pulls: aw-sync would push the imported buckets back out under this host's name, and the monitors would import them again.
#

{
    config,
    lib,
    pkgs,
    ...
}:
let
    awServer = pkgs.aw-server-rust;
    syncDir = "/Storage/Files/ActivityWatch"; # The Syncthing folder of that name, which Thor's exports also reach by rsync
    port = 5600;
    stateDir = "/var/lib/activitywatch";

    thorToHeimdall = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2KzwzM/NIrIVXNuKr7tl94i3IUfA3uYnDACTBhXcSM activitywatch-thor-to-heimdall";

    # aw-server keeps its device id and config under the XDG directories, which in beatlink's home would not survive a boot
    environment = {
        HOME = stateDir;
        XDG_CONFIG_HOME = "${stateDir}/config";
        XDG_DATA_HOME = "${stateDir}/data";
        XDG_CACHE_HOME = "${stateDir}/cache";
    };
in
{
    config = lib.mkMerge [

        # Server #####################################################################################################################################
        {
            # beatlink, because Syncthing writes the shared folder as that user and aw-sync opens the databases in it for writing
            systemd.services.aw-server = {
                description = "ActivityWatch server";
                wantedBy = [ "multi-user.target" ];
                after = [ "network.target" ];
                unitConfig.RequiresMountsFor = [ stateDir ];
                inherit environment;
                serviceConfig = {
                    User = "beatlink";
                    Group = "beatlink";
                    ExecStart = "${lib.getExe awServer} --host 127.0.0.1 --port ${toString port} --dbpath ${stateDir}/sqlite.db";
                    Restart = "on-failure";
                    RestartSec = 10;
                };
            };

            environment.persistence."/Storage/Services/ActivityWatch".directories = [
                {
                    directory = stateDir;
                    user = "beatlink";
                    group = "beatlink";
                    mode = "0700";
                }
            ];
        }

        # Import #####################################################################################################################################
        {
            systemd.services.aw-sync = {
                description = "Import every monitored host's ActivityWatch export";
                requires = [ "aw-server.service" ];
                after = [ "aw-server.service" ];
                unitConfig.RequiresMountsFor = [
                    stateDir
                    syncDir
                ];
                inherit environment;
                serviceConfig = {
                    Type = "oneshot";
                    User = "beatlink";
                    Group = "beatlink";
                    ExecStart = "${awServer}/bin/aw-sync --port ${toString port} --sync-dir ${syncDir} sync-advanced --mode pull";
                };
            };

            systemd.timers.aw-sync = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnBootSec = "5m";
                    OnUnitActiveSec = "5m";
                };
            };

            # Thor is outside the Syncthing mesh, so its key may write files under the shared folder and do nothing else on this host
            users.users.beatlink.openssh.authorizedKeys.keys = [
                ''restrict,command="${pkgs.rrsync}/bin/rrsync -wo ${syncDir}" ${thorToHeimdall}''
            ];
        }

        # Reverse Proxy ##############################################################################################################################
        {
            nginx-vhosts.activitywatch = {
                domain = "activitywatch.heimdall.technet";
                inherit port;
            };

            # The server refuses any Host header but its own loopback name, so the proxy has to send that one
            services.nginx.virtualHosts.activitywatch.locations."/" = {
                recommendedProxySettings = lib.mkForce false;
                extraConfig = "proxy_set_header Host localhost;";
            };
        }
    ];
}
