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
            # A library refresh or a Trakt import answers only once every title is done, which for a large library can pass nginx's 60s default.
            extraConfig = ''
                proxy_read_timeout 5m;
            '';
        };
    };
}
