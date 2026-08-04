# Audio
#
# Point ALSA at the UCM profiles, which is what gives this phone a speaker and
# an earpiece.
#
# Symptom this fixes: both the default sink and the default source were the
# snd-aloop Loopback card, and the real codec had no sink at all. That looks
# like a defaulting problem and is not one. Walking it back:
#
#   * The PinePhone card sat on the profile `input:stereo-fallback` -- input
#     only -- so no output node was ever created for it to be the default of.
#   * Its only output port was `analog-output-headphones`. No Speaker, no
#     Earpiece, so even with an output profile there was nowhere to play except
#     headphones.
#   * Those two ports come from ALSA's use case manager, and alsa-ucm-conf ships
#     exactly the right profile -- ucm2/Allwinner/A64/PinePhone/HiFi.conf defines
#     SectionDevice "Speaker", "Earpiece" and "Mic".
#   * ALSA never found it. There is no ALSA_CONFIG_UCM2 in PipeWire's
#     environment, no /etc/alsa/ucm2 and no ucm2 under /run/current-system/sw,
#     so the profiles were in the closure and unreachable.
#
# Which leaves three cards visible and the two useless ones winning by default:
# snd-dummy and snd-aloop are both compiled into megi's kernel rather than being
# modules, so blacklisting cannot remove them, and snd-dummy even describes
# itself as "Built-in Audio", which is why it is hard to spot in wpctl output.
#
# Set on the units rather than through environment.variables because these are
# user services and inherit the session environment only if it was imported
# before they started -- which is the same race documented for syncthing in
# 6-display.nix.
#
{ pkgs, ... }:
{
    systemd.user.services = {
        pipewire.environment.ALSA_CONFIG_UCM2 = "${pkgs.alsa-ucm-conf}/share/alsa/ucm2";
        wireplumber.environment.ALSA_CONFIG_UCM2 = "${pkgs.alsa-ucm-conf}/share/alsa/ucm2";
    };

    # Same value for anything else that opens ALSA directly -- alsamixer, or a
    # call daemon reaching past PipeWire.
    environment.variables.ALSA_CONFIG_UCM2 = "${pkgs.alsa-ucm-conf}/share/alsa/ucm2";

    # For inspecting UCM by hand. `alsaucm -c PinePhone list _verbs` is the check
    # that the profile is being found at all, and it was not installed while
    # diagnosing this.
    environment.systemPackages = [ pkgs.alsa-utils ];

    # Force the codec onto a profile that has an output.
    #
    # Left alone it selects `input:stereo-fallback` and stays there, so the card
    # contributes a source and no sink at all, and the default sink falls to
    # snd-dummy because nothing better exists. Setting it by hand with
    # `wpctl set-profile` works and does not survive a restart of the audio
    # stack, which is why it belongs here.
    #
    # This is the fallback path, not the good one. Until the UCM profile above
    # actually resolves, the only output port the card offers is
    # analog-output-headphones -- so this yields working headphones and neither
    # a speaker nor an earpiece. It is worth having anyway: a real sink that
    # persists beats no sink and a dummy default.
    #
    # api.acp.auto-profile is false on this device, which is why the profile has
    # to be named rather than left to WirePlumber to pick.
    services.pipewire.wireplumber.extraConfig."51-pinephone-output" = {
        "monitor.alsa.rules" = [
            {
                matches = [ { "device.name" = "alsa_card.platform-sound"; } ];
                actions.update-props = {
                    "device.profile" = "output:stereo-fallback+input:stereo-fallback";
                    "api.acp.auto-profile" = false;
                };
            }
        ];
    };
}
