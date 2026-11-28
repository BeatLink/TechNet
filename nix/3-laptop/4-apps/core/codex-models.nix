# CODEX Local Models ##################################################################################################################################
#
# A llama.cpp server each for Inkling 2 Mini, Qwen3.6-35B-A3B and Ternary Bonsai 2.5 27B, as user units the owner starts by hand.
# Every chat model answers on one port, the one CODEX is declared with, so the one running is the one CODEX uses; starting one stops the others.
# A chat model holds /run/user/1000/codex-gpu.lock while it runs, so no other session loads the 4 GB GPU underneath it.
#

{ pkgs, ... }:
let
    models = "/Storage/Files/Projects/X-Tech-Laboratories/CODEX/models";

    # Odin's dGPU is an 8.6 part, so one architecture keeps the CUDA build short
    llama = (pkgs.llama-cpp.override { cudaSupport = true; }).overrideAttrs (previous: {
        cmakeFlags = previous.cmakeFlags ++ [ "-DCMAKE_CUDA_ARCHITECTURES=86" ];
    });

    # Inkling's looped layers need Unsloth's fork; the other models run on the stock build
    llama_unsloth = pkgs.callPackage ./llama-cpp-unsloth.nix { };

    flock = "${pkgs.util-linux}/bin/flock /run/user/1000/codex-gpu.lock";
    chat_port = 18082;

    chat = { description, others, exec }: {
        Unit = {
            Description = "CODEX local model (${description})";
            Conflicts = map (name: "${name}.service") others;
        };
        Service = {
            Slice = "background.slice";
            ExecStart = "${flock} ${exec}";
            Restart = "no";
        };
    };
in
{
    nix.settings = {
        extra-substituters = [ "https://cache.nixos-cuda.org" ];
        extra-trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
    };

    home-manager.users.beatlink.systemd.user.services = {
        # Unsloth's guide command (https://unsloth.ai/docs/models/inkling-2-mini) and sampling, without the vision projector and drafter it says
        # can be left out; the context cut to what CODEX is declared with, as it says to when memory is limited; GPU layers left to the build's fit,
        # with a 256 MiB margin instead of its 1024 default, since the desktop runs on the integrated GPU
        codex-llm-inkling = chat {
            description = "Inkling 2 Mini";
            others = [ "codex-llm-qwen" "codex-llm-bonsai" ];
            exec = "${llama_unsloth}/bin/llama-server --host 127.0.0.1 --port ${toString chat_port} --model ${models}/Inkling-2-Mini-UD-Q4_K_M.gguf --alias inkling-2-mini --temp 1.0 --top-p 1.0 --top-k 0 --min-p 0.0 --ctx-size 32768 --parallel 1 --fit-target 256";
        };

        codex-llm-qwen = chat {
            description = "Qwen3.6-35B-A3B";
            others = [ "codex-llm-inkling" "codex-llm-bonsai" ];
            exec = "${llama}/bin/llama-server --host 127.0.0.1 --port ${toString chat_port} --model ${models}/Qwen3.6-35B-A3B-UD-IQ4_XS.gguf --alias qwen3.6-35b-a3b -ngl 999 --n-cpu-moe 39 -fa on -ctk q8_0 -ctv q8_0 -c 32768 -t 6 -b 1024 -ub 1024 --parallel 1 --jinja --reasoning-format auto";
        };

        # The Q2_0 file runs on stock llama.cpp from b11556 (https://huggingface.co/prism-ml/Ternary-Bonsai-2.5-27B-GGUF), with its card's sampling;
        # GPU layers left to the build's fit, the one setting that loaded on Odin
        codex-llm-bonsai = chat {
            description = "Ternary Bonsai 2.5 27B";
            others = [ "codex-llm-inkling" "codex-llm-qwen" ];
            exec = "${llama}/bin/llama-server --host 127.0.0.1 --port ${toString chat_port} --model ${models}/Ternary-Bonsai-2.5-27B-Q2_0.gguf --alias ternary-bonsai-2.5-27b -fa on -ctk q8_0 -ctv q8_0 -c 32768 -t 6 -b 512 -ub 512 --parallel 1 --jinja --reasoning-format auto --temp 1.0 --top-p 0.95 --top-k 20 --min-p 0";
        };
    };
}
