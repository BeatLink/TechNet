{ config, lib, pkgs, ... }:

let
  cfg = config.services.openbooks;
in
{
  options.services.openbooks = {
    enable = lib.mkEnableOption "openbooks IRC ebook downloader";

    package = lib.mkPackageOption pkgs "openbooks" { };

    user = lib.mkOption {
      type = lib.types.str;
      default = "openbooks";
      description = "User account under which openbooks runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "openbooks";
      description = "Group under which openbooks runs.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/openbooks";
      description = "Root state directory for openbooks. Used as the service working directory and user home.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address on which the openbooks web interface listens. Use \"0.0.0.0\" to listen on all interfaces.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port on which the openbooks web interface listens.";
    };

    basePath = lib.mkOption {
      type = lib.types.str;
      default = "/";
      description = ''
        Base path for hosting behind a reverse proxy.
        Must begin and end with a forward slash, e.g. "/openbooks/".
      '';
    };

    persist = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to keep downloaded books on disk after the browser session ends.
        When false, downloads are removed when the user's session closes.
      '';
    };

    booksDir = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.dataDir}/books";
      defaultText = lib.literalExpression ''"''${config.services.openbooks.dataDir}/books"'';
      description = "Directory where downloaded ebooks are stored.";
    };

    ircNick = lib.mkOption {
      type = lib.types.str;
      default = "openbooks";
      description = ''
        IRC nickname used when connecting to irc.irchighway.net.
        Must be unique on the network; consider adding a random suffix.
      '';
    };

    log = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable verbose IRC/DCC protocol logging to the journal.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the configured port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.basePath && lib.hasSuffix "/" cfg.basePath;
        message = "services.openbooks.basePath must begin and end with '/' (e.g. \"/\" or \"/openbooks/\").";
      }
    ];

    users.users.${cfg.user} = lib.mkIf (cfg.user == "openbooks") {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      description = "openbooks service user";
    };

    users.groups.${cfg.group} = lib.mkIf (cfg.group == "openbooks") { };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}   0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.booksDir}  0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.openbooks = {
      description = "openbooks IRC ebook downloader";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.concatStringsSep " " (
          [
            "${lib.getExe cfg.package}"
            "server"
            "--address" cfg.host
            "--port" (toString cfg.port)
            "--basepath" cfg.basePath
            "--name" cfg.ircNick
            "--dir" cfg.booksDir
          ]
          ++ lib.optional cfg.persist "--persist"
          ++ lib.optional cfg.log "--log"
        );

        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;

        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.dataDir cfg.booksDir ];
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "~@privileged" ];

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}