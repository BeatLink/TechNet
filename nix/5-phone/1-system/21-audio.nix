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

    # Stop the two phantom cards from registering.
    #
    # This phone shows three ALSA cards and only one of them is real:
    #
    #   0 [Dummy    ]  snd-dummy    describes itself as "Built-in Audio"
    #   1 [Loopback ]  snd-aloop
    #   2 [PinePhone]  simple-card  the actual codec
    #
    # Both of the others come from mobile-nixos' kernel config and neither has a
    # use here. They are not merely noise: WirePlumber picked one of them as the
    # default sink and one as the default source, which is what made the phone
    # silent while the real codec sat unused. snd-dummy calling itself "Built-in
    # Audio" is why that was hard to see in wpctl output.
    #
    # boot.blacklistedKernelModules cannot help -- CONFIG_SND_DUMMY=y and
    # CONFIG_SND_ALOOP=y, so they are built in rather than modules. A built-in
    # driver still parses its module parameters off the kernel command line
    # though, and both expose `enable` as a per-card array:
    #
    #   /sys/module/snd_aloop/parameters/enable -> Y,N,N,N,...
    #
    # Setting the first element to 0 stops the card being registered at all,
    # which is cleaner than hiding it in WirePlumber -- nothing enumerates it,
    # so nothing can pick it.
    boot.kernelParams = [
        "snd_aloop.enable=0"
        "snd_dummy.enable=0"
    ];

    # Save and restore the mixer across boots.
    #
    # Getting UCM to match was necessary and not sufficient. The codec still came
    # up silent, because every gain stage was at a power-on default that no
    # layer was fixing:
    #
    #   AIF1 DA0 Playback Volume    0 of 192    silence before the DAC
    #   DAC Playback Volume         0, muted
    #   AIF1 Slot 0 Digital DAC     off
    #   Line Out Playback Switch    off
    #
    # UCM's FixedBootSequence sets the routing switches and none of the gains, so
    # it could never have fixed this on its own. Nothing else was restoring
    # state, because the host had no alsa-store/alsa-restore at all -- both units
    # reported not-found.
    #
    # Worth recording the shape of the mistake this exposes: with the digital
    # stages later opened to their maximum the sound was badly distorted, because
    # 0-192 is not a percentage. 192 is +24dB and 160 is unity, so the working
    # setting is digital stages at 0dB and the analog Line Out carrying the
    # level. Anything that "fixes" audio by moving a raw control to its maximum
    # is clipping rather than working.
    hardware.alsa.enablePersistence = true;

    # alsa-store writes here on shutdown and the restore reads it. On a host that
    # rolls / back to a blank snapshot every boot, a state file in /var/lib is a
    # state file that never survives.
    environment.persistence."/persistent".directories = [ "/var/lib/alsa" ];

    # The gain structure this codec needs, declared rather than remembered.
    #
    # alsa-store below persists whatever the mixer happens to hold, which covers
    # a running phone and not a reinstalled one -- a fresh install would come up
    # at the power-on defaults that made this silent in the first place. These
    # are the settings that had to be found by hand, so they are written down.
    #
    # Only what UCM does not already do. Routing switches come from the profile;
    # what it has no opinion on is the gains, and the gains were the problem:
    #
    #   AIF1 DA0    0dB, unity. This is the stage that clips -- pushed to its
    #               maximum it is +24dB and the sound is pure static. 0-192 is
    #               not a percentage.
    #   DAC        +6dB. Shared by both outputs. The earpiece control is already
    #               at its own ceiling of 0dB, so the only headroom for it lives
    #               here, and +6 is what sounded right without distorting.
    #   Earpiece    its maximum, since it has no headroom to spare.
    #
    # Line Out is deliberately absent: PipeWire drives it as the speaker's mixer
    # element, so anything set here is overwritten the moment the volume is
    # touched. The earpiece is likewise PipeWire's, but starting it at maximum
    # costs nothing.
    #
    # Ordered before alsa-restore-late so a stored state, if there is one, wins
    # -- these are a floor for a fresh install, not a policy overriding whatever
    # the phone was last set to.
    #
    # Addressed by card name rather than index because disabling the two phantom
    # cards renumbers PinePhone from card 2 to card 0.
    systemd.services.alsa-defaults = {
        description = "Apply the codec gain structure this phone needs";
        wantedBy = [ "multi-user.target" ];
        after = [ "local-fs.target" ];
        before = [
            "alsa-restore-late.service"
            "pipewire.service"
        ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "alsa-defaults" ''
                card=PinePhone
                ${pkgs.alsa-utils}/bin/amixer -c "$card" cset name='AIF1 DA0 Playback Volume' 160
                ${pkgs.alsa-utils}/bin/amixer -c "$card" cset name='DAC Playback Volume' 168
                ${pkgs.alsa-utils}/bin/amixer -c "$card" cset name='Earpiece Playback Volume' 31
            '';
        };
    };

    # enablePersistence installs a udev rule that restores each card as its
    # controlC* appears. On this phone that happens around 1.7s, and /var/lib is
    # on a pool that is not imported until roughly 20s -- the same ordering that
    # left the Bluetooth firmware unloadable, see 22-bluetooth.nix. So the udev
    # restore runs against a file that does not exist yet and quietly does
    # nothing.
    #
    # Restoring again once the filesystem is actually there is what makes it
    # work. Cheap, and idempotent: with no state file yet it is a no-op.
    systemd.services.alsa-restore-late = {
        description = "Restore the ALSA mixer once /var/lib is available";
        wantedBy = [ "multi-user.target" ];
        after = [ "local-fs.target" ];
        before = [ "pipewire.service" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # The leading `-` is systemd's ignore-failure prefix, and it has to
            # be that rather than `|| true`: ExecStart is not run through a
            # shell, so the shell form is passed to alsactl as arguments and it
            # fails with "Cannot find soundcard '||'".
            #
            # Failure is tolerated because a first boot has nothing stored yet,
            # and a card that is absent -- the SD card is removable -- is not an
            # error worth failing activation over.
            ExecStart = "-${pkgs.alsa-utils}/bin/alsactl restore";
        };
    };

    systemd.services.voice-call-mixer = {
        description = "Set the AIF2 mixer levels the Voice Call UCM verb leaves alone";
        wantedBy = [ "multi-user.target" ];
        after = [ "alsa-restore-late.service" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };
        script = ''
            amixer -c 0 cset name='AIF2 ADC Capture Volume' 144
            amixer -c 0 cset name='AIF2 DAC Playback Volume' 160
            amixer -c 0 cset name='AIF2 Digital ADC Capture Switch' on
            amixer -c 0 cset name='AIF2 DAC Stereo Playback Route' 'Mix Mono'
        '';
        path = [ pkgs.alsa-utils ];
    };
}
