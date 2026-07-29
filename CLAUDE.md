# CLAUDE.md

Docker-based GitHub Action that downloads the Prequel CLI and runs `prequel ... model apply` against a directory of model configs.

Part of the Prequel workspace at `~/prequel/`. See `~/prequel/CLAUDE.md` for cross-repo context. The CLI binary this action installs is built by the `datafeed` repo and served from GCS, so behavior changes can originate there rather than here.

## Gotchas

- **The `v1` tag predates the base-image fix.** `v1` still builds `FROM debian:bookworm-slim`. The ubuntu base is only on `v1.0.1` and `main`. The README's example usage says `@v1`, so anyone copying it gets the pre-fix image. Verify with `git show v1:Dockerfile` before assuming a consumer is on current code.
- **`ubuntu:24.04` is a requirement, not a default.** The Prequel CLI binary needs glibc 2.38+, which is why the base image moved off debian. The Dockerfile records this in a comment. Do not switch to debian, alpine, or an older ubuntu.
- **Inputs are positional, and the coupling is silent.** `action.yml` passes five `args` in order to `entrypoint.sh` as `$1..$5`: `use_dev_cli`, `host`, `api_key`, `mode`, `dir`. Reordering the `args` list or inserting an input shifts every downstream argument with no error, just a wrong command.
- **`api_key` is `$3` and lands on a command line.** It is passed as `--api_key="$3"` to `prequel`. Never add `set -x` to `entrypoint.sh` or echo the arguments, since that would print a live API key into Actions logs.
- **The installer is fetched over HTTPS, not `gs://`.** `entrypoint.sh` runs `wget` against `https://storage.googleapis.com/prequel_binaries/install.sh` (when `use_dev_cli` is `true`) or `https://storage.googleapis.com/prequel_cli_binaries/install.sh`. The buckets are public over HTTPS, so reaching for `gsutil` or credentials is the wrong path.
- **Nothing validates changes automatically.** There is no `.github/` directory and no test suite. A broken Dockerfile or entrypoint is only caught by building locally or by pointing a real workflow at your branch.
- **`import` vs `export` semantics live in `datafeed`.** The `mode` flag is handed straight to the CLI (`backend/cmd/prequel/`); nothing in this repo defines what the modes do. Do not infer their meaning from this repo alone.
- **`action.yml`'s `description` is leftover template text** ("Greet someone and record the time"). It is inaccurate in both this repo and `apply-product-configs`. Ignore it; it is not a clue about behavior.

## Divergence from apply-product-configs

The two repos are near-identical and are a copy-paste hazard in both directions. Everything below must stay model-flavored:

| | this repo | apply-product-configs |
|---|---|---|
| CLI subcommand | `model apply` | `product apply` |
| default `dir` | `prequel/models/*` | `prequel/products/*` |
| branding color | green | blue |

## Testing

```bash
docker build -t apply-model-configs .
docker run apply-model-configs false https://api.prequel.co/ <api_key> export 'prequel/models/*'
```

Quote the glob. `entrypoint.sh` passes `"$5"` through to the CLI, which does its own expansion, so an unquoted `prequel/models/*` is expanded by your shell first and the container receives the wrong arguments.

In a real workflow, reference the branch directly: `uses: prequel-co/apply-model-configs@your-branch-name`.
