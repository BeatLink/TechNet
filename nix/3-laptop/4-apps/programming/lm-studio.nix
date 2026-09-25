# LM Studio
#
# Desktop runner for local LLMs. It downloads its own llama.cpp runtimes on
# first launch, so the only GPU piece needed from NixOS is the CUDA driver.
# The model files are named here and fetched on demand, so they stay out of backups.
#
{ lib, ... }:
let
    # Models #########################################################################################################################################
    # The weights are 38GiB of content that Hugging Face already keeps a copy of, so they are excluded from the backups and listed here instead.
    # Each entry is a Hugging Face repository and the files wanted from it; anything not listed is left alone rather than deleted.
    models = {
        "lmstudio-community/gemma-4-26B-A4B-it-QAT-GGUF" = [ "gemma-4-26B-A4B-it-QAT-Q4_0.gguf" ];
        "lmstudio-community/gpt-oss-20b-GGUF" = [ "gpt-oss-20b-MXFP4.gguf" ];
        "lmstudio-community/Llama-3.2-3B-Instruct-GGUF" = [ "Llama-3.2-3B-Instruct-Q4_K_M.gguf" ];
        "lmstudio-community/Qwen3.5-4B-GGUF" = [ "Qwen3.5-4B-Q4_K_M.gguf" ];
        "lmstudio-community/Qwen3.5-9B-GGUF" = [
            "Qwen3.5-9B-Q4_K_M.gguf"
            "mmproj-Qwen3.5-9B-BF16.gguf"
        ];
        "Smoffyy/Qwen3.5-4B-Instruct-Revised-GGUF" = [
            "Qwen3.5-4B-Revised-q4_k_m.gguf"
            "mmproj-f16.gguf"
        ];
    };

    # Vision projectors parked outside the models tree, which is what lets the 4B load text-only and reach its 24k context.
    disabledMmproj = {
        "lmstudio-community/Qwen3.5-4B-GGUF" = [ "mmproj-Qwen3.5-4B-BF16.gguf" ];
    };

    # Renders one `fetch` call per wanted file, for the download service below.
    fetchCalls =
        dir: set:
        lib.flatten (
            lib.mapAttrsToList (
                repo: files:
                map (file: "fetch ${lib.escapeShellArg repo} ${lib.escapeShellArg file} ${dir} || rc=1") files
            ) set
        );

    # Load Setups ####################################################################################################################################
    # The 3050 Ti holds 3.68GiB. What fits in it is the whole question, so both setups below were measured on this host rather than guessed, and they
    # carry only the keys that were observed to reach llama.cpp -- the cache quantisation fields are flagged experimental in this build and are
    # silently dropped, so the contexts here are sized for an f16 cache.
    #
    # Speed: a 4B at Q4 with its weights and cache resident, nothing crossing the PCIe bus per token. Its vision projector was moved to
    # ~/.lmstudio/disabled-mmproj so the model loads text-only, which is what buys the 24k context; restoring the file caps it back at 8k.
    #
    # Quality: a 26B mixture-of-experts activates only 4B parameters per token, so the experts sit in system RAM while attention and the cache stay on
    # the GPU. 18 tok/s once warm, against 5.5 on the CPU alone and 8.9 for a dense 9B half-offloaded -- a bigger model that runs faster, because
    # what moves per token is what counts. It asks 14.4GiB of RAM against a desktop that already holds 12, so it is mapped rather than read in: the
    # first reply after a load is slow while pages fault in, and read in outright it puts 12GiB into zram and halves the rate.
    #
    # autoFit has to be off for the offload ratio to be read at all, and the runtime's strict VRAM cap has to be off with it: the cap sizes a layer by
    # its experts too, which on the 26B leaves 6 layers on the GPU when all 41 belong there.
    setups = {
        "qwen/qwen3.5-4b" = {
            "llm.load.contextLength" = 24576;
            "llm.load.offloadKVCacheToGpu" = true;
            "llm.load.llama.autoFit" = false;
            "llm.load.llama.acceleration.offloadRatio" = 1;
            "llm.load.numParallelSessions" = 1; # Four sessions split the cache four ways and cost VRAM for parallelism nobody here uses
            "llm.load.llama.cpuThreadPoolSize" = 6; # The six physical cores; 12 oversubscribes them and measured 1.3 tok/s
        };
        # The lighter of the two mixture-of-experts models: near enough the same rate as the 26B for 2.4GiB less RAM, which is the difference
        # between 8GiB free and 14GiB while it runs. Reach for it when the desktop is busy.
        "lmstudio-community/gpt-oss-20b-GGUF/gpt-oss-20b-MXFP4.gguf" = {
            "llm.load.contextLength" = 32768;
            "llm.load.offloadKVCacheToGpu" = true;
            "llm.load.llama.autoFit" = false;
            "llm.load.llama.acceleration.offloadRatio" = 1;
            "llm.load.numParallelSessions" = 1;
            "llm.load.llama.cpuThreadPoolSize" = 6;
            "llm.load.numCpuExpertLayersRatio" = 1;
            "llm.load.llama.tryMmap" = true;
            "llm.load.llama.keepModelInMemory" = false;
        };
        "lmstudio-community/gemma-4-26B-A4B-it-QAT-GGUF/gemma-4-26B-A4B-it-QAT-Q4_0.gguf" = {
            "llm.load.contextLength" = 32768;
            "llm.load.offloadKVCacheToGpu" = true;
            "llm.load.llama.autoFit" = false;
            "llm.load.llama.acceleration.offloadRatio" = 1;
            "llm.load.numParallelSessions" = 1;
            "llm.load.llama.cpuThreadPoolSize" = 6;
            "llm.load.numCpuExpertLayersRatio" = 1; # Every expert on the CPU, which is what leaves the GPU for attention and the cache
            "llm.load.llama.tryMmap" = true; # Mapped, so the kernel can drop pages under pressure; read in outright it lands in zram instead
            "llm.load.llama.keepModelInMemory" = false;
        };
    };

    toFields = attrs: lib.mapAttrsToList (key: value: { inherit key value; }) attrs;
in
{
    home-manager.users.beatlink =
        { lib, pkgs, ... }: # home-manager's own lib, which carries lib.hm
        {
            home = {
                packages = [ pkgs.lmstudio ];

                persistence."/Storage/Apps/AI/LMStudio" = {
                    directories = [
                        ".lmstudio" # Models, chats, presets and the downloaded runtimes
                        ".config/LM Studio" # Window state and app preferences
                    ];
                };

                # Load Settings ######################################################################################################################
                # LM Studio answers a small card by keeping the KV cache in system RAM, and every token attends over the whole cache, so that puts a
                # PCIe round trip in the hot path once per token: measured at 7k tokens of context, 6.8 tok/s against 58.7 tok/s with it on the GPU.
                #
                # The app owns these files and rewrites them, so this merges the keys it cares about rather than symlinking them from the store.
                activation.lmStudioSetups = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    internal="$HOME/.lmstudio/.internal"
                    jq=${lib.getExe pkgs.jq}
                    [ -d "$internal" ] || exit 0

                    # Restates the runtime defaults for every installed engine, so a newly added model starts out right and a runtime update
                    # cannot bring the old answers back.
                    if [ -f "$internal/hardware-config.json" ]; then
                        kv="llm.load.offloadKVCacheToGpu"
                        cap="load.gpuStrictVramCap"
                        "$jq" --arg kv "$kv" --arg cap "$cap" \
                            '.json |= map(.[1].fields |= (
                                 map(select(.key != $kv and .key != $cap))
                                 + [{ key: $kv, value: true }, { key: $cap, value: false }]
                             ))' \
                            "$internal/hardware-config.json" > "$internal/hardware-config.json.new" \
                            && run mv "$internal/hardware-config.json.new" "$internal/hardware-config.json"
                    fi

                    # A per-model file saved from the GUI outranks the runtime default, so every one of them is swept too, not just the setups below.
                    find "$internal/user-concrete-model-default-config" -name '*.json' -print0 2>/dev/null | while IFS= read -r -d "" cfg; do
                        "$jq" --arg k "llm.load.offloadKVCacheToGpu" 'walk(if type == "object" and .key == $k then .value = true else . end)' \
                            "$cfg" > "$cfg.new" && mv "$cfg.new" "$cfg"
                    done

                    # With the strict cap off, a model with no context of its own reaches for its full native window -- 128k on a 3B is
                    # 14GiB of cache -- and fails to load. Every installed model without one is given a modest default instead.
                    find "$HOME/.lmstudio/models" -name '*.gguf' ! -name 'mmproj*' -print0 2>/dev/null | while IFS= read -r -d "" model; do
                        rel="''${model#$HOME/.lmstudio/models/}"
                        cfg="$internal/user-concrete-model-default-config/$rel.json"
                        [ -f "$cfg" ] && "$jq" -e '.load.fields[]? | select(.key == "llm.load.contextLength")' "$cfg" >/dev/null 2>&1 && continue
                        mkdir -p "$(dirname "$cfg")"
                        [ -f "$cfg" ] || echo '{"preset":"","operation":{"fields":[]},"load":{"fields":[]}}' > "$cfg"
                        "$jq" '.load.fields += [{ key: "llm.load.contextLength", value: 8192 }]' "$cfg" > "$cfg.new" \
                            && mv "$cfg.new" "$cfg"
                    done

                    # Each setup above is then merged into its own file, leaving any key not named there as the app left it.
                    apply_setup() {
                        cfg="$internal/user-concrete-model-default-config/$1.json"
                        run mkdir -p "$(dirname "$cfg")"
                        [ -f "$cfg" ] || echo '{"preset":"","operation":{"fields":[]},"load":{"fields":[]}}' > "$cfg"
                        "$jq" --argjson new "$2" \
                            '.load.fields = (((.load.fields // []) | map(select(.key as $k | ($new | map(.key) | index($k)) == null))) + $new)' \
                            "$cfg" > "$cfg.new" && run mv "$cfg.new" "$cfg"
                    }

                    ${lib.concatStringsSep "\n                    " (
                        lib.mapAttrsToList (
                            path: fields:
                            "apply_setup ${lib.escapeShellArg path} ${lib.escapeShellArg (builtins.toJSON (toFields fields))}"
                        ) setups
                    )}
                '';
            };

            # Model Downloads ########################################################################################################################
            # Fetches any listed file that is not on disk, so a restored machine reaches the same set of models without them being in a backup.
            # Removing a model from the lists above stops it being fetched; it does not delete a copy that is already there.
            systemd.user.services.lm-studio-models = {
                Unit = {
                    Description = "Fetch the LM Studio models named in the flake";
                    After = [ "network-online.target" ];
                    Wants = [ "network-online.target" ];
                };
                Service = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    Nice = 19;
                    IOSchedulingClass = "idle";
                    ExecStart = pkgs.writeShellScript "lm-studio-models" ''
                        set -u
                        # Downloads one file into the named directory, resuming a part-file and leaving the final name untouched until it completes.
                        fetch() {
                            repo="$1"
                            file="$2"
                            case "$3" in
                                models) dest="$HOME/.lmstudio/models/$repo/$file" ;;
                                *) dest="$HOME/.lmstudio/disabled-mmproj/$file" ;;
                            esac
                            [ -f "$dest" ] && return 0
                            mkdir -p "$(dirname "$dest")"
                            ${lib.getExe pkgs.curl} -fL --retry 5 --retry-delay 10 --retry-all-errors -C - \
                                -o "$dest.part" "https://huggingface.co/$repo/resolve/main/$file" || return 1
                            mv "$dest.part" "$dest"
                        }

                        rc=0
                        ${lib.concatStringsSep "\n" (
                            fetchCalls "models" models ++ fetchCalls "disabled-mmproj" disabledMmproj
                        )}
                        exit $rc
                    '';
                };
                Install.WantedBy = [ "default.target" ];
            };
        };
}
