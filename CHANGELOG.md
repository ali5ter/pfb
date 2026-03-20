# Changelog

All notable changes to pfb are documented here.

## [2.0.0] — 2026-03-20

### Summary

A comprehensive UX overhaul based on a detailed audit comparing pfb against modern
CLI tools (gum, Clack, Ora). 15 issues were addressed across safety, correctness,
and ergonomics. The result is a library that works safely in CI, pipelines, and
`set -e` scripts with no behavior changes for non-interactive output.

### Breaking Changes

#### `pfb select` now returns the selected index via stdout

**Before:**

```bash
pfb select "${options[@]}"
selected=$?   # exit code carried the index
```

**After:**

```bash
selected=$(pfb select "${options[@]}")
```

**Why:** Exit codes are 8-bit (0–255), making lists of 256+ items silently wrap.
More critically, any non-zero selection caused `set -e` scripts to abort.
The stdout convention matches `pfb input` and modern tools (gum, fzf).

**Migration:** Replace `pfb select ...; idx=$?` with `idx=$(pfb select ...)`.
The `pfb select-from` alias preserves the old exit-code behavior during transition.

#### `pfb success` now displays `[success]` instead of `[done]`

The visible label now matches the command name. Scripts that parse pfb output
for the string `[done]` will need to update to `[success]`.

### New Features

- **CI/non-interactive mode:** Set `PFB_NON_INTERACTIVE=1` to have `pfb confirm`,
  `pfb select`, and `pfb input` return their defaults without prompting. Non-TTY
  stdin is also detected automatically. (#UX-003)

- **Configurable confirm default:** `pfb confirm "Delete?" no` now defaults to No.
  Useful for destructive operations. (#UX-014)

  ```bash
  pfb confirm "Remove all containers?" no
  pfb confirm "Continue?" yes   # explicit yes (same as before)
  ```

- **Elapsed time in spinner:** Operations running longer than 3 seconds now show
  a live elapsed time counter alongside the spinner. (#UX-008)

- **`--no-color` per-invocation flag:** Disable colors for a single call without
  changing the environment. (#UX-012)

  ```bash
  pfb --no-color info "Plain text output"
  ```

- **ANSI color variables and cursor helpers available at source time:** Previously,
  `cursor_on`, `rgb_fg`, `INFO_COLOR`, etc. required at least one `pfb` call to
  become available. They are now defined when `pfb.sh` is sourced. (#UX-011, #UX-013)

  ```bash
  source ./pfb.sh
  printf "${INFO_COLOR}available immediately${RESET}\n"
  cursor_off  # no pfb call needed first
  ```

### Fixes

- **Interactive UI now writes to stderr** (`pfb confirm`, `pfb select`). This means
  `result=$(command_that_calls_pfb)` no longer captures terminal control sequences.
  The pattern matches gum, fzf, and Inquirer.js. (#UX-001)

- **`pfb confirm` no longer hangs on EOF** (piped input, closed stdin). EOF is
  treated as "enter" and uses the current default. (#UX-005)

- **`pfb select` with no arguments** now exits 1 with a clear usage error instead
  of corrupting the terminal. (#UX-006)

- **`pfb spinner` with no subcommand** now shows a helpful usage message with
  examples instead of `unknown spinner subcommand ''`. (#UX-010)

- **Exact command matching** replaces glob patterns in the dispatch table. Commands
  like `pfb errrr`, `pfb inofoo` no longer silently succeed — they now fall through
  to the Levenshtein typo corrector. (#UX-009)

  Recognized aliases: `info|information`, `warn|warning`, `err|error`, `success|done`.

- **Spinner style range corrected** to `0-17` in `--help` and README (was `0-16`). (#UX-004)

- **README typo** `inpur` → `input` in the input section. (#UX-015)

### Backward Compatibility

| Old pattern | Status | Migration |
|---|---|---|
| `pfb select ...; idx=$?` | Deprecated | `idx=$(pfb select ...)` |
| `pfb select-from ...` | Preserved (exit-code alias) | Migrate to `pfb select` |
| `pfb wait <msg> [cmd]` | Preserved | `pfb spinner start` |
| `pfb wait-stop` | Preserved | `pfb spinner stop` |
| `pfb done "msg"` | Preserved as alias | `pfb success` |

---

## [1.1.0-beta] — pre-release baseline

Initial tagged release capturing the state before the v2.0.0 UX overhaul.
See the [v1.1.0-beta release](https://github.com/ali5ter/pfb/releases/tag/v1.1.0-beta)
for details.
