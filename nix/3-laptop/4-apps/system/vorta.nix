# Vorta Repositories #################################################################################################################################
#
# Vorta no longer runs: Odin's /Storage backups move into the borgmatic repositories, and Vorta's repositories stay as read-only history.
# What is left reads that history: the repos' SSH key and passphrase, the restore canary, Vorta's settings, and the replay into borgmatic.
#
# The key is the identity the repos authorize (`odin-borg-key`), root-owned, so borg can reach them over SSH when it runs under sudo.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    replayState = "/persistent/vorta-merge";
in
{
    sops.secrets.vorta_ssh_key = {
        sopsFile = "${config.technet.secrets.path}/vorta.yaml";
    };

    # Passphrase for the encrypted Vorta repos, which the borg monitors read on this host to unlock them.
    sops.secrets.vorta_backup_passphrase = {
        sopsFile = "${config.technet.secrets.path}/vorta.yaml";
    };

    # X-Monitor restores this file from the newest archive and compares it with the live one, so its content must never change.
    systemd.tmpfiles.settings."Vigil-Canary"."/Storage/Files/.vigil-canary".f = {
        user = "root";
        group = "root";
        mode = "0644";
        argument = "Vigil restore canary";
    };

    # Vorta's settings database names each profile's sources, excludes and retention, so it stays with the history it describes.
    home-manager.users.beatlink.home.persistence."/Storage/Apps/System/Vorta".directories = [
        ".cache/borg"
        ".cache/Vorta"
        ".config/borg"
        ".local/share/Vorta"
        ".local/state/Vorta"
    ];

    # Ragnarok Replay --------------------------------------------------------------------------------------------------------------------------------

    # Copies Ragnarok's Vorta archives into Ragnarok's borgmatic repository, resuming at every boot until all are copied and verified.
    systemd.services.vorta-replay = {
        description = "Replay Ragnarok's Vorta archives into its borgmatic repository";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        startAt = "Sun 10:30";
        restartIfChanged = false;
        unitConfig = {
            # The script leaves `stopped` after a mismatch, so a boot never replays that archive again before someone has looked.
            ConditionPathExists = [
                "${replayState}/bin/replay-vorta.sh"
                "!${replayState}/stopped"
            ];
            StartLimitIntervalSec = 0;
        };
        serviceConfig = {
            ExecCondition = pkgs.writeShellScript "vorta-replay-outside-checks" ''
                [ "$(date +%u)" != 7 ] || [ "$(date +%H%M)" -lt 0145 ] || [ "$(date +%H%M)" -ge 1030 ]
            '';
            ExecStart = lib.concatStringsSep " " [
                "${pkgs.systemd}/bin/systemd-inhibit --what=sleep:shutdown --who=vorta-merge \"--why=Replaying Vorta archives\""
                "${pkgs.bash}/bin/bash ${replayState}/bin/replay-vorta.sh run"
                "ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Vorta"
                "ssh://borg@ragnarok.technet/Storage/Backups/Laptop/Borgmatic"
            ];
            Nice = 10;
            IOSchedulingClass = "idle";
            Restart = "on-failure";
            RestartSec = "15min";
        };
    };

    # Stops the replay while Ragnarok checks its repositories, on the same disk, until vorta-replay's timer starts it again.
    systemd.services.vorta-replay-pause = {
        description = "Pause the Vorta replay for Ragnarok's weekly borg checks";
        startAt = "Sun 01:45";
        serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl stop vorta-replay.service vorta-replay-ragnarok.service";
        };
    };
}
