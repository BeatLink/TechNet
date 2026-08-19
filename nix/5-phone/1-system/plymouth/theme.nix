{
    runCommand,
    imagemagick,
    src,
    logoWidth ? 440,
    progressBarWidth ? 440,
    screenHeight ? 1440,
    logoAlignment ? 0.42,
    progressBarAlignment ? 0.62,
    progressBarHeight ? 6,
    titleHeight ? 21,
}:
runCommand "plymouth-theme-nixos-mobile" { nativeBuildInputs = [ imagemagick ]; } ''
    theme=$out/share/plymouth/themes/nixos-mobile
    mkdir -p $theme

    cp ${src}/src/resources/*.png $theme/
    chmod +w $theme/*.png
    magick mogrify -resize ${toString logoWidth}x -strip $theme/throbber-*.png

    # The title sits midway between the bottom of the logo and the top of the progress bar. The frames pulse a glow around a fixed logo,
    # so the smallest of them marks where the logo itself ends; the larger ones are halo the eye does not read as an edge.
    logoHeight=$(magick identify -format '%h' $theme/throbber-0001.png)
    inkBottom=$logoHeight
    for frame in $theme/throbber-*.png; do
        box=$(magick identify -format '%@' "$frame")
        height=''${box#*x}
        height=''${height%%+*}
        offset=''${box##*+}
        [ $((height + offset)) -lt $inkBottom ] && inkBottom=$((height + offset))
    done
    logoBottom=$(awk "BEGIN { print ${toString logoAlignment} * ${toString screenHeight} - $logoHeight / 2 + $inkBottom }")
    barTop=$(awk "BEGIN { print ${toString progressBarAlignment} * (${toString screenHeight} - ${toString progressBarHeight}) }")
    titleAlignment=$(awk "BEGIN { printf \"%.4f\", (($logoBottom + $barTop - ${toString titleHeight}) / 2) / (${toString screenHeight} - ${toString titleHeight}) }")

    # Each frame is written twice so the 30fps pulse plays over twelve seconds instead of six.
    n=0
    for frame in $theme/throbber-*.png; do
        for _ in 1 2; do
            n=$((n + 1))
            cp "$frame" "$theme/frame-$(printf '%04d' "$n").png"
        done
        rm "$frame"
    done
    for frame in $theme/frame-*.png; do
        mv "$frame" "$theme/throbber-''${frame##*frame-}"
    done

    cat > $theme/nixos-mobile.plymouth <<EOF
    [Plymouth Theme]
    Name=nixos-mobile
    Description=NixOS logo and progress bar, laid out for a 720x1440 portrait panel
    ModuleName=two-step

    [two-step]
    ImageDir=$theme
    Font=DejaVu Sans 14

    BackgroundStartColor=0x000000
    BackgroundEndColor=0x000000

    HorizontalAlignment=.5
    VerticalAlignment=${toString logoAlignment}
    Transition=fade-over
    TransitionDuration=6.0
    MessageBelowAnimation=true

    TitleFont=DejaVu Sans 16
    TitleHorizontalAlignment=.5
    TitleVerticalAlignment=$titleAlignment

    ProgressBarWidth=${toString progressBarWidth}
    ProgressBarHeight=${toString progressBarHeight}
    ProgressBarHorizontalAlignment=.5
    ProgressBarVerticalAlignment=${toString progressBarAlignment}
    ProgressBarBackgroundColor=0x606060
    ProgressBarForegroundColor=0xffffff

    DialogHorizontalAlignment=.5
    DialogVerticalAlignment=.5
    DialogClearsFirmwareBackground=false

    [boot-up]
    Title=Starting Up...
    UseAnimation=true
    UseEndAnimation=false
    UseFirmwareBackground=false
    SuppressMessages=false
    ProgressBarShowPercentComplete=false
    UseProgressBar=true

    [shutdown]
    Title=Shutting Down...
    UseAnimation=true
    UseEndAnimation=false
    UseFirmwareBackground=false
    SuppressMessages=false
    ProgressBarShowPercentComplete=false
    UseProgressBar=true

    [reboot]
    Title=Restarting...
    UseAnimation=true
    UseEndAnimation=false
    UseFirmwareBackground=false
    SuppressMessages=false
    ProgressBarShowPercentComplete=false
    UseProgressBar=true
    EOF
''
