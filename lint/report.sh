# Redundant Defaults Report ##########################################################################################################################
#
# Runs the redundant-defaults scan once per host, each in its own evaluation, and prints one warning per option this repo sets to its default value.
#

usage() {
    echo "usage: nix run .#lint -- [--fail] [host...]" >&2
    echo "  --fail   exit non-zero when anything is reported, for CI" >&2
}

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
scanner="$root/lint/redundant-defaults.nix"
failOnFindings=0
hosts=()

for argument in "$@"; do
    case "$argument" in
        --fail) failOnFindings=1 ;;
        -h | --help) usage; exit 0 ;;
        -*) usage; exit 2 ;;
        *) hosts+=("$argument") ;;
    esac
done

if [ ! -f "$scanner" ]; then
    echo "lint: no $scanner -- run this from a TechNet checkout" >&2
    exit 1
fi

if [ ${#hosts[@]} -eq 0 ]; then
    mapfile -t hosts < <(
        nix eval --impure --raw --expr \
            "builtins.concatStringsSep \"\n\" (builtins.attrNames (builtins.getFlake \"$root\").nixosConfigurations)"
    )
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

for host in "${hosts[@]}"; do
    echo "lint: scanning $host" >&2
    nix eval --impure --json --expr "import $scanner { flakePath = \"$root\"; host = \"$host\"; }" \
        | jq --arg host "$host" 'map(. + { host: $host })' > "$work/$host.json"
done

jq -s -r '
    add
    | group_by([.file, .line, .option])
    | map(.[0] + { hosts: (map(.host) | unique | join(", ")) })
    | sort_by(.file, .line)
    | .[]
    | if .option == null
      then "\(.file): warning: \(.value) (\(.hosts))"
      elif .certain
      then "\(.file):\(.line): warning: \(.option) is already \(.value) by default (\(.hosts))"
      else "\(.file):\(.line): note: \(.option) matches the default package by name; check whether the build differs (\(.hosts))"
      end
' "$work"/*.json

findings="$(jq -s '[.[][]] | group_by([.file, .line, .option]) | length' "$work"/*.json)"

if [ "$findings" -eq 0 ]; then
    echo "lint: nothing set to its own default" >&2
    exit 0
fi

echo "lint: $findings settings match the option default; silence any that are deliberate in lint/allowed-defaults.nix" >&2
[ "$failOnFindings" -eq 1 ] && exit 1
exit 0
