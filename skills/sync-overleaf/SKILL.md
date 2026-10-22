---
name: sync-overleaf
description: Use after producing or updating empirical tables/figures that belong in a paper, and before writing any file in an Overleaf-synced folder. Gets artifacts into the Overleaf folder (or confirms the producers already wrote them there), protects the user's web-editor edits, catches Dropbox conflicted copies, and verifies the compile.
---

# Sync Overleaf

Overleaf folders live under `~/Dropbox/Apps/Overleaf/<paper>/` (or your Dropbox root's
equivalent) — confirm the folder before writing; project folders may sit in a different Dropbox root. Overleaf ↔ Dropbox
is a two-way bridge, and the user edits in the Overleaf web editor between turns.

## 1. Before ANY write under `Apps/Overleaf/`

- Run `overleaf-sync-now sync <folder>` first. The PreToolUse hook only fires on
  Read/Edit/Write; Bash `cp`/`rsync` and Python rewrites bypass it.
- Edit the Overleaf-folder copy in place. Never keep a separate "master" copy and `cp` it
  over — that has clobbered the user's web edits before.
- If the user says they are revising a file by hand, leave it alone until they say otherwise.
  Re-read a file right before editing so you never overwrite edits they just made.
- Keep Overleaf comment anchors and coauthors' comments intact when editing nearby text.
- `.bib` files come from Zotero. Never edit them directly; tell the user what to add in Zotero.

## 2. Getting tables and figures in

Find out which case the project uses:

- **Producers write straight into the Overleaf folder** (esttab or a generator writes both the
  project's `tables/` and Overleaf's `Tables/`). Don't copy — verify:
  ```bash
  for f in tables/*.tex; do cmp -s "$f" "$OL/Tables/$(basename "$f")" || echo "DIFFERS $f"; done
  ```
- **Copy mode** (artifacts exist only in the project): `diff -q` each source against the
  destination and list NEW / CHANGED / UNCHANGED. Run `overleaf-sync-now sync`, then copy only
  NEW + CHANGED, preserving filenames so `\input{}` / `\includegraphics{}` calls don't change.

Never delete files in the Overleaf folder — only add or overwrite. If a filename collides but
the content differs on purpose (e.g. an anonymized version), ask before overwriting.

## 3. After writing — confirm it actually landed

Dropbox can silently demote a just-written file to `<name> (… conflicted copy <date>).tex`
and restore Overleaf's older content as the live file, keeping the old mtime. A compile right after the write proves nothing.

1. Save a copy of each edited file outside Dropbox (scratchpad) before anything else.
2. Don't run `overleaf-sync-now sync` in a loop right after writing — that invites the
   round-trip race. A `dropbox_echo` result doesn't mean the edit reached Overleaf.
3. A minute or two later, re-read the file and check the change is still there. Run
   `find "$OL" -name "*conflicted copy*"` before concluding anything is lost.
4. To confirm real sync, download `https://www.overleaf.com/project/<id>/download/zip` with the
   `overleaf_session2` cookie from `~/.overleaf-sync/cookies.json` and `shasum` the file
   against local.
5. If Overleaf still doesn't show the change after ~20 minutes (the bridge has stalled for
   hours before), say so and tell the user. Don't keep rewriting the file.

## 4. Editing .tex files

- **Diff before writing.** If the pulled Overleaf version differs from the local copy, show
  the diff and ask which to keep. Do not merge on your own.
- **Targeted edits only.** Never regenerate or overwrite a whole `.tex` file when an Edit on
  the specific block will do — regenerating clobbers the user's web-editor prose.
- If an Edit fails because the file changed underneath (the sync hook updated it mid-edit),
  re-read and redo the edit. Don't fall back to rewriting the file.

## 5. Verify the compile before reporting done

After any table or figure edit, recompile the root that `\input`s it (see the `table` skill:
`tectonic -Z continue-on-errors --keep-logs -o "$TMP" <root>.tex`). Check the affected page —
fit, float placement, header layout — and report the actual measurement (e.g.
`Overfull \hbox (83.0pt too wide) at line 412`). Never say a fit is "fixed" without a compile
that shows it. Render the page with `pdftoppm` and show the PNG so the user can check it without
opening the PDF.

## Reporting

List NEW and CHANGED paths with sizes (≤ 10 lines). When the user asks to see a table, show
it — the table itself or the rendered page.
