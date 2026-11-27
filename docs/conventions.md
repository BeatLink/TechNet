# Conventions

How code in this tree is written, and the configuration traps that shape it.

## Comments

Comments are allowed for exactly four purposes:

1. A file header of at most five lines: the module's purpose and any hazard.
2. Section banners. Major sections are `# Section Name ####…`, subsections and functions `# Subsection name ----…`.
   Indentation, text and separator run to exactly 150 characters.
3. One sentence above a function saying what it does.
4. One line marking a hazard: a value that looks wrong but is right, or looks droppable but is load-bearing.

Everything else (mechanism, history, measurements, rejected alternatives) belongs in the commit, the PR or these
docs. A comment is one line and one sentence: no continuation paragraphs, no spacer lines, no quoted output. The
rule applies to existing files too: a rewrite strips old commentary rather than matching it.

A hazard comment says what the hazard is, not its mechanism, and names the way out if there is one. It sits on
the line that would have to change, and carries enough noun to read in place:

```nix
# 160 is unity, not a maximum; 192 is +24dB and clips into static
amixer -c "$card" cset name='AIF1 DA0 Playback Volume' 160
```

The test is whether an editor would act differently without the line. When a cleanup would delete a line of this
kind, keep it.

## Module layout

- Numeric prefixes belong to the top two directory levels only: the host (`0-common`, `3-laptop`) and the category
  under it (`1-system`, `2-users`, `3-services`, `4-apps`). Deeper folders and every `.nix` file have plain names.
  A category with one file is that file (`5-phone/2-users.nix`). A group of related modules gets a folder with a
  `default.nix`; the import order there is the only sequencing signal, so order it by how things apply.
- A module holding more than one domain is `config = lib.mkMerge [ … ]`, one `{ }` per domain under a banner. A
  single-domain module stays a plain attrset. Name a domain for its contents ("Silent Boot", not "Boot"), split a
  shared option path across domains when purpose demands, and keep settings that must agree in one block.
  `options` and `imports` stay above `config`. Check a migration is value-identical with `nix eval --apply` on a
  real host before and after, priorities included.
- Use `{ }` for several options under one prefix and dot notation for a lone leaf.

## Formatting

Run the `nixfmt` on PATH (the flake's own build) as `nixfmt --indent 4`; bare `nixfmt` reindents the whole file
to two spaces. The tree is at the formatter's fixed point, so only your edit should change. nixfmt can knock
banners off 150 columns, so check them afterwards.

## Storage and persistence

- The root drive, `/persistent` included, holds only what can be rebuilt. Before moving anything there, sort its
  files into rebuildable and not, and keep the rest under `/Storage`.
- A `.nobackup` marker (`backup-excludes.markers` in
  [`backup-excludes.nix`](../nix/0-common/3-services/backup-excludes.nix)) drops its whole directory from every
  backup with no log line. A new service's persistence directory must not reuse one that holds another unit's
  data: `ls /Storage/Services/` and grep the tree for the path first.
- `home.persistence."<root>".files = [ "<path>" ]` stores the file at `<root>/home/beatlink/<path>`. If that source
  is missing at switch time the home file is replaced by a dangling symlink, so seed it there before deploying.
- A file persisted on its own is a bind mount: `sed -i` and other rename-over writes fail with "Device or resource
  busy". Write in place instead. Persisted directories are unaffected.
- Activation scripts run in the initrd (`initrd-nixos-activation.service`), before switch-root and after initrd
  SSH is gone. Anything that walks `/Storage` belongs in a oneshot with `RequiresMountsFor`, or a slow walk hangs
  the boot with no journal to show for it.

## Networking

- `systemd.network` files apply in lexical order, and `99-ethernet-default-dhcp.network` from
  `networking.useDHCP` beats an unprefixed name. Name every network `NN-<iface>` and check the "Network File" line
  of `networkctl status <iface>`.
- NetworkManager profiles get their credentials by `$VAR` substitution from sops templates
  (`ensureProfiles.environmentFiles`). Keep each template's variables disjoint, since the last `EnvironmentFile`
  wins. A secret agent does not work here: NetworkManager only asks agents of the requesting uid.
- NetworkManager silently drops a keyfile that fails validation; the only trace is a `keyfile:` line in its
  journal, and a desktop prompt for the PSK is the symptom. `ipv4.gateway` is only legal with static `addresses`,
  and booleans take `true`/`false`, never `"yes"`. A cancelled prompt saves a PSK-less copy under
  `/etc/NetworkManager/system-connections/`, which outranks `/run`; delete it as part of the fix. A desktop-made
  copy has a v4 UUID, while ensureProfiles derives a v3 one.
- At home, Pi-hole answers `.technet` names with Heimdall's LAN address, so a Heimdall service reached by name
  from home needs its port open on the LAN interface as well as `wireguard0`. Test both addresses.

## Secrets

- `sops-install-secrets` decrypts every file before installing any, so one file not encrypted to the host fails
  all of its secrets. The running system keeps its old `/run/secrets` and looks fine until the next boot. Before
  a host consumes a secret, add it to the file's `creation_rules` in `.sops.yaml` and run `sops updatekeys`.
  Land a new sops key before or with the Nix change that references it.
- `boot.initrd.secrets` values must be string paths; a path literal is copied into the store at eval. They stay out
  of the store only while `boot.loader.supportsInitrdSecrets` is true; otherwise NixOS bakes them into the initrd
  store path. That is why the WireGuard peer endpoint is a sops-rendered `.netdev.d` drop-in
  (`technet.initrdWireguard.peer` in [`initrd-wireguard.nix`](../nix/0-common/1-system/networking/initrd-wireguard.nix)).
- [`secrets/admin/credential-flow.drawio`](../secrets/admin) maps what unlocks what; open it with
  [`open-credential-flow.sh`](open-credential-flow.sh).

## Commit signing

Odin signs commits with an SSH key from `secrets/3-laptop/git-signing.yaml`
([`git-signing.nix`](../nix/3-laptop/4-apps/tools/git-signing.nix)), and X-Nix signs its input updates with
`secrets/2-server/x-nix-signing.yaml` ([`x-nix.nix`](../nix/2-server/3-services/monitoring/x-nix.nix)). Both public
keys are in [`allowed-signers`](../nix/0-common/3-services/allowed-signers), which git and X-Nix's pull mode read.
Odin's pull mode only accepts signed heads; GitHub's merge commits are signed by GitHub's own key and never verify,
so the next X-Nix update commit on top is what Odin takes.

## Desktop settings

- An app with a `.dconf` export beside its module gets its keys from that file: the `dconf-load-*` user units from
  [`dconf.nix`](../nix/0-common/1-system/desktop/dconf.nix) run after Home Manager and win. Edit the export, and use
  `dconf.settings` only where no export covers the path.
- `dconf load` only writes, so a key removed from an export stays live on every host that loaded it. Reset it by
  hand after the switch (the outgoing loader fires once more during activation), one key at a time.
- A `programs.dconf.profiles.user.databases` change reaches a running session only when it restarts; a fresh
  `gsettings get` over SSH reads the new value and makes it look applied.
