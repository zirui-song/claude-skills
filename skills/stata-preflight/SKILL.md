---
name: stata-preflight
description: Use before editing or running any Stata .do file in the user's research projects. Checks for missing `<your-stata-username>` username path branches, `cap`-suppressed esttab calls, and other recurring Stata pitfalls. Catches issues that otherwise surface only as silent failures (no log produced, lost estimates).
---

# Stata Pre-flight

Before running or finishing edits to any `.do` file, run these checks. The user's Stata username is `<your-stata-username>` (Stata base path `/Users/<your-username>/`).

## 1. Username path branch

Every do-file needs a `<your-stata-username>` branch in its path-setting block:

```bash
grep -L "<your-stata-username>" path/to/file.do
```

If the file is listed (no match), the path block is missing the user's branch and the script will fail silently on this machine. Add a branch like:

```stata
if "`c(username)'" == "<your-stata-username>" {
    global root "/Users/<your-username>/.../<project>"
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

If missing, add one near the top so failures leave a diagnosable trail.

## 4. After running

- Verify `*.log` was produced and mtime is recent.
- Open the tail of the log and confirm no `r(xxx);` errors before declaring success.
- If using `esttab`, confirm the output `.tex`/`.csv` was actually written and has content.

## Reporting

Report each check as PASS/FAIL. If anything is FAIL, do not run the script — fix first.
