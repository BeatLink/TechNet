# Ideapad ############################################################################################################################################
#
# Holds the ideapad ACPI firmware toggles — battery conservation mode and Fn lock — at declared values.
# conservation_mode: 1 caps charging near 60% for a life spent on AC power, 0 charges fully.
# fn_lock: 1 fires the media actions without Fn held, 0 makes the F-keys plain function keys.
# Fan behavior on the 15ACH6 follows the Fn+Q platform profile; the EC exposes no fan curve and the legacy ideapad fan_mode attribute is a no-op.
#

{ lib, ... }:
{
    config = lib.mkMerge [

        # Firmware Toggles ###########################################################################################################################
        {
            systemd.services.ideapad-toggles = {
                description = "Set ideapad ACPI firmware toggles";
                wantedBy = [ "multi-user.target" ];
                serviceConfig.Type = "oneshot";
                script = ''
                    echo 0 > "/sys/bus/platform/devices/VPC2004:00/conservation_mode"
                    echo 1 > "/sys/bus/platform/devices/VPC2004:00/fn_lock"
                '';
            };
        }
    ];
}
