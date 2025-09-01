{
  services.zpool-usage-monitor = {
    enable = true;
    baseUrl = "https://uptime-kuma.heimdall.technet/api/push";
    interval = "10m"; # run every 10 minutes
    pools = [
      { pool = "data-pool"; threshold = "90"; endpoint = "2zvVsdV1ar"; }
      { pool = "root-pool"; threshold = "90"; endpoint = "A9n0Zjzk1n"; }
    ];
  };
}
