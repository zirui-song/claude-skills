---
name: sync-overleaf
description: Use after producing or updating empirical tables/figures that belong in a paper. Copies updated artifacts from the project's results/ directory to the corresponding Overleaf-synced folder, preserving filenames, and reports what changed so the LaTeX draft picks them up on next compile.
---

# Sync Overleaf

Standard post-step to push updated tables/figures into an Overleaf-synced folder.

## Inputs (infer if obvious, otherwise ask)

- Source directory in the project (typically `results/tables/` and `results/figures/`).
- Destination Overleaf folder (typically under `~/Dropbox (MIT)/Apps/Overleaf/<paper>/` — confirm location; project folders may live in separate unsynced Dropbox roots).

## Steps

1. **Confirm destination exists and is synced** — `ls -la <dest>` and check files are real (not Dropbox placeholders).
2. **Diff** — for each source file, compare to the existing destination file:
   ```bash
   diff -q source dest
   ```
   Build a list of: NEW, CHANGED, UNCHANGED.
3. **Copy** only NEW + CHANGED files. Preserve filenames exactly so `\input{}` / `\includegraphics{}` calls don't need editing.
4. **Report** — list NEW and CHANGED file paths and their sizes. ≤ 10 lines.

## Editing .tex files (not just copying artifacts)

The user edits in the Overleaf web editor while Claude edits locally. Treat this as a
**two-way sync, never a one-way push**.

1. **Pull first.** Invoke the `overleaf` skill (or run `overleaf-sync-now sync`) to refresh
   the local copy before touching any `.tex`/`.bib`.
2. **Diff before writing.** Show the user a diff of the pulled Overleaf version against the
   local copy. If they differ, **stop and ask which to keep.** Do not merge on your own.
3. **Targeted edits only.** Never regenerate or overwrite a whole `.tex` file when an Edit
   on the specific block will do. Regenerating clobbers the user's web-editor prose — this
   has already cost recovery from Overleaf version history.

## Verify the compile before reporting done

After ANY table or figure edit:

- Recompile the document.
- Look at the affected page — page-fit, header layout, rendering — don't infer it from a
  clean exit code.
- Report the actual measurement (e.g., `Overfull \hbox (83.0pt too wide) at line 412`).
  Never say a fit is "fixed" without a compile that shows it.

## Conventions

- Never delete files in the Overleaf folder — only add/overwrite.
- If a filename collision exists but content differs intentionally (e.g., anonymized version), confirm with the user before overwriting.
- After copy, suggest the user trigger a fresh Overleaf compile.

## Anti-patterns

- Do not paste table content into chat — only path + size.
- Do not assume the Overleaf folder structure; confirm first if not previously used in this session.
