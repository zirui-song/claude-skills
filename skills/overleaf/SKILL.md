---
name: overleaf
description: "Refresh local .tex/.bib files against Overleaf before AI edits, so the agent never edits a stale copy (default Overleaf-to-Dropbox sync lags 10-20 min). Refresh path: probe `/project/<id>/updates` (read-only), skip if nothing changed, skip if all changes were our own Dropbox round-trips, else download-zip and extract only the web-origin changed files. WHEN: (1) before editing .tex/.bib/.cls/.sty/.bst under Apps/Overleaf/<project>/ run `overleaf-sync-now sync`; (2) on user request to refresh; (3) for first-time auth run `overleaf-sync-now login`. Claude Code: a PreToolUse hook auto-runs sync; manual invocation rarely needed. Codex CLI: invoke sync explicitly. AUTH RECOVERY when sync/setup fails: run `overleaf-sync-now login` (browser-assisted, works on Chrome 130+). Do NOT tell the user to 'log into Overleaf' in their daily browser — on Chrome 130+ app-bound encryption blocks on-disk cookie extraction regardless of login state. See body for full recovery flow."
argument-hint: "setup | sync [folder] [--force] | status [folder] | link <project_id> [folder] | install | save-cookie <value> | doctor"
user-invocable: true
---

# overleaf-sync-now

## ⚠ STOP — read this before suggesting "log in to Overleaf"

If the user is on Windows with Chrome 130 or later, **logging into Overleaf in their daily browser will NOT fix auth failures.** Chrome 130 added App-Bound Encryption: the cookie database AES key is wrapped a second time with a key bound to `Chrome.exe` itself, brokered through Windows COM. Any process that isn't Chrome.exe (and isn't running as admin) can read the encrypted bytes but can't decrypt them. So `browser_cookie3` and `rookiepy` fail regardless of how recently the user logged in.

**The proper fix is `overleaf-sync-now login`.** It launches a controlled browser (patchright-managed Chromium since 0.3.2; vanilla Playwright fallback), the user logs in there once, and we read the cookie via Chrome DevTools Protocol — which returns plaintext because the request comes from inside the browser. The login persists in our profile for weeks.

## The problem

Overleaf's Dropbox bridge polls in one direction (Overleaf → Dropbox) every 10–20 minutes, so a local Dropbox-mirrored `.tex` file can be stale by that long. This skill fixes it by probing Overleaf's version history (`GET /project/{id}/updates`) and, on an actual web-origin change, downloading the project zip (`GET /project/{id}/download/zip`) and extracting only the files that changed — without changing the user's existing Dropbox-bridge setup, so cross-device Dropbox sync still works as before.

## How project lookup works

- **Auto-link** (zero-config, preferred): if a file lives under any `…/Apps/Overleaf/<project-name>/`, the skill looks up `<project-name>` in the user's Overleaf project list (cached 24 h, projects.json v2 since 0.3.0). The cached list keeps `trashed`/`archived`/`lastUpdated`/`ownerId`, so the resolver filters out trashed and archived projects by default and refuses to guess when two living projects share a name.
- **Marker auto-write** (since 0.3.0): on a successful auto-link the resolver writes a tiny `.overleaf-project` JSON marker into the project folder so future resolution skips the index lookup entirely. The marker carries `project_id` + provenance (`source`, `linked_at`, `name_at_link_time`).
- **Manual link** (override): if the user has two living projects with the same name (or the local folder name doesn't match), the resolver refuses to guess and prints all candidates with the exact `overleaf-sync-now link <id> <folder>` command to copy-paste. Run that command to write the marker explicitly. Old marker files containing only `{"project_id": "..."}` keep working.

### When `sync` warns or refuses

- **`auto-link: N non-trashed Overleaf projects named <name>. Refusing to guess.`** — Two or more live projects share the folder name. The skill lists candidates with IDs, last-updated timestamps, and any archived flag. Tell the user to pick one and run the printed `link` command. *Do NOT pick a project ID for them.*
- **`WARN: marker at <folder> -> <id> is trashed/archived on Overleaf`** — User explicitly linked a stale project. Sync proceeds but the user probably wants `overleaf-sync-now link <other_id> <folder>` to relink to the active project.
- **`WARN: project <id> has recent Dropbox-origin updates touching files not present in <folder>`** — Strong signal the link points at the wrong project entirely (a typo'd manual link, a fork, or a same-name duplicate that earlier defenses didn't catch). Have the user run `overleaf-sync-now status` and `overleaf-sync-now projects` to verify, then `link` to fix.

## Auth — DO NOT ask the user which method to use

The script handles auth itself. It tries (in this exact order, automatically): cached cookies → persistent `login` browser profile → `rookiepy` (Chrome 127+ friendly) → `browser_cookie3` → Claude Code's Playwright MCP profile → manual paste prompt.

**Just run `overleaf-sync-now setup` (or `install`).** Do not ask the user "do you want auto-detect or manual paste?" — the script picks the best available source.

## When auth fails (the recovery flow you should use)

When `setup` reports "AUTO-DETECT FAILED" or `sync` returns a "No valid Overleaf cookies" error, **the proper recovery is `overleaf-sync-now login`** (browser-assisted, works on every platform including Chrome 130+ Windows). Don't suggest the user "log in" in their daily browser — on Chrome 130+ Windows that doesn't help.

**Recovery flow:**

1. Run `overleaf-sync-now doctor` to confirm which automatic sources failed.
2. Tell the user: *"Run `overleaf-sync-now login` in your terminal. A browser window will open. Log into Overleaf there. We'll capture the cookie via the browser's API."*
3. (On first run, this auto-installs Playwright + Chromium, ~150MB, one-time.) The browser opens to overleaf.com, the user logs in, and the script captures the cookie via Chrome DevTools Protocol (no on-disk decryption needed). The login persists in the profile.
4. After they confirm login finished, run `overleaf-sync-now status` to verify, then retry the original sync.

**Fallback for environments where `login` can't run** (no display, server, etc.): `save-cookie <value>`. Ask the user to copy their `overleaf_session2` value from F12 → Application → Cookies → overleaf.com, then run `overleaf-sync-now save-cookie "<value>"`. Don't rely on this when `login` is available — `login` is more reliable.

### If Google blocks the `login` browser ("This browser or app may not be secure")

If the user signs into Overleaf via **"Sign in with Google"** and the managed `login` browser hits Google's *"This browser or app may not be secure"* page, that's Google's anti-automation gate (`disallowed_useragent`). The `login` command since 0.3.2 detects this and prints a tailored recovery message. The supported escape hatch is to give the user's Overleaf account an email+password alternate login:

1. Open https://www.overleaf.com/user/password/reset in any normal browser.
2. Enter the Overleaf account email; Overleaf emails a password-set link.
3. Set a password (their Google sign-in still works elsewhere; this just adds email+password).
4. Re-run `overleaf-sync-now login` and use **email+password** in the Overleaf form. Google never sees this flow.

Or fall back to `save-cookie` paste. **Do not** suggest fighting Google's detection further — patchright already does the best-available stealth, and Google iterates against bypasses.

## Subcommands

The CLI is `overleaf-sync-now` (installed globally via `uv tool install`).

### `setup`
Auth wizard. Walks the auto-detect chain; in interactive mode also prompts for manual paste. Run once; cached for weeks afterward.

### `login`
Browser-assisted login (Playwright + Chromium). The proper fix when `setup` can't auto-detect — including the Chrome 130+ app-bound encryption case on Windows. See the recovery flow above.

### `save-cookie <value>`
Last-resort: persist an `overleaf_session2` cookie value pasted from the browser's F12 → Application → Cookies pane. Use only when `login` can't run (no display / CI / server).

### `sync [folder] [--force]`
Refresh the project that owns `folder` (or current dir) against Overleaf.

- Probes `/project/<id>/updates`; skips if no change or if all new updates are Dropbox-origin round-trips of our own saves; otherwise downloads the zip and extracts only the files whose web-origin updates aren't yet on local.
- `--force`: always download the zip and re-extract. Hash-compare still skips files whose bytes already match local. Also disables the 30-second recent-mtime guard (see below).

Data-safety: by default, `sync` refuses to overwrite a local file modified within the last 30 seconds, and prints `SKIP <path>` to stderr. This protects an in-progress local save that hasn't yet propagated Dropbox → Overleaf. When a protected file *also* had a web-origin change in the pulled zip, `sync` does **not** advance the cached version — it reports `version held at <toV>` and re-offers that web change on the next sync (once the local file ages out of the 30 s window), so the web edit is never silently dropped. Pass `--force` to overwrite local with the Overleaf copy immediately.

When to invoke: manually when the user says "pull latest from Overleaf," or automatically before editing in Codex CLI (PreToolUse hooks aren't reliable on Windows in Codex).

### `status [folder]`
Reports data dir, cookie validity, linked project, last-sync time, and cached Overleaf version (`toV`). Distinguishes sandbox-blocked network from real auth failures.

### `projects [--refresh]`
List the user's Overleaf projects (name + ID). `--refresh` forces re-fetch of the index.

### `doctor [folder]`
Diagnostic dump: cookie cache state, per-browser cookie extraction, Playwright profile, auth-chain resolution, and a live `/updates` probe against the given folder's linked project.

### `link <project_id> [folder]`
Writes a `.overleaf-project` marker. Only needed for non-standard folder layouts (i.e., not `Apps/Overleaf/<name>/`).

### `hook`
PreToolUse hook entrypoint for Claude Code. Reads JSON from stdin. **Not for manual use.**

### `install`
Idempotent post-install setup: copies `SKILL.md` into `~/.claude/skills/overleaf/` and `~/.codex/skills/overleaf/` (whichever exists), installs / updates the Claude Code PreToolUse hook (matcher `Read|Edit|Write|MultiEdit`), runs the auth chain. Re-run after upgrading.

### `uninstall`
Removes skill installs and the hook. Cookies are preserved.

## Sandbox notes (Codex CLI, restricted shells)

If any network-using subcommand (`sync`, `status`, `login`, `doctor`, `setup`) fails with a socket-permission error — **Windows** `WinError 10013` / `forbidden by its access permissions`, **POSIX** `EACCES` / `EPERM` / "Permission denied" — the host shell is blocking the outbound HTTPS call. **This is not an auth problem.**

The tool detects this case specifically and prints:

> Outbound HTTPS to Overleaf was blocked by the host environment (likely a sandboxed shell — Codex CLI, some CI runners). Auth is probably fine; running setup/login/doctor will fail the same way. Approve the `overleaf-sync-now` command prefix in your sandbox policy, or re-run outside the sandbox.

When you see that message (or any of the above errno markers):
- Do **not** run `setup` / `login` / `doctor` — each hits the same blocked socket.
- Tell the user to approve the `overleaf-sync-now` command prefix in their sandbox (Codex CLI's always-approve list), or re-run from an unsandboxed shell.
- `status` will print `Cookie auth: UNKNOWN — outbound HTTPS is blocked ...` rather than `INVALID` in this case, so you don't have to guess.

## When to invoke this skill

- **In Claude Code**: rarely — the hook handles editing automatically. Invoke `sync` only on explicit user request, or `setup`/`link` for first-time configuration.
- **In Codex CLI on Windows**: every time you're about to Edit/Write a `.tex`/`.bib`/`.cls`/`.sty`/`.bst` file under `Apps/Overleaf/`, invoke `sync` first. (Codex hooks don't reliably fire pre-Edit on Windows.)
- **User mentions stale Overleaf content**: invoke `sync`.
- **User asks to set up Overleaf sync**: invoke `setup` (or full `install` if not yet linked into Claude/Codex skill dirs).

## Failure modes & recovery

- **`No valid Overleaf cookies (cache: <path>)`**: cookies expired or never set. **In the Claude Code hook this now BLOCKS the edit (exit 2)** so the AI re-auths instead of editing a possibly-stale copy. Recovery: run `overleaf-sync-now doctor` to confirm which sources failed, then `overleaf-sync-now login` (browser-assisted; works on Chrome 130+ Windows). Fallback: `overleaf-sync-now save-cookie "<value>"`. Do **not** rely on `setup` here — in non-interactive/agent context it only retries auto-detect and returns `AUTO-DETECT FAILED` without capturing a cookie.
- **`setup` can't find browser cookies**: user may not be logged into overleaf.com in Chrome/Edge/Firefox. Use `overleaf-sync-now login` (the reliable path), or paste a cookie via `save-cookie`.
- **Auto-link can't find the project**: folder name doesn't match Overleaf project name. Use `link <project_id> .` inside the folder.

## Security note

Cached cookies grant full access to the user's Overleaf account. Two sensitive stores live under the data dir (`~/.overleaf-sync/` by default; legacy `~/.claude/overleaf-data/`):

- `cookies.json` — the cached session, written `0600` on POSIX (user-only).
- `browser-profile/` — created by `overleaf-sync-now login`; holds a **live, weeks-long Overleaf session** that grants the same full account access.

Since 0.4.0 the data dir itself is `0700` on POSIX so neither is reachable by other local users. To scrub credentials (sharing a home dir, decommissioning a machine, after a suspected compromise), delete the **whole** data dir, not just `cookies.json`. Don't commit, don't share. (On Windows, ACL inheritance from the parent directory is the relevant control.)
