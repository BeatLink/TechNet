{
    services.wyoming = {
        piper.servers."piper" = {
            enable = true;
            voice = "en_US-ryan-high"; # or whichever voice you prefer
            uri = "tcp://127.0.0.1:10200";
            extraArgs = [
                "--data-dir"
                "/Storage/Services/Wyoming/voices"
            ];
        };
        faster-whisper.servers."whisper" = {
            enable = true;
            model = "medium-int8"; # good balance of speed vs accuracy
            language = "en";
            uri = "tcp://0.0.0.0:10300";
        };
    };
    environment.persistence."/Storage/Services/Wyoming".directories = [
        {
            directory = "/var/lib/wyoming";
            user = "wyoming-piper";
            group = "wyoming-piper";
            mode = "u=rwx,g=rwx,o=";
        }

    ];
}
