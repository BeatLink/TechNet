# TechNet

Read [docs/conventions.md](docs/conventions.md) before editing Nix and [docs/deploying.md](docs/deploying.md)
before landing anything. Host specifics are in `docs/<host>.md`.

- **Verify, never assume.** Every claim about this repo, a host or its hardware comes from something checked in
  this session: the tree, `docs/`, or the live host. A fact about one host does not transfer to another. Say
  "unverified" when it cannot be checked.
- **Landing on `main` is deploying.** X-Nix switches every host from `origin/main` on its own.
- **Other sessions land on `main` while you work.** Branch from `origin/main`, check `git log --oneline -1 main`
  right before merging, and `git log origin/main..main` before resetting a local `main`.
- **No code comments** beyond the four kinds in [conventions](docs/conventions.md#comments).
- **The root drive is expendable.** Nothing on it, `/persistent` included, is ever backed up; state that cannot be
  rebuilt goes in the Nix config or under `/Storage`.
