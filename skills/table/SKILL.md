---
name: table
description: Regenerate a Stata table and verify it in the compiled PDF — run its producer, check the log, recompile the root that inputs it, check fit and float placement, show the page, then commit. Also covers the table-by-table review loop ("move onto Table N").
---
Given a table number:

1. **Find the producer.** Check the project's own map first: an exhibit map (e.g. `EXHIBIT_MAP.md`),
   a generator script that stages and writes tables, or a `Replication/` folder. If tables reach Overleaf through a generator, run the
   generator rather than the raw do-file, and respect its guards (e.g. an md5 check on the
   last-written file). Re-run any variant producers that share the table (suffix variants such
   as `_imp`).
2. **Run it** with the Stata console binary (run the `stata-preflight` checks first):
   on macOS that is the lowercase `stata-se` / `stata-mp` inside the app bundle, e.g.
   `/Applications/Stata/StataSE.app/Contents/MacOS/stata-se -b do <file>`. Check which edition
   is actually installed rather than assuming MP. Mac batch Stata chokes on spaces in the
   `-b do` path, so if any project directory has a space in its name, run it
   through a wrapper do-file in a space-free directory containing `do "<quoted path>"` (add a
   `cd "<dir>"` line first if the do-file uses relative paths).
3. **Check the .log** for r(###) errors and confirm its mtime is new; stop and report if not.
4. **Clustering:** keep what the do-file and the project's CLAUDE.md/memory specify. Project
   defaults override a global firm-level default (e.g. two-way firm + officer). Don't change it.
5. **House style:** read the project's CLAUDE.md/memory first. Common defaults:
   - Name the dependent variable in the table itself (a spanning "Dep. var.:" header, or a row
     when columns differ) — `mlabels(, depvars)` or a `posthead` line in esttab.
   - Notes describe construction only (data, sample, spec, FE, clustering, significance
     legend) and start "This table shows"; never describe or interpret results.
   - A column-number row; no N-firms rows unless asked.
   - Panels follow the paper's own layout. Some papers use one tabular per panel with
     `\hline\hline` and a centred italic title above each — that overrides the global
     booktabs rule for that paper.
   - esttab label gotcha: `$F$` and backtick quotes vanish from `labels()`/`postfoot()` with
     no error. Grep the emitted `.tex` for the literal label text.
6. **Recompile the document that `\input`s the fragment.** Don't assume a `main.tex` — a
   project may hold several standalone roots (the paper, a results appendix, a referee
   response), so compile the one that actually includes the fragment. Use `tectonic` (or
   latexmk if installed) with output in a temp dir so no PDFs land in the Overleaf-synced folder:
   ```bash
   tectonic -Z continue-on-errors --keep-logs -o "$TMP" <root>.tex
   ```
   Full drafts often carry LaTeX errors Overleaf ignores (e.g. `float` and `floatrow` both
   loaded, a `subfigure` clash), so plain `tectonic` halts on them. Compile a scratch copy of
   the Overleaf folder and compare the error count (`grep -c '^!' "$TMP/<root>.log"`) with the
   draft's known baseline — only new errors matter. Never comment out a package to get a compile; it silently changes float and
   caption behaviour.
7. **Check fit and placement** for the affected page, and report actual measurements:
   - `Overfull \hbox` lines with their pt values.
   - `Float too large` warnings, and floats pushed to the end of the document.
   - Which page the table landed on: `pdftotext -layout "$TMP/<root>.pdf" -` and grep for the
     caption; `pdfinfo` for the page count.
   Then render that page and show the PNG, so the user can see it without opening the PDF:
   ```bash
   pdftoppm -f N -l N -r 110 -png "$TMP/<root>.pdf" "$TMP/table_p"
   ```
8. **Only then commit**, with a message naming the table, following the project's repo layout
   (some projects push only the code repo; logs and results stay local). Then sync to Overleaf
   (`sync-overleaf`).

## Review loop ("move onto Table N")

When the user reviews exhibits one at a time: show the table as a PNG, list numbered proposed
fixes, and wait for the user to pick ("do 1, 2 and 4"). Apply only those, re-render, and show
it again. Don't carry a fix over to other tables unless asked.
