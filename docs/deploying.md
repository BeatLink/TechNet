# Deploying

Every host is deployed by [X-Nix](../nix/2-server/3-services/monitoring/x-nix.nix) on Heimdall, never by hand:
no `nixos-rebuild`, `nixtool` or `switch-to-configuration` from a shell.

## How a change reaches the hosts

- Every deployment has `auto_switch` on. Once `origin/main` moves, X-Nix builds the closure in the TechNet cache
  and switches the host, usually within minutes. Landing on `main` is therefore deploying, and a generation
  deployed from a branch would be replaced by `main` within the hour.
- The cache builds on Heimdall only (`caches.technet.host`); Odin never builds. A Thor build that takes four
  minutes on Odin takes about twenty on Heimdall, and that is accepted.
- One unbuildable package anywhere in a closure blocks that host's switch.
- X-Nix can lag a merge by a few minutes; `refresh_flake` on `technet-config` makes it read the new revision.
- X-Nix's switch watchdog gives up after 240 s (`activation_timeout`), but the switch keeps running and usually
  completes, and on Odin build time counts against the limit. Read `get_deployment` or the host's
  `/run/current-system` before treating it as failed; it is usually "switched late".
- X-Nix evaluates `github:BeatLink/TechNet` per host, so a commit landing mid-deploy can split the fleet across
  revisions. To check what a host runs, compare against the deployed drv's `outputs.out.path`, not a fresh
  `nix eval`, which may include later commits.

## Before landing

- Make sure nothing a switch would stop or remove is mid-run: backups, checks, long jobs. A switch once removed
  borgmatic in the middle of an upload.
- A change that restarts the user's desktop apps on Odin needs the user's go-ahead before the merge.
- Review a risky change with a `dry-activate` through X-Nix's `run_deployment_action`, and read the "would stop"
  list. If it unmounts a live filesystem (removing `tmp.mount` did, and hung Thor), deploy it to boot and reboot.
- `git add` new files before building: a flake only sees tracked files.
- Merge `main` into a PR branch rather than rebasing it. A rebase takes the branch's `flake.lock` whole and silently
  reverts every input bump that landed meanwhile. After any rebase that touched the lock, compare it with
  `git log main -- flake.nix flake.lock`.
- Never pipe a build, copy or flash whose exit status matters through `tail` or `head`: the pipeline reports the
  pager's status.

## After a switch

A switch exits 0 in all of these cases:

- **New user units** are written but not started in the running session. Check `systemctl --user is-active`.
- **Group changes** do not reach a running service. Compare `Groups:` in `/proc/<MainPID>/status` with `id`, and
  restart the unit.
- **A new `home.persistence` directory** mounts after Home Manager has written into it, hiding those files. Restart
  `home-manager-beatlink.service` and any new user service writing there.
- **Re-pointing a persisted `/etc/<dir>`** mounts the new, empty backing directory over the `environment.etc` files
  just installed. Pre-seed them from `/etc/static/<dir>/` with the module's owner and mode, or reinstall them right
  after and restart the service.
- **NetworkManager profiles** come from `NetworkManager-ensure-profiles`, a oneshot the switch neither stops nor
  starts. Start it by hand, then check `journalctl -u NetworkManager | grep keyfile:` is empty.
- **Secrets**: grep the switch log for `failed to decrypt` (see [conventions](conventions.md#secrets)).
- **Pi-hole lists**: check `pihole -q <domain>` names the new list.

systemd keeps no timestamps or `Result` for an inactive oneshot across a switch, so date runs such as `nix-gc`
from the journal (`journalctl -u nix-gc -o short-unix -g 'store paths deleted' -n 1`), not `systemctl show`.

## CI

[`ci.yml`](../.github/workflows/ci.yml) builds every host in `nixosConfigurations` on a runner of its own platform.
Its first job reads the flake's `checks` output to fill the matrix, so a new host joins with no workflow edit.

- Thor is evaluated on an arm64 runner, because [`gnss.nix`](../nix/5-phone/1-system/gnss.nix) reads a file out
  of an aarch64 source at evaluation time.
- `cancel-in-progress` is on for pull requests only: X-Nix pushes input updates to `main` faster than Odin's
  hour-long build, so cancelling there meant no run ever finished.
- Odin's CI build stubs Packet Tracer (`ciModules` in `flake.nix`), since its installer is added by hand.
- A red Heimdall job on a calibre test is a new flaky test; extend the exclusions in
  [`calibre-web-nextgen.nix`](../nix/2-server/3-services/fun-and-media/calibre-web-nextgen.nix).

## Cross-architecture builds

Odin and Heimdall build aarch64 under binfmt emulation. qemu-user cannot emulate user namespaces, so a check phase
that runs `bwrap` fails whatever the sandbox setting; turn the check off (as in
[`calls.nix`](../nix/5-phone/1-system/calls.nix)). Emulation also cannot run foreign tools that talk to the host
kernel, such as `zpool`; see [installing](installing.md#disko-for-an-aarch64-host).
