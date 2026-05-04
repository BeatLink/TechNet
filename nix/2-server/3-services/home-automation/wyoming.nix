{
    services.wyoming.piper.servers."piper" = {
        enable = true;
        voice = "en_US-ryan-high"; # or whichever voice you prefer
        uri = "tcp://127.0.0.1:10200";
        extraArgs = [
            "--data-dir"
            "/Storage/Services/Wyoming/voices"
        ];
    };
}
