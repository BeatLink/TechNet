{ lib, ... }:
{
  # Automatic cleanup for transient directories
  systemd.tmpfiles.rules = [
    # Ensure /tmp and /var/tmp exist with correct permissions.
    "d /tmp 1777 root root -"
    "d /var/tmp 1777 root root -"

    # Clean up old files automatically.
    # /tmp can be cleaned more aggressively because it is transient.
    "q /tmp 1777 root root 10d"
    # Keep /var/tmp for longer, but still remove stale items.
    "q /var/tmp 1777 root root 30d"
  ];

  systemd.timers."systemd-tmpfiles-clean" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
