# Ragnarok — backup server

| | |
| --- | --- |
| Device | Pine64 Rock64 SBC, Rockchip RK3328 |
| Platform | `aarch64-linux` |
| Modules | [`nix/0-common`](../nix/0-common) + [`nix/1-backup-server`](../nix/1-backup-server) |
| Address | `ragnarok.technet` over WireGuard |

Ragnarok is a low-power SBC whose job is to hold backups. It is a WireGuard
client, dialling in to Heimdall.

Despite both being quad Cortex-A53 aarch64, it shares no silicon with Thor:
Ragnarok is Rockchip RK3328, Thor is Allwinner A64. Nothing vendor-specific
transfers between them — different U-Boot targets, different DTBs, and recovery
is Rockchip maskrom rather than Allwinner FEL. Its ethernet is `dwmac_rk` +
`stmmac`, both in the initrd so the tunnel has a link to run over.

## Backups

Borg is configured in [`7-borg.nix`](../nix/1-backup-server/1-system/7-borg.nix),
with the repository living on the data drive from
[`4-data-drive.nix`](../nix/1-backup-server/1-system/4-data-drive.nix). Other
hosts push to it; the `borg` group on each client grants repo access.

## Unlocking

Same arrangement as Heimdall — clevis against Odin's tang, enabled in
[`8-clevis.nix`](../nix/1-backup-server/1-system/8-clevis.nix), passphrase in
`secrets/1-backup-server/clevis.yaml`.

As a WireGuard *client*, its initrd recovery loop probes the server through the
tunnel (`10.100.100.1` out of `wg0`) rather than probing the LAN, since for a
client it is the tunnel itself that has to work.

## As a build host

Ragnarok is the only native `aarch64-linux` machine in the network. Odin can
build aarch64 closures through binfmt, but that is qemu emulation and slow.
Adding Ragnarok to `nix.buildMachines` on Odin would make Thor's builds native.

Two caveats: it is a modest SBC, so it is faster than emulation but not fast in
absolute terms, and it must be awake and unlocked to be useful — which, per the
tang arrangement, means Odin must be unlocked too.

## Rebuilding

```sh
nixtool run maintenance/rebuild --host Ragnarok --action dry-activate
nixtool run maintenance/rebuild --host Ragnarok --action switch
```

Builds for Ragnarok run on Odin under emulation unless a native builder is
configured, so expect them to take noticeably longer than Heimdall's.
