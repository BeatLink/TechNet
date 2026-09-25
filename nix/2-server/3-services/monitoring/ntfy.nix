# ntfy ###############################################################################################################################################
#
# Push notifications for the fleet: Vigil publishes its alerts to the `vigil` topic and the phone subscribes to it.
# Anonymous access is denied; users, the topic grant and Vigil's token are declared through a sops-rendered environment file.
#

{ config, lib, ... }:
{
    config = lib.mkMerge [

        # Server #####################################################################################################################################
        {
            services.ntfy-sh = {
                enable = true;
                settings = {
                    base-url = "https://ntfy.heimdall.technet";
                    listen-http = "127.0.0.1:9420";
                    behind-proxy = true;
                    auth-default-access = "deny-all";
                    enable-login = true;
                };
                environmentFile = config.sops.templates."ntfy.env".path;
            };

            nginx-vhosts.ntfy = {
                domain = "ntfy.heimdall.technet";
                port = 9420;
            };

            environment.persistence."/Storage/Services/Ntfy".directories = [ "/var/lib/private/ntfy-sh" ];
        }

        # Users and Tokens ###########################################################################################################################
        {
            sops.secrets = {
                ntfy_beatlink_password_hash = {
                    sopsFile = "${config.technet.secrets.path}/ntfy.yaml";
                    key = "beatlink_password_hash";
                };
                ntfy_vigil_password_hash = {
                    sopsFile = "${config.technet.secrets.path}/ntfy.yaml";
                    key = "vigil_password_hash";
                };
                ntfy_vigil_token = {
                    sopsFile = "${config.technet.secrets.path}/ntfy.yaml";
                    key = "vigil_token";
                    owner = "vigil";
                };
            };

            sops.templates."ntfy.env" = {
                content = ''
                    NTFY_AUTH_USERS="beatlink:${config.sops.placeholder.ntfy_beatlink_password_hash}:admin,vigil:${config.sops.placeholder.ntfy_vigil_password_hash}:user"
                    NTFY_AUTH_ACCESS="vigil:vigil:wo"
                    NTFY_AUTH_TOKENS="vigil:${config.sops.placeholder.ntfy_vigil_token}:Vigil"
                '';
                restartUnits = [ "ntfy-sh.service" ];
            };
        }
    ];
}
