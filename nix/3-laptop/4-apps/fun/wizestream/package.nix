# WizeStream Desktop -- the Electron client of the Material 3 NewPipe fork.
#
# Upstream ships only unsigned AppImage/deb betas, so this builds from source: a
# Gradle/JVM extractor backend the Electron main process spawns, plus the npm
# renderer and the libmpv addon it plays video through.
#
{
    buildNpmPackage,
    copyDesktopItems,
    electron_43,
    ffmpeg-headless,
    fetchFromGitHub,
    gradle_9,
    jdk21_headless,
    lib,
    makeDesktopItem,
    makeWrapper,
    mpv-unwrapped,
    nodejs_24,
    python3,
    stdenv,
}:
let
    version = "0.6.0-beta";

    src = fetchFromGitHub {
        owner = "wizdom13";
        repo = "WizeStream";
        rev = "5a0428f98fce04e0df30cf3687f0f7d9215fb9d6";
        hash = "sha256-nFhNRDm3nWLtYK/tQGmGuIGoVFBvCy/RgWRPwUwFN8A=";
    };

    gradle = gradle_9.override { java = jdk21_headless; };

    # The backend compiles NewPipe extractor and sync sources out of the Android
    # tree, so its build needs the whole checkout rather than desktop/backend.
    backend = stdenv.mkDerivation (finalAttrs: {
        pname = "wizestream-desktop-backend";
        inherit version src;

        nativeBuildInputs = [ gradle ];

        mitmCache = gradle.fetchDeps {
            pkg = finalAttrs.finalPackage;
            data = ./gradle-deps.json;
        };

        gradleFlags = [
            "-p"
            "desktop/backend"
            "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        ];

        # installDist alone: the runtimeImage jlink task is replaced below by the
        # full JDK, which the launcher finds under backend/build/runtime.
        gradleBuildTask = "installDist";

        installPhase = ''
            runHook preInstall
            cp -r desktop/backend/build/install/wizestream-desktop-backend/lib $out
            runHook postInstall
        '';
    });
in
buildNpmPackage (finalAttrs: {
    pname = "wizestream";
    inherit version src;

    sourceRoot = "${finalAttrs.src.name}/desktop";

    npmDepsHash = "sha256-OlBwuYYot1fbfZZWHkjD3mc9IuR+hci1W3bHKb+iSQY=";

    nodejs = nodejs_24;

    nativeBuildInputs = [
        copyDesktopItems
        makeWrapper
        python3
    ];

    env = {
        ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
        # The vendored addon links no libmpv and dlopens it instead, so these only
        # have to satisfy its headers-and-library check at build time.
        MPV_INCLUDE_DIR = "${mpv-unwrapped.dev}/include";
        MPV_LIB = "${lib.getLib mpv-unwrapped}/lib/libmpv.so";
        MPV_RUNTIME_DIR = "${lib.getLib mpv-unwrapped}/lib";
    };

    preBuild = ''
        export npm_config_nodedir=${electron_43.headers}
    '';

    # Installed unpacked rather than through electron-builder, so the main process
    # takes its app.getAppPath() branch and reads everything below relative to it.
    installPhase = ''
        runHook preInstall

        mkdir -p $out/share/wizestream/backend/build $out/share/wizestream/native/media-tools
        cp -r dist-electron dist-renderer node_modules package.json vendor $out/share/wizestream/

        # The electron package is build-only and its binary download is skipped, so it
        # ships nothing at runtime beyond wrapper links pointing at absent files.
        rm -rf $out/share/wizestream/node_modules/electron
        find $out/share/wizestream/node_modules/.bin -xtype l -delete

        mkdir -p $out/share/wizestream/backend/build/install/wizestream-desktop-backend
        ln -s ${backend} $out/share/wizestream/backend/build/install/wizestream-desktop-backend/lib
        ln -s ${jdk21_headless} $out/share/wizestream/backend/build/runtime

        ln -s ${lib.getExe' ffmpeg-headless "ffmpeg"} $out/share/wizestream/native/media-tools/ffmpeg
        ln -s ${lib.getExe' ffmpeg-headless "ffprobe"} $out/share/wizestream/native/media-tools/ffprobe

        install -Dm644 ../assets/wizestream_logo_round.svg \
            $out/share/icons/hicolor/scalable/apps/wizestream.svg

        makeWrapper ${lib.getExe electron_43} $out/bin/wizestream \
            --add-flags $out/share/wizestream \
            --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true" \
            --prefix LD_LIBRARY_PATH : ${lib.getLib mpv-unwrapped}/lib

        runHook postInstall
    '';

    desktopItems = [
        (makeDesktopItem {
            name = "wizestream";
            desktopName = "WizeStream";
            comment = "Privacy-friendly streaming client";
            exec = "wizestream %U";
            icon = "wizestream";
            startupNotify = true;
            startupWMClass = "WizeStream Desktop";
            categories = [
                "AudioVideo"
                "Video"
                "Player"
            ];
            keywords = [
                "youtube"
                "newpipe"
                "video"
                "streaming"
            ];
        })
    ];

    meta = {
        description = "Privacy-friendly multi-platform streaming client, a Material 3 fork of NewPipe";
        homepage = "https://github.com/wizdom13/WizeStream";
        license = lib.licenses.gpl3Plus;
        mainProgram = "wizestream";
        platforms = [ "x86_64-linux" ];
    };
})
