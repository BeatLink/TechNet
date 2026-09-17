# Gallery-DL #########################################################################################################################################
#
# Downloads galleries, and records the page each one came from so BlockURL can hide it from the browser once it has been downloaded.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    apiUrl = "https://blockurl.heimdall.technet";
    apiKeyFile = config.sops.secrets.blockurl_api_key.path;

    stateDir = "/Storage/Apps/Tools/Gallery-DL/blockurl"; # Beside the archives the hand-written config.json already keeps there
    pendingLog = "${stateDir}/pending.txt";
    cursorFile = "${stateDir}/cursor";

    # Resolves the browsable page a downloaded post came from; extend the per-site rules as new sites come up.
    recorder = pkgs.writeText "blockurl-record.py" ''
        """Append the page URL of each post gallery-dl downloads to the BlockURL pending log."""

        import os

        LOG = "${pendingLog}"


        def page_url(kwdict):
            """Return the page a post is browsable at, or None when the site exposes no such field."""
            for key in ("post_url", "webpage_url", "gallery_url"):
                url = kwdict.get(key)
                if url:
                    return url
            category = kwdict.get("category")
            if category == "reddit" and kwdict.get("permalink"):
                return "https://www.reddit.com" + kwdict["permalink"]
            if category == "twitter" and kwdict.get("tweet_id"):
                author = kwdict.get("author") or kwdict.get("user") or {}
                if author.get("name"):
                    return "https://x.com/%s/status/%s" % (author["name"], kwdict["tweet_id"])
            return None


        def record(kwdict):
            """Post hook: log the post's page URL, leaving the sync timer to send it on."""
            url = page_url(kwdict)
            if not url:
                return
            os.makedirs(os.path.dirname(LOG), exist_ok=True)
            with open(LOG, "a", encoding="utf-8") as log:
                log.write(url + "\n")
    '';

    # Falls back to the URL handed to gallery-dl when the run recorded no page of its own, which is the only URL a booru or a forum offers.
    galleryDl = pkgs.writeShellApplication {
        name = "gallery-dl";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
            log=${lib.escapeShellArg pendingLog}

            size() {
                if [ -e "$log" ]; then stat -c %s "$log"; else echo 0; fi
            }

            before=$(size)
            status=0
            ${pkgs.gallery-dl}/bin/gallery-dl "$@" || status=$?

            if [ "$status" -eq 0 ] && [ "$(size)" = "$before" ]; then
                mkdir -p "$(dirname "$log")"
                for argument in "$@"; do
                    case "$argument" in
                        http://*|https://*) printf '%s\n' "$argument" >>"$log" ;;
                        *) ;;
                    esac
                done
            fi

            exit "$status"
        '';
    };

    sync = pkgs.writers.writePython3Bin "gallery-dl-blockurl-sync" { flakeIgnore = [ "E501" ]; } ''
        import json
        import os
        import sys
        import urllib.error
        import urllib.request

        API = "${apiUrl}"
        KEY_FILE = "${apiKeyFile}"
        LOG = "${pendingLog}"
        CURSOR = "${cursorFile}"
        BATCH = 1000


        def api_key():
            """Read the key out of the NAME=value line the secret is stored as."""
            line = open(KEY_FILE, encoding="utf-8").read().strip()
            return line.partition("=")[2] if "=" in line else line


        def cursor():
            """Byte offset in the log up to which URLs have already been sent."""
            try:
                return int(open(CURSOR, encoding="utf-8").read().strip() or 0)
            except (OSError, ValueError):
                return 0


        def pending(start):
            """URLs written to the log since 'start', and the offset they end at."""
            with open(LOG, "rb") as log:
                log.seek(start)
                data = log.read()
            # Stop at the last newline, so a line gallery-dl is midway through writing is left for tomorrow.
            data = data[: data.rfind(b"\n") + 1]
            urls = []
            for line in data.decode("utf-8", "replace").splitlines():
                line = line.strip()
                if line.startswith(("http://", "https://")) and line not in urls:
                    urls.append(line)
            return urls, start + len(data)


        def block(key, urls):
            """Send one batch of URLs to BlockURL."""
            request = urllib.request.Request(
                API + "/urls/block",
                data=json.dumps({"urls": urls}).encode(),
                headers={"Content-Type": "application/json", "X-API-Key": key},
                method="POST",
            )
            with urllib.request.urlopen(request, timeout=60) as response:
                response.read()


        def main():
            if not os.path.exists(LOG):
                print("nothing downloaded yet", flush=True)
                return
            start = cursor()
            if os.path.getsize(LOG) < start:
                start = 0
            urls, end = pending(start)
            if urls:
                key = api_key()
                for index in range(0, len(urls), BATCH):
                    block(key, urls[index:index + BATCH])
            if end != start:
                with open(CURSOR, "w", encoding="utf-8") as handle:
                    handle.write(str(end))
            print("blocked", len(urls), "new URLs", flush=True)


        try:
            main()
        except (urllib.error.URLError, OSError) as error:
            # The cursor is left where it was, so an unreachable server just means tomorrow's run sends today's URLs too.
            print("blockurl sync failed:", error, file=sys.stderr, flush=True)
            sys.exit(1)
    '';
in
{
    config = lib.mkMerge [

        # BlockURL API Key ###########################################################################################################################
        {
            # Heimdall's own copy of this key lives in 2-server/blockurl.nix; .sops.yaml names Odin as a second recipient of the file.
            sops.secrets.blockurl_api_key = {
                sopsFile = "${config.technet.secrets.root}/2-server/blockurl.yaml";
                owner = "beatlink";
                mode = "0400";
            };
        }

        # Gallery-DL #################################################################################################################################
        {
            # gallery-dl merges /etc over its own hand-written config.json, so the recorder is added without Nix owning that file.
            environment.etc."gallery-dl.conf".source = (pkgs.formats.json { }).generate "gallery-dl.conf" {
                extractor.postprocessors = [
                    {
                        name = "python";
                        event = "post";
                        function = "${recorder}:record";
                    }
                ];
            };

            home-manager.users.beatlink = {
                programs.gallery-dl = {
                    enable = true;
                    package = galleryDl;
                };

                home.persistence."/Storage/Apps/Tools/Gallery-DL".directories = [
                    ".config/gallery-dl"
                ];
            };
        }

        # BlockURL Sync ##############################################################################################################################
        {
            home-manager.users.beatlink = {
                home.packages = [ sync ];

                systemd.user.services.gallery-dl-blockurl-sync = {
                    Unit.Description = "Send the pages gallery-dl downloaded from to BlockURL";
                    Service = {
                        Type = "oneshot";
                        ExecStart = lib.getExe sync;
                    };
                };

                systemd.user.timers.gallery-dl-blockurl-sync = {
                    Unit.Description = "Daily BlockURL sync of gallery-dl downloads";
                    Timer = {
                        OnCalendar = "daily";
                        Persistent = true; # The laptop is asleep at most fixed times, so the run has to be caught up rather than missed
                        RandomizedDelaySec = "30m";
                    };
                    Install.WantedBy = [ "timers.target" ];
                };
            };
        }
    ];
}
