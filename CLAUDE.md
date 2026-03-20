# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

pfb (pretty feedback for bash) is a lightweight, dependency-free Bash library that provides terminal UI components and feedback mechanisms for shell scripts. The entire library is contained in a single `pfb.sh` file that can be sourced into any Bash script.

## Core Architecture

### Single-File Design
The entire library exists in `pfb.sh`. This file must:
- Be sourceable with `source pfb.sh`
- Work on bash 4.0+ with zero dependencies
- Be completely self-contained (no external binaries except standard UNIX utilities)

### Key Design Patterns

**ANSI/VT100 Terminal Control**: All visual output uses ANSI escape sequences defined in `_pfb_set_ansi_vars()`, called once at source time. The library provides cursor control, color management, and screen manipulation primitives.

**Function Namespace**: All internal functions are prefixed with `_` (e.g., `_wait_start`, `_print_message`). The public API is accessed via the main `pfb()` function which routes to internal implementations based on the first argument.

**Spinner Management**: Background spinner processes use a flag file (`/tmp/pfb_spinner_$$_${RANDOM}`) for synchronization. The spinner PID and flag path are stored in `PFB_SPINNER_PID` and `PFB_SPINNER_FLAG`. The `_wait_stop()` function MUST be synchronous to prevent race conditions.

**Cursor Position Save/Restore**: The prompt/answer pattern uses `save_pos()` and `restore_pos()` to maintain cursor position across multi-step interactions. This is critical for inline feedback.

## Configuration

Environment variables controlling behaviour (set before sourcing pfb.sh):
- `PFB_SPINNER_STYLE` (default: 2) — Spinner animation style (0-17)
- `PFB_DEFAULT_LOG_DIR` (default: `$HOME/logs`) — Command log directory
- `PFB_DEFAULT_LOG` (default: "scripts") — Log file basename
- `PFB_NON_INTERACTIVE` (default: unset) — Set to `1` to auto-answer prompts (CI/cron)
- `PFB_FORCE_COLOR` (default: unset) — Force colors even when stdout is not a TTY
- `PFB_NO_COLOR` (default: 0) — Set to `1` to disable colors
- `NO_COLOR` (default: unset) — Standard color-disable flag (https://no-color.org)

## Public API Commands

Access all functionality via: `pfb <command> [args...]`

**Log levels**: `info`, `warn`, `err`, `success`
**Headings**: `heading`, `subheading`, `suggestion`
**Spinners**: `spinner start` (with optional command), `spinner stop`
**Input**: `input`, `confirm`, `select`
**Prompt pattern**: `prompt`, `answer`
**Utilities**: `test`, `list-spinner-styles`, `logfile`

**Backward compatibility**: The old commands (`wait`, `wait-stop`, `select-from`) continue to work as redirects to the new API.

## Testing and Development

**Run the demo**: `source ./pfb.sh && pfb test`
This interactive demo showcases all pfb features and spinner styles.

**Generate example GIFs**: Uses [vhs](https://github.com/charmbracelet/vhs) for tape-based terminal recordings.
Always use `run_vhs.sh` — never call `vhs` directly. The script runs `unset PROMPT_COMMAND`
before invoking vhs, which prevents shell prompt hooks (e.g. starship) from producing
`command not found` errors inside the recordings.

```bash
cd examples
./run_vhs.sh select.tape   # Regenerate a single GIF
./run_vhs.sh               # Regenerate all GIFs
```

**VHS tapes** in `examples/` directory:
- All tapes source `config.tape` for consistent styling
- Each tape corresponds to a feature demo (e.g., `spinner.tape` → `spinner.gif`)
- The `run_vhs.sh` script skips `config.tape` when generating all

**Visual review after regeneration**: Extract frames with ffmpeg and read them as images
to check for regressions — do not rely on reading the GIF directly (only shows first frame):

```bash
count=$(ffprobe -v error -select_streams v:0 -count_frames \
  -show_entries stream=nb_read_frames -of default=nokey=1:noprint_wrappers=1 file.gif 2>/dev/null)
ffmpeg -y -i file.gif -vf "select=eq(n\,$((count * 95 / 100))),scale=1024:-1" \
  -frames:v 1 /tmp/review.png 2>/dev/null
# Then: Read /tmp/review.png
```

## Color System

**Basic colors**: 8 ANSI colors available as foreground (`BLACK`, `RED`, etc.) and background (`BBLACK`, `BRED`, etc.)

**RGB colors**: Use `rgb_fg(r, g, b)` and `rgb_bg(r, g, b)` for 24-bit color:
```bash
printf "$(rgb_fg 215 119 87)Orange text${RESET}\n"
```

**Semantic colors**: Pre-defined RGB colors for consistency:
- `INFO_COLOR` - Soft blue-cyan (100, 180, 220)
- `WARN_COLOR` - Warm amber (255, 180, 80)
- `ERROR_COLOR` - Clear red (240, 90, 90)
- `SUCCESS_COLOR` - Fresh green (90, 200, 120)
- `SPINNER_COLOR` - Claude orange (215, 119, 87)
- `PROMPT_COLOR` - Bright cyan (120, 220, 240)

Always use `${RESET}` to clear formatting.

## Key Implementation Details

**Spinner cleanup**: The spinner background process cleanup in `_wait_stop()` (called by `pfb spinner stop`) follows this sequence:
1. Remove flag file to signal stop
2. Wait up to 0.5s for graceful exit
3. Force kill if still running
4. Clear line and restore cursor

**Confirm prompts**: Accept y/n keys, arrow keys for navigation, and enter to select.
Default is "Yes"; pass an optional second arg to change: `pfb confirm "Delete?" no`.
All interactive UI writes to stderr; exit code 0 = yes, 1 = no.

**Select**: Uses arrow keys only. Returns selected index via stdout — capture with
`selected=$(pfb select ...)`. The legacy `select-from` alias returns via exit code (`$?`) for
backward compatibility. IMPORTANT: `_pfb_set_ansi_vars` must NOT be called inside `pfb()`;
it runs once at source time. Re-calling it inside a `$(...)` subshell would see non-TTY stdout
and wipe `ESC=""`, corrupting all cursor sequences.

**Input with defaults**: Displays default in `[brackets]`, returns default if user presses enter without typing.

## Cursor Control Functions

Low-level cursor control is available for custom UI:
- `cursor_on`, `cursor_off` - Visibility
- `get_cursor_row`, `get_cursor_col` - Position queries
- `cursor_to row [col]`, `cursor_up`, `cursor_down`, `cursor_sol` - Movement
- `erase_down`, `erase_up`, `erase_screen`, `erase_eol`, `erase_sol`, `erase_line` - Clearing
- `save_pos`, `restore_pos` - Position stack

## Logging

Commands run via `pfb spinner start "message" command` are logged to `$PFB_DEFAULT_LOG_DIR/$PFB_DEFAULT_LOG.log` with command and output.

## Compatibility Notes

- Requires Bash 4.0+ for nameref support (`local -n`)
- Uses `disown` to detach background processes
- Terminal must support ANSI/VT100 escape sequences
- The `_wait()` function uses job control tricks to suppress Bash background job messages
