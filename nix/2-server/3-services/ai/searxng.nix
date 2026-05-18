{
    pkgs,
    ...
}:
{
    services.searx = {
        enable = true;
        package = pkgs.searxng;
        redisCreateLocally = true;
        environmentFile = "/Storage/Services/SearxNG/searxng.env";
        settings = {
            server = {
                bind_address = "127.0.0.1";
                port = 8295;
                limiter = false;
            };
            search = {
                # engines to enable — DuckDuckGo + Google by default via use_default_settings
                safe_search = 0;
                autocomplete = "";
            };
        };
    };
    nginx-vhosts.searxng = {
        domain = "searxng.heimdall.technet";
        port = 8295;
    };
}
