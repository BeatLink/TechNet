# Audio ##############################################################################################################################################
{ pkgs, ... }:
let
    # The AIF2 levels upstream's Voice Call verb omits, taken from mobile-nixos' tree with this phone's own volumes.
    voiceCallAif2 = pkgs.writeText "voice-call-aif2.conf" ''
        cset "name='AIF2 DAC Playback Volume' 160"
        cset "name='AIF2 DAC Stereo Playback Route' Mix Mono"
        cset "name='AIF2 ADC Capture Volume' 144"
        cset "name='AIF2 Digital ADC Capture Switch' on"
    '';

    # Upstream's UCM tree plus an alias matching megi's card long name.
    ucm2 = pkgs.runCommand "alsa-ucm-conf-pinephone" { } ''
        cp -r --no-preserve=mode ${pkgs.alsa-ucm-conf}/share/alsa/ucm2 "$out"
        cp "$out/conf.d/simple-card/PinePhone.conf" \
            "$out/conf.d/simple-card/PINE64-PinephoneA64-.conf"

        verb="$out/Allwinner/A64/PinePhone/VoiceCall.conf"
        grep -q "AIF2 ADC Stereo Capture Route" "$verb"
        sed -i "/AIF2 ADC Stereo Capture Route/r ${voiceCallAif2}" "$verb"
    '';
in
{
    # UCM --------------------------------------------------------------------------------------------------------------------------------------------
    systemd.user.services = {
        pipewire.environment.ALSA_CONFIG_UCM2 = "${ucm2}";
        wireplumber.environment.ALSA_CONFIG_UCM2 = "${ucm2}";
    };

    environment.variables.ALSA_CONFIG_UCM2 = "${ucm2}";
    environment.systemPackages = [ pkgs.alsa-utils ];

    # Phantom cards ----------------------------------------------------------------------------------------------------------------------------------
    boot.kernelParams = [
        "snd_aloop.enable=0"
        "snd_dummy.enable=0"
    ];

    # Mixer persistence ------------------------------------------------------------------------------------------------------------------------------
    hardware.alsa.enablePersistence = true;
    environment.persistence."/persistent".directories = [ "/var/lib/alsa" ];

    # Applies the codec gain structure this phone needs.
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
                # 160 is unity, not a maximum; 192 is +24dB and clips into static
                ${pkgs.alsa-utils}/bin/amixer -c "$card" cset name='AIF1 DA0 Playback Volume' 160
                ${pkgs.alsa-utils}/bin/amixer -c "$card" cset name='DAC Playback Volume' 168
                ${pkgs.alsa-utils}/bin/amixer -c "$card" cset name='Earpiece Playback Volume' 31
            '';
        };
    };

    # Restores the ALSA mixer once the pool holding /var/lib is imported.
    systemd.services.alsa-restore-late = {
        description = "Restore the ALSA mixer once /var/lib is available";
        wantedBy = [ "multi-user.target" ];
        after = [ "local-fs.target" ];
        before = [ "pipewire.service" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # Leading `-` ignores failure; ExecStart has no shell, so `|| true` would be passed as arguments
            ExecStart = "-${pkgs.alsa-utils}/bin/alsactl restore";
        };
    };
}
