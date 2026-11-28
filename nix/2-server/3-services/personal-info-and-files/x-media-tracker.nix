# X-Media-Tracker ####################################################################################################################################
#
# The X-Media-Tracker web app and sync server. Its admins are the accounts file in secrets/2-server/x-media-tracker.yaml, beside the admin's
# generated password; browsers and devices sign in as them.
#
{
    config,
    inputs,
    pkgs,
    ...
}:
{
    imports = [ inputs.x-media-tracker.nixosModules.default ];

    sops.secrets.x_media_tracker_password_hash.sopsFile = "${config.technet.secrets.path}/x-media-tracker.yaml";

    services.x-media-tracker = {
        enable = true;
        port = 9004;
        passwordHashFile = config.sops.secrets.x_media_tracker_password_hash.path;
        # Where paired devices reach this server's sync, through nginx below.
        syncAddress = "https://media-tracker.heimdall.technet/api/";
    };

    environment.persistence."/Storage/Services/X-Media-Tracker".directories = [
        "/var/lib/private/x-media-tracker"
    ];

    # Impermanence leaves the persisted copy world-readable, exposing the library and its Trakt tokens to every local account
    systemd.services.x-media-tracker.serviceConfig.ExecStartPre = [
        "+${pkgs.coreutils}/bin/chmod 0700 /Storage/Services/X-Media-Tracker"
    ];

    nginx-vhosts.x-media-tracker = {
        domain = "media-tracker.heimdall.technet";
        port = 9004;
        extraConfig = {
            # A large library's refresh or Trakt import can pass nginx's 60s default, and a device's first sync its 10M one.
            extraConfig = ''
                proxy_read_timeout 5m;
                client_max_body_size 256m;
            '';
        };
    };
}
