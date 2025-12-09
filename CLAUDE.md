# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

pfb (pretty feedback) is a single-file bash utility library that provides formatted terminal output for shell scripts. It uses ANSI/VT100 Terminal Control Escape Sequences to create interactive and visually appealing command-line interfaces.

## Core Architecture

The entire library is contained in `pfb.sh` as a single bash function `pfb()` with multiple internal helper functions:

- **Main function**: `pfb()` - dispatcher that routes to specific message types
- **ANSI setup**: `_set_ansi_vars()` - initializes color and formatting variables
- **Message rendering**: `_print_message()` - handles formatted output
- **Interactive selection**: `_select_option()` - arrow-key navigable menu system
- **Progress indication**: `_wait()` - spinner animation for long-running commands
- **Logging**: `_logfile()` - returns the path to log file for command output
- **Cursor control**: Helper functions like `cursor_up`, `cursor_down`, `line_start`, `erase_line` for terminal manipulation
- **RGB colors**: `rgb_fg(r, g, b)` and `rgb_bg(r, g, b)` for 24-bit true color support

## Message Types

The library is invoked via `pfb [message-type] [message] [optional-params]`:

- `info|warn|error|success` - Standard log levels with color coding
- `heading [icon]` - Section headers with optional emoji/icon
- `subheading` - Dimmed text under headings
- `suggestion` - Green highlighted suggestions
- `prompt` - Formatted prompt that saves cursor position
- `answer` - Answer text that appears after prompt (restores cursor position)
- `wait [message] [command]` - Runs command with spinner animation, logs to file
- `select-from [array]` - Interactive arrow-key menu, returns selected index via exit code
- `test` - Demonstrates all features with examples
- `logfile` - Echoes the current log file path

## Key Design Patterns

### Cursor Position Management
The prompt/answer pair uses `save_pos()` and `restore_pos()` to place answer text inline after the prompt question.

### Interactive Selection Return Value
The `select-from` command returns the selected index as an exit code (`return "$selected"`), which callers capture using `$?`.

### Spinner Animation with Frame Arrays
The `wait` command implements spinner animation using arrays of frames rather than string manipulation:
- Each spinner style (0-18) is defined as a separate array (e.g., `spinner_0`, `spinner_1`, etc.)
- Style 18 uses Claude Code's asterisk-like spinner characters: `·` `✢` `✳` `✶` `✻` `✽`
- The selected style's frames are copied to a working `frames` array
- Animation loops through frames using array indexing: `${frames[step++ % ${#frames[@]}]}`
- Each iteration: `line_start` (moves cursor to start) → `erase_line` (clears line) → `printf` (prints frame)
- This approach avoids substring extraction and handles multi-byte Unicode characters reliably

### Command Execution and Logging
The `wait` command runs commands in background, displays animated spinner while monitoring process, then clears the line for subsequent success/error messages. All commands are logged with timestamps to `$PFB_DEFAULT_LOG_DIR/$PFB_DEFAULT_LOG.log`.

**Job Control Suppression**: To prevent bash job control messages from appearing during animation:
- The background job is started with stderr redirected: `{ eval "$command" >>"$logfile" 2>&1 & } 2>/dev/null`
- Immediately disowned to remove from job table: `disown 2>/dev/null`
- Process monitoring uses `kill -0 "$pid"` to check if process is running
- Final cleanup with `wait "$pid" 2>/dev/null` ensures proper process reaping
- This approach completely suppresses both the initial `[1] PID` and completion `[1]+ Done` messages

## Configuration

Environment variables:
- `PFB_SPINNER_STYLE` - Spinner style index 0-18 (default: 2). The test function displays all available spinner styles with names. Style 18 uses Claude Code's spinner characters.
- `PFB_DEFAULT_LOG_DIR` - Directory for log files (default: `$HOME/logs`)
- `PFB_DEFAULT_LOG` - Log file basename (default: `scripts`). Creates `$PFB_DEFAULT_LOG_DIR/$PFB_DEFAULT_LOG.log`

## Testing

Run the built-in test suite:
```bash
source ./pfb.sh && pfb test
```

This demonstrates all message types, interactive features, and spinner animations.

## Development Considerations

- The script uses ANSI escape sequences, so terminal compatibility matters
- Cursor manipulation functions are exported and available to scripts that source pfb.sh
- The `_select_option` function traps SIGINT to restore cursor and echo on exit
- shellcheck directives are used to suppress expected warnings for printf formatting and dynamic variable assignment
- RGB color functions (`rgb_fg`, `rgb_bg`) provide 24-bit true color support using the format `ESC[38;2;R;G;Bm` for foreground and `ESC[48;2;R;G;Bm` for background (requires modern terminal with true color support)

## Color Palette

pfb uses a modern RGB color palette designed for readability and semantic meaning:
- **INFO_COLOR** (100, 180, 220): Soft blue-cyan for informational messages, less harsh than standard cyan
- **WARN_COLOR** (255, 180, 80): Warm amber for warnings, better contrast than pure yellow
- **ERROR_COLOR** (240, 90, 90): Clear red for errors, slightly softened from pure red
- **SUCCESS_COLOR** (90, 200, 120): Fresh green for success messages, modern and pleasant
- **SPINNER_COLOR** (215, 119, 87): Claude Code's signature orange for spinner animations
- **PROMPT_COLOR** (120, 220, 240): Bright cyan for interactive prompts

The basic 8 ANSI colors are still available for backward compatibility.
