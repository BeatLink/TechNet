# Remote Deploy ######################################################################################################################################
#
# Heimdall's Vigil switches the other hosts over SSH: each target has a `deploy` account that only Heimdall's key for that host can log in to, and
# Heimdall runs every such switch through one root-only script that holds the target awake and runs its after-switch hook.
#
{
    config,
    lib,
    pkgs,
    ...
}:
let
    deploy = import ../1-system/software/deploy.nix;
    host = config.networking.hostName;

    # sudoers ends a command spec at an unescaped colon.
    upgradeFlake = builtins.replaceStrings [ ":" ] [ "\\:" ] config.technet.flake;

    keySecret = name: "deploy_key_${lib.toLower name}";

    # Runs nixos-rebuild with the arguments Vigil sends, refusing any target not in deploy.nix, so the sudo rules below are the whole of what it can do.
    remoteSwitch = pkgs.writeShellApplication {
        name = "technet-remote-switch";
        runtimeInputs = [
            config.system.build.nixos-rebuild
            config.nix.package
            pkgs.git
            pkgs.openssh
        ];
        text = ''
            target=""
            previous=""
            for arg in "$@"; do
                if [ "$previous" = "--target-host" ]; then
                    target=$arg
                fi
                previous=$arg
            done

            case "$target" in
            ${lib.concatStrings (
                lib.mapAttrsToList (name: d: ''
                    ${lib.escapeShellArg d.target})
                        key=${config.sops.secrets.${keySecret name}.path}
                        post=${lib.escapeShellArg (if d.postSwitch == null then "" else d.postSwitch)}
                        ;;
                '') deploy.remote
            )}
            *)
                echo "technet-remote-switch: refusing unknown target '$target'" >&2
                exit 2
                ;;
            esac

            ssh_opts=(-i "$key" -o IdentitiesOnly=yes -o BatchMode=yes -o ServerAliveInterval=30)
            export NIX_SSHOPTS="''${ssh_opts[*]}"

            # The inhibit lasts as long as this pipe is open, so it ends with the script however the script ends.
            exec 3> >(ssh "''${ssh_opts[@]}" "$target" 'sudo /run/current-system/sw/bin/systemd-inhibit --what=idle:sleep --mode=block --why="Heimdall is deploying this system" cat > /dev/null')

            status=0
            nixos-rebuild "$@" || status=$?
            exec 3>&-

            if [ -n "$post" ]; then
                # shellcheck disable=SC2029 # The command is sent as written, to run on the target
                ssh "''${ssh_opts[@]}" "$target" "$post" || echo "technet-remote-switch: after-switch command on $target failed" >&2
            fi
            exit "$status"
        '';
    };
in
{
    config = lib.mkMerge [

        # Deploy Account #############################################################################################################################
        # Root-equivalent by nature, since whoever can deploy a closure can deploy a malicious one; what is scoped is the key, its source and its host.
        (lib.mkIf (deploy.remote ? ${host}) {
            users.groups.deploy = { };
            users.users.deploy = {
                isSystemUser = true;
                description = "Heimdall's deployments of this host";
                group = "deploy";
                shell = "/run/current-system/sw/bin/bash"; # nix copy and the activation run over SSH exec, which needs a shell
                openssh.authorizedKeys.keys = [
                    ''restrict,from="${lib.concatStringsSep "," deploy.heimdallAddresses}" ${
                        deploy.remote.${host}.publicKey
                    }''
                ];
            };

            # Trusted, because nix copy refuses the unsigned paths Heimdall builds from anyone else.
            nix.settings.trusted-users = [ "deploy" ];

            security.sudo.extraRules = [
                {
                    users = [ "deploy" ];
                    commands = [
                        {
                            command = "ALL";
                            options = [ "NOPASSWD" ];
                        }
                    ];
                }
            ];
        })

        # Heimdall #################################################################################################################################
        (lib.mkIf (host == "Heimdall") {
            sops.secrets = lib.mapAttrs' (
                name: _:
                lib.nameValuePair (keySecret name) { sopsFile = "${config.technet.secrets.path}/deploy.yaml"; }
            ) deploy.remote;

            environment.systemPackages = [ remoteSwitch ];

            # Vigil's switch of each remote host, matched argv for argv against what its monitor sends, so the agent can only deploy the committed flake.
            security.sudo.extraRules = [
                {
                    users = [ "vigil-agent" ];
                    commands = lib.mapAttrsToList (name: d: {
                        command = "/run/current-system/sw/bin/technet-remote-switch switch --flake ${upgradeFlake}\\#${name} --target-host ${d.target} ${lib.concatStringsSep " " deploy.remoteArgs} --refresh";
                        options = [ "NOPASSWD" ];
                    }) deploy.remote;
                }
            ];
        })
    ];
}
