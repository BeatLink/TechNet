# llama.cpp, Unsloth's Prebuilt #######################################################################################################################
#
# The build Unsloth's Inkling 2 Mini guide names (https://unsloth.ai/docs/models/inkling-2-mini): b12649-mix-c7059d6, upstream b12649 merged with the
# Inkling PRs at release time (its release notes), from a commit that is not published, so the git tag alone does not load Inkling and only the
# release archive is the tested build. The CUDA 12 portable archive, checked against the digest GitHub publishes for it, with its libraries
# pointed at nixpkgs' CUDA 12 runtime and the driver's libcuda.
#

{
    stdenv,
    fetchurl,
    autoPatchelfHook,
    autoAddDriverRunpath,
    cudaPackages_12,
    openssl,
}:
stdenv.mkDerivation {
    pname = "llama-cpp-unsloth";
    version = "b12649-mix-c7059d6";

    src = fetchurl {
        url = "https://github.com/unslothai/llama.cpp/releases/download/b12649-mix-c7059d6/app-b12649-mix-c7059d6-linux-x64-cuda12-portable.tar.gz";
        hash = "sha256-Y/AxdRkn+waJSSjhi/RufxZMVVuIB8isTpY+ajfG1Cw=";
    };

    # The archive holds its files at the top, with no folder of its own
    sourceRoot = ".";

    nativeBuildInputs = [
        autoPatchelfHook
        autoAddDriverRunpath
    ];

    buildInputs = [
        stdenv.cc.cc.lib
        cudaPackages_12.cuda_cudart
        cudaPackages_12.libcublas
        openssl
    ];

    # libcuda comes from the NVIDIA driver at run time, through the driver runpath
    autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];

    # The binaries find their own libraries beside them ($ORIGIN), so everything stays in one folder
    installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        cp -a ./* $out/bin/
        rm -f $out/bin/env-vars
        runHook postInstall
    '';
}
