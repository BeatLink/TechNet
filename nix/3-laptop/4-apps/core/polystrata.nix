# PolyStrata ##########################################################################################################################################
#
# PolyStrata (https://github.com/simplexai-labs/PolyStrata, Apache 2.0), a local inference server with an OpenAI-compatible API, as released:
# its Python server from the tagged source and its ready-made strata-poly engine (CUDA 13, built for sm_86 among others), checked against the
# digest GitHub publishes for it, with the engine's libraries pointed at nixpkgs' CUDA 13 runtime and the driver's libcuda.
# `polystrata-serve <config> <port>` runs the server; `polystrata-prepare <gguf> <pack>` writes a model's tokenizer from its GGUF.
#

{
    stdenv,
    fetchFromGitHub,
    fetchurl,
    autoPatchelfHook,
    autoAddDriverRunpath,
    cudaPackages_13_0,
    python3,
    writeShellScriptBin,
    symlinkJoin,
}:
let
    version = "0.2.20-poly.6";

    source = fetchFromGitHub {
        owner = "simplexai-labs";
        repo = "PolyStrata";
        rev = "v${version}";
        hash = "sha256-YKB0oCkQcRod0KHRJgJFouf2vYHP6Oy+T23i54CSc1g=";
    };

    engine = stdenv.mkDerivation {
        pname = "strata-poly";
        inherit version;

        src = fetchurl {
            url = "https://github.com/simplexai-labs/PolyStrata/releases/download/v${version}/strata-poly-linux-x64-cuda13-a5588664228fc21e.tar.gz";
            hash = "sha256-v/UD1/r3uf5NDd8DAkgTosxApm87Xf+pbuEaArHdT+w=";
        };

        sourceRoot = ".";

        nativeBuildInputs = [
            autoPatchelfHook
            autoAddDriverRunpath
        ];

        buildInputs = [
            stdenv.cc.cc.lib
            cudaPackages_13_0.cuda_cudart
            cudaPackages_13_0.libcublas
        ];

        # libcuda comes from the NVIDIA driver at run time, through the driver runpath
        autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];

        installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp -a strata-poly strata-vision BUILD.json $out/bin/
            runHook postInstall
        '';
    };

    python = python3.withPackages (packages: with packages; [
        numpy
        jinja2
        regex
        pyyaml
        requests
        pillow
        psutil
        truststore
    ]);

    terminal = "${source}/terminal";

    serve = writeShellScriptBin "polystrata-serve" ''
        export PYTHONDONTWRITEBYTECODE=1
        exec ${python}/bin/python ${terminal}/serve/server.py --engine strata --config "$1" --host 127.0.0.1 --port "$2"
    '';

    prepare = writeShellScriptBin "polystrata-prepare" ''
        export PYTHONDONTWRITEBYTECODE=1
        exec ${python}/bin/python ${terminal}/tools/strata_tokenizer.py --gguf "$1" --out "$2"
    '';
in
symlinkJoin {
    name = "polystrata-${version}";
    paths = [ serve prepare ];
    passthru.engine = "${engine}/bin/strata-poly";
}
