# Boot Messages ######################################################################################################################################
#
# Feeds the splash a status line at each boot milestone, shown between the logo and the progress bar.
#

{
    config,
    lib,
    ...
}:
let
    plymouth = "${config.boot.plymouth.package}/bin/plymouth";
    message = text: ''-${plymouth} display-message --text="${text}"'';
in
{
    config = lib.mkMerge [

        # Networking #################################################################################################################################
        (lib.mkIf config.boot.initrd.systemd.network.enable {
            boot.initrd.systemd.services.systemd-networkd.serviceConfig.ExecStartPre = [ (message "Setting up networking...") ];
        })

        # Mounting ###################################################################################################################################
        {
            boot.initrd.systemd.services.splash-mounting-message = {
                description = "Tell the splash the drives are about to mount";
                wantedBy = [ "sysroot.mount" ];
                before = [ "sysroot.mount" ];
                unitConfig.DefaultDependencies = "no";
                serviceConfig = {
                    Type = "oneshot";
                    ExecStart = message "Mounting drives...";
                };
            };
        }

        # Activation #################################################################################################################################
        {
            # Also runs on every rebuild switch, where no plymouthd is listening and the call fails silently.
            system.activationScripts.splashMessage.text = ''
                ${plymouth} display-message --text="Activating NixOS..." > /dev/null 2>&1 || true
            '';
        }
    ];
}
