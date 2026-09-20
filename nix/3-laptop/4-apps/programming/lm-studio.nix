# LM Studio
#
# Desktop runner for local LLMs. It downloads its own llama.cpp runtimes on
# first launch, so the only GPU piece needed from NixOS is the CUDA driver.
#
{ lib, ... }:
let
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
        };
}
