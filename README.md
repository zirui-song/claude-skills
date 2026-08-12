# Claude Code Skills for Empirical Research

[![Agent Skills](https://img.shields.io/badge/agent%20skills-15-blue)](skills/)
[![Skill count badge](https://github.com/zirui-song/claude-skills/actions/workflows/skill-count.yml/badge.svg)](https://github.com/zirui-song/claude-skills/actions/workflows/skill-count.yml)

A collection of custom Claude Code skills designed for empirical research in economics and finance. These skills provide structured workflows for common academic research tasks.

## Installation

To use these skills, copy the `.md` files to your Claude Code commands directory:

```bash
# Copy all skills to your Claude commands folder
cp *.md ~/.claude/commands/
```

After installation, you can invoke any skill in Claude Code using `/skill-name` (e.g., `/robustness`).

The `skills/` directory holds a second set in the newer **agent skill** format (a folder per
skill, each with a `SKILL.md` and YAML frontmatter). Those install to a different location:

```bash
# Copy the agent skills to your Claude skills folder
cp -R skills/* ~/.claude/skills/
```

Claude invokes these automatically when a task matches the skill's `description`; you can also
call one by name. See [Agent Skills](#agent-skills-skills) below.

## Available Skills

### 1. Robustness (`/robustness`)

**Purpose:** Comprehensive checklist of empirical robustness tests for finance/economics papers.

**Features:**
- Core robustness categories: alternative samples, specifications, measures
- Identification tests: placebo, pre-trends, IV diagnostics
- DiD-specific tests (parallel trends, Bacon decomposition, Callaway-Sant'Anna)
- IV-specific tests (first-stage F, weak instrument inference)
- Referee-proof minimum requirements
- Reporting templates for robustness tables

**Usage:**
```
/robustness
> "robustness checklist"     # Full checklist for current paper
> "DiD robustness"           # DiD-specific tests only
> "referee-proof"            # Most commonly requested tests
```

---

### 2. Literature Review (`/lit-review`)

**Purpose:** Systematically summarize academic papers, extract key findings, and identify research gaps.

**Features:**
- Structured paper summary template
- Data & methodology extraction
- Comparison tables across multiple papers
- Literature gap analysis framework
- BibTeX generation

**Usage:**
```
/lit-review
> "summarize this paper"     # Full template
> "quick summary"            # Citation, question, finding, relevance
> "compare papers"           # Comparison table
> "find gaps"                # Identify research gaps
```

---

### 3. Coding Guidelines (`/coding-guidelines`)

**Purpose:** Standardized Python & Stata coding practices for empirical research projects.

**Features:**
- Project directory organization
- Python script templates with path management
- Stata script templates with global macros
- Data loading, merging, and validation patterns
- Visualization standards (matplotlib/seaborn)
- Output table conventions (outreg2/esttab)
- Variable naming conventions
- Common pitfalls and best practices

**Key Patterns:**
```python
# Python path management
def get_project_root():
    return Path(__file__).parent.absolute()
```

```stata
* Stata path setup
global repodir "/path/to/project"
global datadir "$repodir/Data"
global cleandir "$datadir/Clean"
```

---

### 4. Data Documentation (`/data-doc`)

**Purpose:** Document datasets, variables, sources, and merge keys for replication packages.

**Features:**
- Dataset overview template
- Source data tracking
- Variable documentation tables
- Variable construction documentation
- Sample filter tracking with observation counts
- Merge key documentation with match rates
- Codebook format for replication packages

**Usage:**
```
/data-doc
> "document this dataset"    # Generate full template
> "variable list"            # Create variable table
> "merge documentation"      # Focus on merge keys
> "sample flow"              # Sample filter table
> "codebook"                 # Formal codebook format
```

---

### 5. Project Structure (`/project-structure`)

**Purpose:** Project directory organization and script naming conventions for research.

**Features:**
- Standard directory structure (Code/, Data/, Results/)
- Script numbering conventions:
  - `0_`: Initial data extraction
  - `1a_, 1b_`: Data cleaning
  - `2_`: Data merging
  - `AN_1_, AN_2_`: Analysis scripts
- Data organization principles (Raw/, Intermediate/, Clean/)
- Logging and output management
- Version control best practices

**Example Structure:**
```
Project/
├── Code/
│   ├── 0_ExtractData.py
│   ├── 1a_CleanDatasetA.py
│   ├── 2_MergeDatasets.py
│   ├── AN_1_Descriptives.py
│   ├── AN_2_MainRegressions.do
│   └── LogFiles/
├── Data/
│   ├── Raw/
│   ├── Intermediate/
│   └── Clean/
└── Results/
    ├── Tables/
    └── Figures/
```

---

### 6. Referee Response (`/referee-response`)

**Purpose:** Structure responses to referee reports for R&R submissions.

**Features:**
- Response document structure template
- Point-by-point response templates
- Response strategies by comment type:
  - Data/sample questions
  - Identification concerns
  - Additional analysis requests
  - Clarification requests
  - Respectful disagreement
- Change tracking summary
- Common phrases and tone guidelines
- Pre-submission checklist

**Usage:**
```
/referee-response
> "format referee response"   # Set up document structure
> "respond to this comment"   # Draft specific response
> "disagreement response"     # Phrase respectful disagreement
> "summarize changes"         # Generate changes summary
```

---

## Agent Skills (`skills/`)

Fifteen skills in the agent-skill format, aimed at the run-it-and-verify-it half of empirical
work: executing pipelines, checking that reported numbers match the logs that produced them,
and stress-testing a design before a referee does.

### Empirical pipeline

| Skill | Purpose |
|-------|---------|
| `table` | Regenerate one Stata table, check the log for `r(###)`, recompile, confirm page fit, then commit |
| `refresh-pipeline` | Pre-flight, run, and verify a multi-stage Stata + Python pipeline |
| `stata-preflight` | Catch the silent Stata failures: missing username path branch, `cap`-suppressed `esttab` |
| `robustness-battery` | Referee-anticipating sweep across estimator, sample, controls, weights, clustering — plus a one-pass fixed-grid mode |
| `spec-curve-sweep` | 200–500 specification sweep with a resumable runner, spec curve, and drafted online appendix |
| `power-first` | First-stage F, effective N, MDE at 80% power, and the top two identification threats — reported *before* any coefficient is interpreted |

### Verification

| Skill | Purpose |
|-------|---------|
| `verify-claims` | Adversarial pass over a draft: every number and citation gets an exact `file:line` or is marked `UNVERIFIED` |
| `verify-numbers-pipeline` | Make every number machine-checkable — YAML claim manifest, `verify_numbers.py`, `make verify`, pre-commit hook that blocks stale numbers |
| `referee-panel` | Five parallel adversarial reviewers (identification, power, literature, provenance, independent replication) → one ranked threat memo |

### LaTeX / Overleaf

| Skill | Purpose |
|-------|---------|
| `sync-overleaf` | Push updated tables/figures to an Overleaf folder; pull and diff before editing any `.tex`, then verify the compile |
| `overleaf` | Refresh local `.tex`/`.bib` against Overleaf so the agent never edits a stale copy |

### Cross-model review

| Skill | Purpose |
|-------|---------|
| `codex-review-plan` | Send a plan to Codex for a second opinion against the real codebase |
| `review-codex-plan` | The reverse — critically review a Codex-authored plan |
| `plan-debate` | Multi-round Claude ↔ Codex debate converging on a stronger plan |
| `codex-bridge` | Shared mechanics for the three above (not invoked directly) |

Paths, usernames, and example coefficients in these files are placeholders — swap in your own.

## Quick Reference

| Skill | Invoke | Best For |
|-------|--------|----------|
| Robustness | `/robustness` | Planning robustness tests before/after analysis |
| Lit Review | `/lit-review` | Summarizing papers, building literature review |
| Coding Guidelines | `/coding-guidelines` | Writing clean, reproducible code |
| Data Doc | `/data-doc` | Creating documentation for replication |
| Project Structure | `/project-structure` | Setting up new research projects |
| Referee Response | `/referee-response` | Responding to R&R reports |

## Workflow Integration

These skills are designed to work together throughout the research lifecycle:

1. **Project Setup:** Use `/project-structure` to organize your directories
2. **Coding:** Follow `/coding-guidelines` for Python and Stata scripts
3. **Documentation:** Use `/data-doc` to document datasets as you build them
4. **Literature:** Use `/lit-review` to systematically review related papers
5. **Analysis:** Use `/robustness` to plan comprehensive robustness tests
6. **Revision:** Use `/referee-response` to structure your R&R responses

## Customization

Each skill is a markdown file with a YAML frontmatter containing the description. You can customize any skill by editing the corresponding `.md` file in `~/.claude/commands/`.

```yaml
---
description: Your skill description here
---
```

## License

MIT License - Feel free to use, modify, and share these skills.

## Contributing

Suggestions and improvements welcome! Feel free to open issues or pull requests.
