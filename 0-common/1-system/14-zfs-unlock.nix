{ config, pkgs, lib, ... }:

let
  unlockScript = pkgs.writeShellScript "zfs-unlock-initrd" ''
    #!/usr/bin/env bash
    set -euo pipefail

    REMOTE_HOST="$1"
    REMOTE_USER="$2"
    SSH_KEY="$3"
    DATABASE="$4"
    shift 4
    POOLS=("$@")

    SSH=${pkgs.openssh}/bin/ssh
    ZFS=${pkgs.zfs}/bin/zfs

    for POOL in "$\{POOLS[@]}"; do
      echo "Fetching key for $POOL from $REMOTE_HOST..."
      KEY=$($SSH -i "$SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=yes \
        "$REMOTE_USER@$REMOTE_HOST" \
        "dbus-send --session --dest=org.keepassxc.KeePassXC --print-reply \
          /org/keepassxc/KeePassXC/MainWindow \
          org.keepassxc.KeePassXC.MainWindow.GetPassword string:'$POOL' | \
          grep string | cut -d '\"' -f2")
      echo "Unlocking $POOL..."
      echo "$KEY" | $ZFS load-key "$POOL"
    done
  '';
in
{
  ######################
  # Options
  ######################
  options.services.zfsUnlock = {
    enable = lib.mkEnableOption "Enable local initrd ZFS unlock";

    pools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "rpool" "tank" ];
      description = "ZFS pools to unlock at boot";
    };

    sshKey = lib.mkOption {
      type = lib.types.path;
      default = "";
      description = "SSH private key used to fetch KeePassXC secrets from the remote host";
    };

    remoteHost = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Remote host where KeePassXC database resides";
    };

    remoteUser = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Existing user on the remote system with access to KeePassXC database";
    };

    remoteDatabasePath = lib.mkOption {
      type = lib.types.path;
      default = "/home/remoteuser/passwords.kdbx";
      description = "Path to KeePassXC database on the remote system";
    };
  };

  ######################
  # Local system
  ######################
  config = lib.mkIf config.services.zfsUnlock.enable rec {
    boot.initrd = {
      network.enable = true;
      initrdPackages = with pkgs; [ bash zfs openssh ];

      # Pass SSH key to initrd
      secrets."zfs-unlock-key" = config.services.zfsUnlock.sshKey;

      systemd.services."zfs-unlock" = {
        description = "Unlock ZFS pools from remote over SSH before root fs is mounted";
        before = [ "initrd-root-fs.target" ];
        wantedBy = [ "initrd.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = ''
            "${unlockScript}" \
              ${config.services.zfsUnlock.remoteHost} \
              ${config.services.zfsUnlock.remoteUser} \
              /run/initrd/secrets/zfs-unlock-key \
              ${config.services.zfsUnlock.remoteDatabasePath} \
              ${lib.concatStringsSep " " config.services.zfsUnlock.pools}
          '';
        };
      };
    };
  };
}
