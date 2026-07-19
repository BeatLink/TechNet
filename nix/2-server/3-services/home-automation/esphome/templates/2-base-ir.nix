# Hardware profile: Athom IR blaster (ESP8285).
#
# Built on athom's own base config, which supplies the pin mapping, the 2MB
# flash layout, factory reset and the diagnostic sensors. Its defaults assume a
# stock athom deployment, so the settings this house does differently are
# overridden below -- ESPHome merges packages with the including file winning,
# so both the substitutions and the hardcoded values here take precedence.
{
    packages = {
        athom = "github://athom-tech/athom-configs/athom-ir-remote.yaml";
        common = "!include 1-common.yaml";
    };

    substitutions = {
        # `1-common.yaml` addresses devices as `<name>.lan`; athom defaults to
        # `.local`.
        dns_domain = ".lan";
        log_level = "INFO";
    };

    esphome = {
        area = "\${room}";
        # Hostnames here are fixed (`ir-fan.lan`), so no MAC suffix.
        name_add_mac_suffix = false;
    };

    # mDNS is off house-wide; DNS resolves the `.lan` names instead.
    mdns.disabled = true;

    # Athom leaves the receiver dumping every code it sees, which is useful when
    # capturing a new remote but is constant log noise otherwise. The pronto
    # codes are already captured, so keep it off.
    remote_receiver.dump = [ ];
}
