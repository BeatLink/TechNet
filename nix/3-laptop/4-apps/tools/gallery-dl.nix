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
    database = "${stateDir}/urls.sqlite3";

    # Resolves the browsable page a downloaded file came from; extend the per-site rules as new sites come up.
    recorder = pkgs.writeText "blockurl-record.py" ''
        """Record the page URL behind each file gallery-dl has downloaded."""

        import os
        import sqlite3

        DB = "${database}"

        _connection = None


        def connection():
            """Open the URL database once per run, creating it on first use."""
            global _connection
            if _connection is None:
                os.makedirs(os.path.dirname(DB), exist_ok=True)
                _connection = sqlite3.connect(DB, timeout=60)
                _connection.execute(
                    "CREATE TABLE IF NOT EXISTS urls (url TEXT PRIMARY KEY, sent INTEGER NOT NULL DEFAULT 0)"
                )
                _connection.commit()
            return _connection


        def page_url(kwdict):
            """Return the page a file is browsable at, or None when nothing identifies one."""
            # Site rules come first: they match the address bar, while a site's own post_url can carry a slug the browser drops.
            category = kwdict.get("category")
            identifier = kwdict.get("id")
            if category == "reddit" and kwdict.get("permalink"):
                return "https://www.reddit.com" + kwdict["permalink"]
            if category == "redgifs" and identifier:
                return "https://www.redgifs.com/watch/%s" % identifier
            if category == "tumblr" and kwdict.get("blog_name") and identifier:
                return "https://%s.tumblr.com/post/%s" % (kwdict["blog_name"], identifier)
            if category == "twitter" and kwdict.get("tweet_id"):
                author = kwdict.get("author") or kwdict.get("user") or {}
                if author.get("name"):
                    return "https://x.com/%s/status/%s" % (author["name"], kwdict["tweet_id"])
            for key in ("post_url", "webpage_url", "gallery_url"):
                url = kwdict.get(key)
                if url:
                    return url
            return None


        def record(kwdict):
            """Download hook: note the page behind a file that is on disk, leaving the sync timer to send it on."""
            url = page_url(kwdict)
            if not url:
                return
            # The addon strips one trailing slash before both blocking and checking, so a stored URL keeping one never matches.
            if url.endswith("/"):
                url = url[:-1]
            con = connection()
            con.execute("INSERT OR IGNORE INTO urls (url) VALUES (?)", (url,))
            con.commit()
    '';

    sync = pkgs.writers.writePython3Bin "gallery-dl-blockurl-sync" { flakeIgnore = [ "E501" ]; } ''
        import json
        import os
        import sqlite3
        import sys
        import urllib.error
        import urllib.request

        API = "${apiUrl}"
        KEY_FILE = "${apiKeyFile}"
        DB = "${database}"
        BATCH = 1000


        def api_key():
            """Read the key out of the NAME=value line the secret is stored as."""
            line = open(KEY_FILE, encoding="utf-8").read().strip()
            return line.partition("=")[2] if "=" in line else line


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
            if not os.path.exists(DB):
                print("nothing downloaded yet", flush=True)
                return
            con = sqlite3.connect(DB, timeout=60)
            urls = [row[0] for row in con.execute("SELECT url FROM urls WHERE sent = 0")]
            sent = 0
            for index in range(0, len(urls), BATCH):
                batch = urls[index:index + BATCH]
                block(api_key(), batch)
                # Marked a batch at a time, so a failure part way through does not resend what BlockURL already took.
                con.executemany("UPDATE urls SET sent = 1 WHERE url = ?", [(url,) for url in batch])
                con.commit()
                sent += len(batch)
            con.close()
            print("blocked", sent, "new URLs", flush=True)


        try:
            main()
        except (urllib.error.URLError, OSError, sqlite3.Error) as error:
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
                        # Both hooks run only for a file that is on disk; a failed download goes to the error hook instead.
                        event = "after,skip";
                        function = "${recorder}:record";
                    }
                ];
            };

            home-manager.users.beatlink = {
                programs.gallery-dl.enable = true;

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
