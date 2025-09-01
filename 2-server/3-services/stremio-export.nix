{ pkgs, ... }:

let
    exportScript = pkgs.writeShellScriptBin "stremio-export" ''
        #!/bin/sh
        outdir="/Storage/Services/Stremio"
        mkdir -p "$outdir"

        urlFile="$outdir/export-url.txt"
        if [ ! -f "$urlFile" ]; then
            echo "Error: $urlFile not found" >&2
            exit 1
        fi

        url=$(cat "$urlFile")
        datestamp="$(date +%Y-%m-%d)"
        datedFile="$outdir/StremioExport-$datestamp.json"
        latestFile="$outdir/StremioExport-latest.json"

        # Fetch JSON once and save to both files
        ${pkgs.curl}/bin/curl -sS "$url" -o "$datedFile" && cp "$datedFile" "$latestFile"
    '';
in {
    systemd.services.stremio-export = {
        description = "Fetch Stremio export JSON";
        serviceConfig = {
            ExecStart = "${exportScript}/bin/stremio-export";
            Type = "oneshot";
            User = "root"; # or adjust if you want a non-root user
        };
    };

    systemd.timers.stremio-export = {
        description = "Run Stremio export daily";
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "daily"; # runs once every day at midnight
            Persistent = true;
        };
    };
}
