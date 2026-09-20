# LM Studio
#
# Desktop runner for local LLMs. It downloads its own llama.cpp runtimes on
# first launch, so the only GPU piece needed from NixOS is the CUDA driver.
#
{ lib, ... }:
let
    # Load Setups ####################################################################################################################################
    # The 3050 Ti holds 3.68GiB. What fits in it is the whole question, so both setups below were measured on this host rather than guessed.
    #
    # Speed: a 4B at Q4 leaves just enough room for a 32k cache at Q8, so weights and cache are both resident and nothing crosses the PCIe bus per
    # token. Quantising the cache is free here -- a smaller cache is less to read each token, so it measured faster than f16 at half the size.
    # Measured 47.3 tok/s at 32k, filling 3654MiB of the 3762MiB available.
    #
    # Quality: a 26B mixture-of-experts activates only 4B parameters per token, so the experts sit in system RAM while attention and the cache stay on
    # the GPU. That is worth 23.2 tok/s against 5.5 on the CPU alone, and beats the 8.9 tok/s a dense 9B manages half-offloaded -- a bigger model that
    # runs faster, because what moves per token is what counts. It asks 14.4GiB of RAM and only 2950MiB of VRAM.
    setups = {
        "lmstudio-community/Qwen3.5-4B-GGUF/Qwen3.5-4B-Q4_K_M.gguf" = {
            "llm.load.contextLength" = 32768;
            "llm.load.offloadKVCacheToGpu" = true;
            "llm.load.llama.flashAttention" = true;
            "llm.load.llama.kCacheQuantizationType" = "q8_0";
            "llm.load.llama.vCacheQuantizationType" = "q8_0";
            "llm.load.llama.acceleration.offloadRatio" = 1;
        };
        "lmstudio-community/gemma-4-26B-A4B-it-QAT-GGUF/gemma-4-26B-A4B-it-QAT-Q4_0.gguf" = {
            "llm.load.contextLength" = 32768;
            "llm.load.offloadKVCacheToGpu" = true;
            "llm.load.llama.flashAttention" = true;
            "llm.load.llama.kCacheQuantizationType" = "q8_0";
            "llm.load.llama.vCacheQuantizationType" = "q8_0";
            "llm.load.llama.acceleration.offloadRatio" = 1;
            "llm.load.numCpuExpertLayersRatio" = 1; # Every expert on the CPU, which is what leaves the GPU for attention and the cache
            "llm.load.llama.tryMmap" = false; # 14.4GiB read into RAM outright, rather than paged in against a desktop already holding 12GiB
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
                    kv="llm.load.offloadKVCacheToGpu"
                    [ -d "$internal" ] || exit 0

                    # Restates the runtime default for every installed engine, so a newly added model starts out right and a runtime update cannot
                    # bring the old answer back.
                    if [ -f "$internal/hardware-config.json" ]; then
                        "$jq" --arg k "$kv" '.json |= map(.[1].fields |= (map(select(.key != $k)) + [{ key: $k, value: true }]))' \
                            "$internal/hardware-config.json" > "$internal/hardware-config.json.new" \
                            && run mv "$internal/hardware-config.json.new" "$internal/hardware-config.json"
                    fi

                    # A per-model file saved from the GUI outranks the runtime default, so every one of them is swept too, not just the setups below.
                    find "$internal/user-concrete-model-default-config" -name '*.json' -print0 2>/dev/null | while IFS= read -r -d "" cfg; do
                        "$jq" --arg k "$kv" 'walk(if type == "object" and .key == $k then .value = true else . end)' \
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
