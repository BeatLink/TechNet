{ config, pkgs, ... }:

let
    logFile = "/var/log/ddns-update.log";
    urlFile = "/etc/ddns-url";
in
{
    ############################################
    # DDNS Service
    ############################################

    systemd.services.ddns-update = {
        description = "Dynamic DNS Update";
        serviceConfig = {
            Type = "oneshot";

            ExecStart = ''
                ${pkgs.bash}/bin/bash -c '
                  URL="$(cat ${urlFile})"
                  TIMESTAMP="$(${pkgs.coreutils}/bin/date --iso-8601=seconds)"
                  RESPONSE="$(${pkgs.curl}/bin/curl \
                    --fail \
                    --show-error \
                    --silent \
                    "$URL" 2>&1)"
                  EXIT_CODE=$?

                  echo "[$TIMESTAMP] Exit: $EXIT_CODE Response: $RESPONSE" >> ${logFile}
                  exit $EXIT_CODE
                '
            '';

            User = "root";

            # Hardening
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
        };
    };

    ############################################
    # Timer (every 6 hours)
    ############################################

    systemd.timers.ddns-update = {
        description = "Run Dynamic DNS update every 6 hours";
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnBootSec = "5min";
            OnUnitActiveSec = "6h";
            Unit = "ddns-update.service";
        };
    };

    ############################################
    # Impermanence persistence
    ############################################

    environment.persistence."/Storage/Services/DDNS" = {
        files = [
            urlFile
            logFile
        ];
    };
}
