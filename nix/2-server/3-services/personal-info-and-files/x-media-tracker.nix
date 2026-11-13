# X-Media-Tracker ####################################################################################################################################
#
# The X-Media-Tracker web app and sync server. Its admins are the same accounts file as X-Fitness's, in secrets/2-server/x-fitness.yaml; browsers and
# devices sign in as them.
#
{
    config,
    inputs,
    pkgs,
    ...
}:
{
    imports = [ inputs.x-media-tracker.nixosModules.default ];

    sops.secrets.x_media_tracker_password_hash = {
        sopsFile = "${config.technet.secrets.path}/x-fitness.yaml";
        key = "x_fitness_password_hash";
    };

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
        domain = "media.heimdall.technet";
        port = 9004;
    };
}
