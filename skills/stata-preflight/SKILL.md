---
name: stata-preflight
description: Use before editing or running any Stata .do file in the user's research projects. Checks for missing username path branches, `cap`-suppressed esttab calls, and other recurring Stata pitfalls. Catches issues that otherwise surface only as silent failures (no log produced, lost estimates).
---

# Stata Pre-flight

Before running or finishing edits to any `.do` file, run these checks. The user's Stata username is `<your-stata-username>` (Stata base path `/Users/<your-username>/`). Check what `c(username)` actually reports on each machine — it can differ from the login name — and if you run Stata on more than one machine, path blocks need a branch for each.

## 1. Username path branches

Every do-file that sets paths needs a branch for each username:

```bash
grep -L '"<your-stata-username>"' path/to/file.do     # listed = missing this machine's branch
grep -L '"<other-machine-username>"' path/to/file.do  # listed = missing the other machine's branch
```

If a file is listed, the script will fail silently on that machine. Add the missing branch:

```stata
if "`c(username)'" == "<your-stata-username>" {
    global root "/Users/<your-username>/.../<project>"
}
if "`c(username)'" == "<other-machine-username>" {
    global root "/Users/<other-username>/.../<project>"
}
```

## 2. No `cap` around esttab

```bash
grep -nE "(^|[^a-z])cap(ture)?[[:space:]]+esttab" path/to/file.do
```

Any hit must be unwrapped. `cap esttab` silently drops in-memory estimates, producing empty tables. Same goes for `cap est store` chains that feed esttab.

## 3. Log file declared

Confirm the do-file opens a log:

```bash
grep -nE "^log using" path/to/file.do
```

If missing, add one near the top so failures leave a diagnosable trail. Follow it with
`set linesize 255` so long lines (MDE, N, long variable lists) aren't truncated in the log.

A PostToolUse hook that checks `.do` files on every edit can repeat checks 1–3; checks 4–5
are only here.

## 4. Text imports declare UTF-8

```bash
grep -n "import delimited" path/to/file.do | grep -v "encoding("
```

Add `encoding("utf-8")` to every hit. Without it Stata may pick ISO-8859-1 (the log says
"encoding automatically selected: ISO-8859-1"), and accented names (Crédit Agricole, Société
Générale) then fail string merges with no error — rows drop silently. Fix every import in a
pipeline at once so N stays consistent across tables.

## 5. esttab label text

In `labels()` / `postfoot()` strings Stata expands macros before writing the file:

- `"KP $F$-stat"` → `$F` is read as an empty global → `KP $-stat`. Write `\$F\$`.
- ``` ``Rung'' ``` → the backticks open a local-macro reference and the phrase vanishes. Use
  `\textquotedblleft Rung\textquotedblright{}`.

Both compile with no error, so grep the emitted `.tex` for the literal label text. When
patching a do-file from Python, use raw strings so `\$` and backticks survive.

## 6. After running

- Run batch Stata with the console binary (e.g. `.../StataSE.app/Contents/MacOS/stata-se -b do <file>`)
  through a wrapper do-file in a space-free directory (`do "<quoted path>"`) — batch Stata
  chokes on spaces in the `-b do` path.
- Verify `*.log` was produced and mtime is recent.
- Open the tail of the log and confirm no `r(xxx);` errors before declaring success.
- If using `esttab`, confirm the output `.tex`/`.csv` was actually written and has content.

## Reporting

Report each check as PASS/FAIL. If anything is FAIL, do not run the script — fix first.
