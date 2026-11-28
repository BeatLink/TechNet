# CODEX Local Models ##################################################################################################################################
#
# A server each for Inkling 2 Mini (PolyStrata), Qwen3.6-35B-A3B, Ternary Bonsai 2.5 27B and LFM2.5-8B-A1B (llama.cpp), as user units the owner starts by hand.
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

    polystrata = pkgs.callPackage ./polystrata.nix { };

    flock = "${pkgs.util-linux}/bin/flock /run/user/1000/codex-gpu.lock";
    chat_port = 18082;

    # PolyStrata keeps the model's tokenizer, run config, log and expert counts here
    inkling_state = "/home/beatlink/.local/state/polystrata/inkling-2-mini-ud-q2_k_xl";
    inkling_model = "${models}/Inkling-2-Mini-UD-Q2_K_XL.gguf";

    # PolyStrata setup's run config for this file on a card that holds few of its experts
    inkling_config = pkgs.writeText "strata-inkling-2-mini.json" (builtins.toJSON {
        exe = polystrata.engine;
        args = [
            "--model" inkling_model
            "--max-context" "16384"
            "--expert-profile" "${inkling_state}/expert-profile.txt"
            "--attn-requant" "q5_k"
            "--loop-bf16"
            "--tail-skip" "4"
        ];
        cwd = inkling_state;
        tokenizer = "${inkling_state}/tokenizer";
        model_name = "inkling-2-mini";
        display_name = "Inkling 2 Mini UD-Q2_K_XL";
        log = "${inkling_state}/strata.log";
        port = chat_port;
        mtp = false;
        gpu = 0;
        reasoning_effort = "low";
    });

    # The tokenizer is read from the GGUF once; the config is copied so the server can save its settings beside it
    inkling_prepare = pkgs.writeShellScript "polystrata-inkling-prepare" ''
        mkdir -p ${inkling_state}
        [ -e ${inkling_state}/tokenizer/vocab.json ] || ${polystrata}/bin/polystrata-prepare ${inkling_model} ${inkling_state}
        install -m 644 ${inkling_config} ${inkling_state}/strata.json
    '';

    chat = { description, others, exec, prepare ? null }: {
        Unit = {
            Description = "CODEX local model (${description})";
            Conflicts = map (name: "${name}.service") others;
        };
        Service = {
            Slice = "background.slice";
            ExecStart = "${flock} ${exec}";
            Restart = "no";
        } // (if prepare == null then { } else { ExecStartPre = "${prepare}"; });
    };
in
{
    nix.settings = {
        extra-substituters = [ "https://cache.nixos-cuda.org" ];
        extra-trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
    };

    home-manager.users.beatlink.systemd.user.services = {
        # PolyStrata runs the looped layers itself and keeps most experts in RAM beside the 4 GB card
        codex-llm-inkling = chat {
            description = "Inkling 2 Mini";
            others = [ "codex-llm-qwen" "codex-llm-bonsai" "codex-llm-lfm" ];
            prepare = inkling_prepare;
            exec = "${polystrata}/bin/polystrata-serve ${inkling_state}/strata.json ${toString chat_port}";
        };

        codex-llm-qwen = chat {
            description = "Qwen3.6-35B-A3B";
            others = [ "codex-llm-inkling" "codex-llm-bonsai" "codex-llm-lfm" ];
            exec = "${llama}/bin/llama-server --host 127.0.0.1 --port ${toString chat_port} --model ${models}/Qwen3.6-35B-A3B-UD-IQ4_XS.gguf --alias qwen3.6-35b-a3b -ngl 999 --n-cpu-moe 39 -fa on -ctk q8_0 -ctv q8_0 -c 32768 -t 6 -b 1024 -ub 1024 --parallel 1 --jinja --reasoning-format auto";
        };

        # The Q2_0 file runs on stock llama.cpp from b11556 (https://huggingface.co/prism-ml/Ternary-Bonsai-2.5-27B-GGUF), with its card's sampling;
        # GPU layers left to the build's fit, the one setting that loaded on Odin
        codex-llm-bonsai = chat {
            description = "Ternary Bonsai 2.5 27B";
            others = [ "codex-llm-inkling" "codex-llm-qwen" "codex-llm-lfm" ];
            exec = "${llama}/bin/llama-server --host 127.0.0.1 --port ${toString chat_port} --model ${models}/Ternary-Bonsai-2.5-27B-Q2_0.gguf --alias ternary-bonsai-2.5-27b -fa on -ctk q8_0 -ctv q8_0 -c 32768 -t 6 -b 512 -ub 512 --parallel 1 --jinja --reasoning-format auto --temp 1.0 --top-p 0.95 --top-k 20 --min-p 0";
        };

        # Every layer on the GPU but the experts, which stay on the CPU, at the context CODEX is declared with
        codex-llm-lfm = chat {
            description = "LFM2.5-8B-A1B";
            others = [ "codex-llm-inkling" "codex-llm-qwen" "codex-llm-bonsai" ];
            exec = "${llama}/bin/llama-server --host 127.0.0.1 --port ${toString chat_port} --model ${models}/LFM2.5-8B-A1B-Q4_K_M.gguf --alias lfm2.5-8b-a1b -c 16384 -fa on -ctk q8_0 -ctv q8_0 -ngl 99 -ot .ffn.*_exps.=CPU --parallel 1 --jinja --temp 0.3 --min-p 0.15";
        };
    };
}
