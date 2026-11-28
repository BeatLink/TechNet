# llama.cpp, Unsloth's Fork ###########################################################################################################################
#
# The build Unsloth's Inkling 2 Mini guide names (https://unsloth.ai/docs/models/inkling-2-mini): b12649-mix-c7059d6, with looped-layer support.
# Mainline builds before it give garbage from Inkling's looped layers (ggml-org/llama.cpp#32710, #32778). CUDA for Odin's 8.6 part only.
#

{ llama-cpp, fetchFromGitHub, cudaPackages, lib }:
(llama-cpp.override { cudaSupport = true; }).overrideAttrs (previous: {
    version = "b12649-mix-c7059d6";
    src = fetchFromGitHub {
        owner = "unslothai";
        repo = "llama.cpp";
        tag = "b12649-mix-c7059d6";
        hash = "sha256-lg4XMHZH76n93Bf5U9vsKMnjqQm/OLSkbuFfhzNO3Zw=";
    };
    # The web UI is built with npm in this tree; the server runs headless for CODEX, so it is left out
    npmDeps = null;
    nativeBuildInputs = builtins.filter (input: !(lib.hasInfix "npm-config-hook" (input.name or ""))) previous.nativeBuildInputs;
    preConfigure = "";
    buildInputs = previous.buildInputs ++ [ cudaPackages.cuda_nvml_dev ];
    cmakeFlags = previous.cmakeFlags ++ [ "-DCMAKE_CUDA_ARCHITECTURES=86" "-DLLAMA_USE_PREBUILT_UI=OFF" "-DLLAMA_BUILD_UI=OFF" ];
})
