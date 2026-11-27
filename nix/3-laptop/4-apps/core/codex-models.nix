# CODEX Local Models ##################################################################################################################################
#
# A llama.cpp server for gpt-oss-20b and one for the embedder, as user units the owner starts and stops by hand; neither starts at login.
# The chat model holds /run/user/1000/codex-gpu.lock while it runs, so no other session loads the 4 GB GPU underneath it.
#

{ pkgs, ... }:
let
    models = "/Storage/Files/Projects/X-Tech-Laboratories/CODEX/models";

    # Odin's dGPU is an 8.6 part, so one architecture keeps the CUDA build short
    llama = (pkgs.llama-cpp.override { cudaSupport = true; }).overrideAttrs (previous: {
        cmakeFlags = previous.cmakeFlags ++ [ "-DCMAKE_CUDA_ARCHITECTURES=86" ];
    });

    chat_port = 18080;
    embed_port = 18081;
in
{
    nix.settings = {
        extra-substituters = [ "https://cache.nixos-cuda.org" ];
        extra-trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
    };

    home-manager.users.beatlink.systemd.user.services = {
        codex-llm = {
            Unit.Description = "CODEX local model (gpt-oss-20b)";
            Service = {
                Slice = "background.slice";
                ExecStart = "${pkgs.util-linux}/bin/flock /run/user/1000/codex-gpu.lock ${llama}/bin/llama-server --host 127.0.0.1 --port ${toString chat_port} --model ${models}/gpt-oss-20b-MXFP4.gguf --alias gpt-oss-20b -ngl 999 --n-cpu-moe 21 -fa on -ctk q8_0 -ctv q8_0 -c 32768 -t 6 -b 1024 -ub 1024 --parallel 1 --jinja --reasoning-format auto";
                Restart = "no";
            };
        };

        codex-embed = {
            Unit.Description = "CODEX local embedder (Qwen3-Embedding-0.6B)";
            Service = {
                Slice = "background.slice";
                ExecStart = "${llama}/bin/llama-server --host 127.0.0.1 --port ${toString embed_port} --model ${models}/Qwen3-Embedding-0.6B-Q8_0.gguf --embedding --pooling last --ctx-size 8192 --parallel 1 --threads 2 -ngl 0";
                Restart = "no";
            };
        };
    };
}
