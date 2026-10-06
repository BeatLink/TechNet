# Stremio Web ########################################################################################################################################
#
# The browser build of Stremio, built from source rather than taken from upstream's release zip so that two things can be set here:
# the streaming server it offers by default, and whether it installs a service worker.
#

{
    lib,
    stdenv,
    fetchFromGitHub,
    nodejs,
    pnpm_11,
    pnpmConfigHook,
    fetchPnpmDeps,
    defaultStreamingServer ? "http://127.0.0.1:11470/",
}:

stdenv.mkDerivation (finalAttrs: {
    pname = "stremio-web";
    version = "5.0.0-beta.40";

    src = fetchFromGitHub {
        owner = "Stremio";
        repo = "stremio-web";
        tag = "v${finalAttrs.version}";
        hash = "sha256-+L/YU8R0zAWmIQHU3P2BBHnB/wLrN2r+ue4B9zy6n0w=";
    };

    pnpmDeps = fetchPnpmDeps {
        inherit (finalAttrs) pname version src;
        fetcherVersion = 4;
        hash = "sha256-X9J+fvodEg8f+XaEDr7E58HHU9DgBlzIqbObJw68iFg=";
    };

    nativeBuildInputs = [
        nodejs
        pnpm_11
        pnpmConfigHook
    ];

    # The upstream build names its asset directory after the checked-out commit, which a source tarball has no way to look up. Both are
    # `--replace-fail`, so a version bump that reworks either one fails the build instead of quietly shipping a UI that points at
    # the viewer's own machine. SearchParamsHandler compares the incoming ?streamingServerUrl against this exact value and, when they
    # match, applies it silently; any other address puts a confirmation modal in front of the user on every new profile.
    postPatch = ''
        substituteInPlace webpack.config.js \
            --replace-fail "const COMMIT_HASH = execSync('git rev-parse HEAD').toString().trim();" \
                           "const COMMIT_HASH = '${finalAttrs.version}';"

        substituteInPlace src/common/CONSTANTS.js \
            --replace-fail "const DEFAULT_STREAMING_SERVER_URL = 'http://127.0.0.1:11470/';" \
                           "const DEFAULT_STREAMING_SERVER_URL = '${defaultStreamingServer}';"
    '';

    # Read by useServiceWorkerUpdater, which returns before registering anything. Workbox still emits service-worker.js into the build,
    # but nothing asks the browser to install it, which leaves nginx the only thing deciding what a page request returns.
    env.SERVICE_WORKER_DISABLED = "true";

    buildPhase = ''
        runHook preBuild
        pnpm build
        runHook postBuild
    '';

    installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r build/. $out/
        runHook postInstall
    '';

    meta = {
        description = "Browser build of Stremio, the media centre front end";
        homepage = "https://www.stremio.com/";
        license = lib.licenses.gpl3Only;
        platforms = lib.platforms.all;
    };
})
