# TwilightCoders Homebrew Tap

Homebrew formulae for [TwilightCoders](https://github.com/TwilightCoders) projects.

```sh
brew tap twilightcoders/tap
```

## Formulae

### `progresql`

A PostgreSQL 18 fork that adds **spanning indexes** — true cross-partition
`PRIMARY KEY` / `UNIQUE` enforcement on partitioned tables via the `GLOBAL`
keyword, without forcing the partition key into the constraint.
See [TwilightCoders/progresql](https://github.com/TwilightCoders/progresql).

```sh
brew install twilightcoders/tap/progresql          # latest tagged beta
brew install --HEAD twilightcoders/tap/progresql   # build from master
```

> ⚠️ **Beta.** This is a research fork. The formula is **keg-only** so it never
> shadows a real PostgreSQL install (or a `pg_cluster`/petere setup): its
> binaries are not symlinked into the Homebrew prefix. Use them via the keg path,
> e.g. add to `PATH` deliberately:
>
> ```sh
> export PATH="$(brew --prefix progresql)/bin:$PATH"
> ```
>
> Keep backups and validate against your workload before trusting production data
> to it — see the upstream README for the current trust/testing status.

Building from source compiles all of PostgreSQL (~10–15 min) plus the `amcheck`
contrib module (used to verify spanning indexes).
