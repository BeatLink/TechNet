#  MQTTX Web
#
#  The browser build of MQTTX -- the same client as the desktop app in nixpkgs,
#  minus Electron. `web/` in the MQTTX repository is a self-contained Vue project
#  with its own yarn.lock, so this builds it the way nixpkgs builds `cli/`:
#  fetch the offline cache, `yarn build`, keep `dist/`. The result is static
#  files for nginx to serve; nothing runs on the server.
#
#  It is self-contained -- no CDN, no fonts or scripts fetched at page load,
#  which is what ruled out HiveMQ's client (it pulls jQuery, lodash and moment
#  from googleapis and cdnjs on every visit). MQTTX bundles Google Tag Manager
#  but only arms it when VUE_APP_IS_ONLINE_ENV is set, which is what the
#  `online` build mode does and this one does not.
#
#  The connection form's defaults are patched to point at this network's broker,
#  so opening the page and pressing Connect needs only the password.
{
    lib,
    stdenv,
    fetchFromGitHub,
    fetchYarnDeps,
    nodejs,
    yarnConfigHook,
    defaultHost ? "broker.emqx.io",
    defaultPort ? 8083,
    defaultTls ? false,
    pageTitle ? "MQTT Client",
}:

stdenv.mkDerivation (finalAttrs: {
    pname = "mqttx-web";
    version = "1.12.1";

    src = fetchFromGitHub {
        owner = "emqx";
        repo = "MQTTX";
        tag = "v${finalAttrs.version}";
        hash = "sha256-aUxhCUx89Qrqkv0zvgMZhC6SUQlxFoJs2elYtUlMio4=";
    };

    yarnOfflineCache = fetchYarnDeps {
        yarnLock = "${finalAttrs.src}/web/yarn.lock";
        hash = "sha256-rbZtlx6k0dnyACzRMsLABjr/22DYzse2pJ0l+GdjILE=";
    };

    nativeBuildInputs = [
        nodejs
        yarnConfigHook
    ];

    # The upstream defaults are the public test broker. Every one of these is a
    # `--replace-fail`, so a version bump that reworks them fails the build
    # rather than quietly shipping a form pointing at broker.emqx.io.
    postPatch = ''
        substituteInPlace web/.env \
            --replace-fail 'VUE_APP_DEFAULT_HOST=broker.emqx.io' \
                           'VUE_APP_DEFAULT_HOST=${defaultHost}' \
            --replace-fail 'VUE_APP_PAGE_TITLE=Easy-to-Use Online MQTT Client | Try Now' \
                           'VUE_APP_PAGE_TITLE=${pageTitle}'

        substituteInPlace web/src/utils/mqttUtils.ts \
            --replace-fail "protocol: process.env.VUE_APP_IS_ONLINE_ENV === 'true' ? 'wss' : 'ws'," \
                           "protocol: '${if defaultTls then "wss" else "ws"}'," \
            --replace-fail "port: process.env.VUE_APP_IS_ONLINE_ENV === 'true' ? 8084 : 8083," \
                           "port: ${toString defaultPort}," \
            --replace-fail "ssl: false," \
                           "ssl: ${lib.boolToString defaultTls},"
    '';

    preConfigure = ''
        cd web
    '';

    # Not yarnBuildHook: the build needs --ignore-engines, the same reason
    # nixpkgs' mqttx-cli spells its build phase out by hand.
    buildPhase = ''
        runHook preBuild
        yarn --offline --ignore-engines build
        runHook postBuild
    '';

    installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r dist/. $out/
        runHook postInstall
    '';

    meta = {
        description = "Browser-based MQTT 5.0 client, the web build of MQTTX";
        homepage = "https://mqttx.app/web";
        license = lib.licenses.asl20;
        platforms = lib.platforms.all;
    };
})
