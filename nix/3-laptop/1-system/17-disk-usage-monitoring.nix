{
  services.zpool-usage-monitor = {
    enable = true;
    baseUrl = "https://uptime-kuma.heimdall.technet/api/push";
    interval = "10m"; # run every 10 minutes
    pools = [
      { pool = "data-pool"; threshold = "90"; endpoint = "lKhOXk3VQ9"; }
      { pool = "root-pool"; threshold = "90"; endpoint = "BkWAwCBjmu"; }
    ];
  };
}
