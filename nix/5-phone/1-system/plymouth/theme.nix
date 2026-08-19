{
    runCommand,
    imagemagick,
    src,
    logoWidth ? 440,
    progressBarWidth ? 440,
}:
runCommand "plymouth-theme-nixos-mobile" { nativeBuildInputs = [ imagemagick ]; } ''
    theme=$out/share/plymouth/themes/nixos-mobile
    mkdir -p $theme

    cp ${src}/src/resources/*.png $theme/
    chmod +w $theme/*.png
    magick mogrify -resize ${toString logoWidth}x -strip $theme/throbber-*.png

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
    VerticalAlignment=.42
    Transition=fade-over
    TransitionDuration=6.0
    MessageBelowAnimation=true

    ProgressBarWidth=${toString progressBarWidth}
    ProgressBarHeight=6
    ProgressBarHorizontalAlignment=.5
    ProgressBarVerticalAlignment=.62
    ProgressBarBackgroundColor=0x606060
    ProgressBarForegroundColor=0xffffff

    DialogHorizontalAlignment=.5
    DialogVerticalAlignment=.5
    DialogClearsFirmwareBackground=false

    [boot-up]
    UseAnimation=true
    UseEndAnimation=false
    UseFirmwareBackground=false
    SuppressMessages=false
    ProgressBarShowPercentComplete=false
    UseProgressBar=true

    [shutdown]
    UseAnimation=true
    UseEndAnimation=false
    UseFirmwareBackground=false
    SuppressMessages=false
    ProgressBarShowPercentComplete=false
    UseProgressBar=true

    [reboot]
    UseAnimation=true
    UseEndAnimation=false
    UseFirmwareBackground=false
    SuppressMessages=false
    ProgressBarShowPercentComplete=false
    UseProgressBar=true
    EOF
''
