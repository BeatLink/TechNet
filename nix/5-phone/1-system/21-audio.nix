# Audio
#
# Give ALSA a use case profile that matches this card, which is what gives the
# phone a speaker and an earpiece.
#
# The symptom was that both the default sink and the default source were the
# snd-aloop Loopback card, and the real codec had no sink at all. That looks
# like a defaulting problem and is not one. Walking it back:
#
#   * The PinePhone card sat on the profile `input:stereo-fallback` -- input
#     only -- so no output node existed for it to be the default of.
#   * Its only output port was `analog-output-headphones`. No Speaker, no
#     Earpiece, so even with an output profile there was nowhere to play.
#   * Those ports come from ALSA's use case manager, and none was being applied:
#     `alsaucm -c PinePhone list _verbs` failed with
#     "failed to import PinePhone use case configuration -2".
#
# alsa-ucm-conf ships exactly the right profile and it is already reachable --
# nixpkgs' alsa-lib symlinks ucm2 into its own share/alsa, and that resolves.
# What it does not do is match. From ucm.conf, the lookup is
#
#     ucm2/conf.d/${CardDriver}/${CardLongName}.conf
#
# and the shipped file is conf.d/simple-card/PinePhone.conf. That matches a card
# whose *long* name is "PinePhone", which is what mainline and postmarketOS
# produce. megi's tree names it differently:
#
#     2 [PinePhone      ]: simple-card - PinePhone
#                          PINE64-PinephoneA64-
#
# so the driver matches, the long name does not, and nothing is found. Adding a
# file under the long name is the whole fix -- confirmed by hand before writing
# it down: verbs become HiFi and Voice Call, and HiFi offers Speaker, Earpiece,
# Mic, Headset and Headphones.
#
# Done as a derived tree pointed at by ALSA_CONFIG_UCM2 rather than by
# overriding alsa-ucm-conf, deliberately. alsa-lib embeds alsa-ucm-conf's path,
# so overriding it rebuilds alsa-lib and everything downstream of it -- the
# whole audio stack, under emulation, for one added filename.
#
# Set on the units as well as environment.variables because user services
# inherit the session environment only if it was imported before they started.
#
{ pkgs, ... }:
let
    # Upstream's tree plus one alias. Copied rather than symlinked because the
    # store is read-only and the copy has to gain a file.
    ucm2 = pkgs.runCommand "alsa-ucm-conf-pinephone-longname" { } ''
        cp -r --no-preserve=mode ${pkgs.alsa-ucm-conf}/share/alsa/ucm2 "$out"
        cp "$out/conf.d/simple-card/PinePhone.conf" \
            "$out/conf.d/simple-card/PINE64-PinephoneA64-.conf"
    '';
in
{
    systemd.user.services = {
        pipewire.environment.ALSA_CONFIG_UCM2 = "${ucm2}";
        wireplumber.environment.ALSA_CONFIG_UCM2 = "${ucm2}";
    };

    # For anything else that opens ALSA directly -- alsamixer, or a call daemon
    # reaching past PipeWire.
    environment.variables.ALSA_CONFIG_UCM2 = "${ucm2}";

    # For inspecting UCM by hand. `alsaucm -c PinePhone list _verbs` is the check
    # that a profile is found at all, and it was not installed while diagnosing
    # this, which is why the first attempt at a fix went out untested.
    environment.systemPackages = [ pkgs.alsa-utils ];
}
