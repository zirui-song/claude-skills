---
name: table
description: Regenerate a Stata table and verify it in the compiled PDF
---
Given a table number:
1. Locate the do-file that produces it in the project's script directory and run it with the
   Stata console binary — on macOS that is the lowercase `stata-se` / `stata-mp` inside the
   app bundle, e.g. `/Applications/Stata/StataSE.app/Contents/MacOS/stata-se -b do <file>`.
   Check which edition is actually installed rather than assuming MP.
   **Gotcha:** Mac batch Stata chokes on spaces in the `-b do` path. If any project directory
   has a space in its name, run through a wrapper do-file placed in a space-free directory
   whose only content is `do "<quoted absolute path>"`.
2. Check the .log for r(###) errors; stop and report if any.
3. Confirm firm-level clustering is used unless the do-file says otherwise.
4. Regenerate the .tex fragment and recompile the document that `\input`s it. Don't assume a
   `main.tex` — a project may hold several standalone root documents (the paper, a results
   appendix, a referee response), so compile the one that actually includes the fragment.
5. Report any overfull hbox for the affected page, with its pt measurement, to confirm fit.
   If latexmk/pdflatex aren't installed, `tectonic` compiles the same documents; either way
   send output to a temp directory so stray PDFs don't land in an Overleaf-synced folder.
6. Only then commit and sync to Overleaf, with a message naming the table.
