# Lenovo Control Center -- battery charge thresholds, CPU governor, fan and
# brightness controls, from PR #2 of the upstream repo.
# https://github.com/afishyke/linux-control-centre-for-lenovo/pull/2

{
    inputs,
    lib,
    pkgs,
    ...
}:
let
    python = pkgs.python3.withPackages (ps: [
        ps.pyqt6
        ps.psutil
    ]);

    # Built here rather than from the PR's own packages.default, which declares
    # only psutil and dies on `import tkinter` before it draws a window.
    lenovo-control-center = pkgs.stdenv.mkDerivation {
        pname = "lenovo-control-center";
        version = "0-unstable-2026-08-03";

        src = inputs.lenovo-control-center;

        nativeBuildInputs = with pkgs; [
            makeWrapper
            copyDesktopItems
            qt6.wrapQtAppsHook
        ];

        buildInputs = with pkgs; [
            qt6.qtbase
            qt6.qtwayland
        ];

        dontBuild = true;

        installPhase = ''
            runHook preInstall

            install -Dm644 main.py $out/share/lenovo-control-center/main.py
            install -Dm644 lenovo-control-center.svg \
                $out/share/icons/hicolor/scalable/apps/lenovo-control-center.svg

            makeWrapper ${lib.getExe python} $out/bin/lenovo-control-center \
                --add-flags $out/share/lenovo-control-center/main.py \
                --prefix PATH : ${
                    lib.makeBinPath (
                        with pkgs;
                        [
                            lm_sensors
                            xrandr
                        ]
                    )
                } \
                "''${qtWrapperArgs[@]}"

            runHook postInstall
        '';

        desktopItems = [
            (pkgs.makeDesktopItem {
                name = "lenovo-control-center";
                desktopName = "Lenovo Control Center";
                comment = "System control and monitoring for Lenovo laptops";
                exec = "lenovo-control-center";
                icon = "lenovo-control-center";
                startupNotify = true;
                categories = [
                    "System"
                    "Settings"
                ];
                keywords = [
                    "lenovo"
                    "battery"
                    "cpu"
                    "fan"
                    "power"
                ];
            })
        ];

        meta = {
            description = "System control and monitoring for Lenovo laptops";
            homepage = "https://github.com/afishyke/linux-control-centre-for-lenovo";
            mainProgram = "lenovo-control-center";
            platforms = [ "x86_64-linux" ];
        };
    };
in
{
    environment.systemPackages = [ lenovo-control-center ];
}
