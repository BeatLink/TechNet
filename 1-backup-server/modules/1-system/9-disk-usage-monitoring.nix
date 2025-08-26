{
  services.disk-usage-monitor = {
    enable = true;
    baseUrl = "https://uptime-kuma.heimdall.technet/api/push";
    interval = "10m"; # run every 10 minutes
    drives = [
      { pool = "data-pool"; threshold = "90"; endpoint = "W6JG9cXo4X"; }
      { pool = "root-pool"; threshold = "90"; endpoint = "OJqTfvQtOh"; }
    ];
  };
}
