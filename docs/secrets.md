# Secrets

Every secret these dotfiles need is resolved at runtime from **Proton
Pass** via `pass-cli`. Nothing encrypted, nothing committed, no second
secrets tool.

**The rule:** `pass://` *references* may live in this repo; resolved
*values* may never touch git or `/nix/store`.

The store half matters as much as the git half. Everything
home-manager writes lands in `/nix/store`, which is world-readable
`0755` — a secret placed in a `home.file` is a secret handed to every
user and process on the machine. That is why there is no
"`~/.kube/config` as a managed symlink" option, and why the helpers
below write into `$HOME` directly at `0600`.

## When resolution happens

At runtime, in your interactive shell. Never at build or activation
time:

- the Nix build sandbox has no network and no Proton Pass session;
- `darwin-rebuild` activation is non-interactive and runs partly as
  root, so `pass-cli` there hangs on a login prompt or fails outright.

So "declarative" means the **reference and the recipe** are versioned
in the repo; materialising the secret stays an explicit command you
run. This is a real limit, not a temporary one — plan around it rather
than trying to move resolution earlier.

Corollary: **never call these helpers at shell startup.** Each is a
network round trip and would add latency to every new terminal. Call
them inside the function that needs the secret, when it needs it.

## The primitives

`pass-cli` offers four ways in. Three are wrapped by
[`nix/home/secrets.nix`](../nix/home/secrets.nix); the fourth needs no
wrapper.

| Use case | Helper | Wraps |
|---|---|---|
| One value into a shell variable | `pass-get <ref>` | `pass-cli item view` |
| A whole config file | `pass-render <template> <dest>` | `pass-cli inject` |
| Precondition check | `pass-check` | `pass-cli info` |
| Env vars for a child process | *(none — use directly)* | `pass-cli run -- <cmd>` |

### `pass-get`

```zsh
key="$(pass-get 'pass://Ahold/TechNLGenAI/api_key')" || return 1
```

Fails **closed**: on any error nothing reaches stdout and the status
is non-zero, so the `|| return 1` idiom can never proceed with an
empty credential. An empty-but-successful lookup is treated as an
error too.

Fail-closed is load-bearing wherever the fallback would be worse than
stopping — in `oc-work` a missing key must abort the launch, because
continuing would route client content straight to Anthropic instead of
the sanctioned TechNL proxy.

### `pass-render`

For config files that are mostly public structure with a few secret
values in them. Write a template with `{{ pass://Vault/Item/field }}`
placeholders, commit it, and render it on demand:

```zsh
pass-render ~/.dotfiles/development/kube/homelab.yaml.tmpl \
            ~/.kube/config.d/homelab
```

The template syntax is `{{ pass://... }}`. Double angle brackets
(`<<...>>`) pass through untouched — pass-cli does not treat them as
references.

Output is always `0600`. The render goes to a temp file in the
destination directory and is renamed on success, so a failure
(expired session, renamed vault, typo'd ref) leaves an existing
working config untouched rather than truncating it.

This is the preferred shape when the file has reviewable structure:
the layout, names, and non-secret fields stay legible in git, and only
the credential blobs are absent.

### `pass-cli run`

```zsh
pass-cli run --env-file .env -- ./some-script
```

Injects secrets as environment variables into a child process and
masks them in its stdout/stderr. The masking is a good default but can
corrupt legitimate output that happens to contain a secret substring;
`--no-masking` disables it.

## Reference naming

```
pass://<Vault>/<Item>/<field>
```

Vaults and items resolve **by name**, e.g.
`pass://Ahold/TechNLGenAI/api_key`. Conventions:

- one item per system, fields for its individual values — not one
  item per value;
- lowercase `snake_case` field names (`api_key`, `proxy_url`,
  `client_cert`);
- client/work secrets in a vault named for the client; infrastructure
  in `Infra`.

**Hazard:** because refs resolve by name, renaming a vault or item in
the Proton Pass UI silently breaks every reference in this repo, with
a "Could not find vault" error at the point of use. `--share-id` is
stable but unreadable; we accept the readable form and take the
rename risk. If you rename something in Proton Pass, grep this repo
for the old name.

## Per-machine bootstrap

One manual step, and it cannot be automated away — it is the root of
trust:

```bash
pass-cli login
```

Verify with `pass-cli info`. That single login is what replaces
copy-pasting each individual secret onto each new machine.

`pass-cli` itself is declared per host as
`protonpass/tap/pass-cli` in `nix/hosts/<name>/homebrew.nix`
(the official tap; Homebrew owns updates, and pass-cli's own
`pass-cli update` is disabled under it).

Optionally lock the session at rest with `pass-cli session
create-lock`; `pass-check` reports a locked session the same way it
reports a missing one.

## Where references live today

| Consumer | Reference | Defined in |
|---|---|---|
| `oc-work` (TechNL key + proxy URL) | `pass://Ahold/TechNLGenAI/{api_key,proxy_url}` | [`nix/home/codemem.nix`](../nix/home/codemem.nix) |
| codemem work-lane observer auth | `pass://Ahold/TechNLGenAI/api_key` | [`nix/home/codemem.nix`](../nix/home/codemem.nix) |
| Per-client OpenCode lanes | `pass://<Client>/<Channel>/{api_key,proxy_url}` | [opencode-client-tooling.md](opencode-client-tooling.md) |

The codemem observer entry is a raw `observer_auth_command` array
rather than a `pass-get` call: codemem spawns that command itself and
cannot see zsh functions. Any consumer outside your shell has the same
constraint — give it the bare `pass-cli` invocation.
