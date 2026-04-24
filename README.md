# pfb

<p align="center">
  <img src="assets/pfb-hero.png" width="800" alt="pfb – pretty feedback for bash scripts">
</p>
<p align="center">
  <strong>Pretty feedback for Bash scripts.</strong><br>
  Lightweight • Dependency-free • Pleasant by default
</p>

![video of pfb example output](examples/pfb_demo.gif)

## Installation

### Debian / Ubuntu

```bash
curl -sL https://raw.githubusercontent.com/ali5ter/pfb/main/install.sh | bash
```

The installer detects `apt`/`dpkg` and downloads the `.deb` from the latest GitHub Release automatically.
To install manually:

```bash
# Download the .deb from https://github.com/ali5ter/pfb/releases/latest
sudo dpkg -i pfb_<version>_all.deb
```

Installs pfb to `/usr/bin/pfb`.

### Homebrew (macOS)

```bash
brew tap ali5ter/pfb
brew install pfb
```

Installs pfb to `$(brew --prefix)/bin/pfb`.

### One-line installer (Linux / macOS without Homebrew)

```bash
curl -sL https://raw.githubusercontent.com/ali5ter/pfb/main/install.sh | bash
```

Installs pfb to `~/.local/bin/pfb`. When Homebrew is present the installer
delegates to `brew` automatically. Re-running is safe — the installer is idempotent.

### Git submodule

For projects that pin pfb at a specific version:

```bash
git submodule add https://github.com/ali5ter/pfb lib/pfb
```

Then source it in your scripts with `source lib/pfb/pfb.sh` or run it directly as `lib/pfb/pfb.sh`.

### Manual

Download `pfb.sh` from a [GitHub release](https://github.com/ali5ter/pfb/releases) and place it anywhere on your path.

## Usage

After installing, pfb is available as a command:

```bash
pfb info "Hello from pfb"
pfb test  # interactive demo of all features
```

To use pfb's helper functions and color variables inside a script, source it:

```bash
source "$(command -v pfb)"
```

For portability across install methods, use a path fallback:

```bash
for _pfb in \
    "$(brew --prefix 2>/dev/null)/bin/pfb" \
    /usr/bin/pfb \
    ~/.local/bin/pfb; do
    [[ -f "$_pfb" ]] && { source "$_pfb"; unset _pfb; break; }
done
```

### Configuration

pfb can be configured using environment variables:

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `PFB_SPINNER_STYLE` | `2` | Spinner style (0-17). Run `pfb test` to see all styles |
| `PFB_SPINNER_LABEL` | `wait` | Spinner/progress prefix label. Set to empty string to suppress the prefix |
| `PFB_DEFAULT_LOG_DIR` | `$HOME/logs` | Directory where command logs are stored |
| `PFB_DEFAULT_LOG` | `scripts` | Base name for log files (creates `$PFB_DEFAULT_LOG.log`) |
| `PFB_NON_INTERACTIVE` | (unset) | Set to `1` to auto-answer prompts with defaults (CI, cron, scripts) |
| `NO_COLOR` | (unset) | Disable colors (see [no-color.org](https://no-color.org)) |
| `PFB_NO_COLOR` | `0` | pfb-specific color disable (set to `1` to disable) |
| `PFB_FORCE_COLOR` | (unset) | Force colors even when not a TTY (must be exported before running pfb) |

Example:

```bash
export PFB_SPINNER_STYLE=13
export PFB_DEFAULT_LOG_DIR="/var/log/myscripts"
export NO_COLOR=1  # Disable colors for accessibility
pfb info "Colors disabled"
```

### Log levels

![video of pfb log-levels](examples/log-levels.gif)

pfb provides regular log level feedback using the following command.

`pfb [info|warn|error|success] message`

### Headings

![video of pfb headings](examples/headings.gif)

pfb provides headings with a leading icon and sub-headings for adding detail under the heading.

A heading is echoed by using the following pfb command.

`pfb heading message [icon]`

Subheadings can be echoed after headings using

`pfb subheading message`

Not really a heading but a formatted subheading indicating a suggestion...

`pfb suggestion message`

### Long running commands

![video of pfb wait spinner](examples/spinner.gif)

pfb can provide feedback that a command is being processed using

`pfb spinner start message some_command`

You can also start a spinner manually and stop it later:

```bash
pfb spinner start message
pfb spinner stop
```

The prefix label defaults to `[wait]`. Use `PFB_SPINNER_LABEL` to customise it or set it to
empty to suppress the prefix entirely:

```bash
PFB_SPINNER_LABEL="deploy" pfb spinner start "Deploying to production..." deploy.sh
# [deploy] ⣾ Deploying to production...

PFB_SPINNER_LABEL="" pfb spinner start "Downloading..." 'curl ...'
# ⣾ Downloading...
```

This is usefully followed up with a pfb success log level message or a pfb answer message.

### Progress bar

![video of pfb progress bar](examples/progress.gif)

For operations with a known completion percentage, use the determinate progress bar:

`pfb progress <current> <total> [message]`

Each call redraws on the same line. Follow the loop with a log-level message to signal
completion:

```bash
files=(*.log)
for i in "${!files[@]}"; do
    process "${files[$i]}"
    pfb progress $(( i + 1 )) ${#files[@]} "Processing files..."
done
pfb success "All files processed!"
```

The bar adapts to the terminal width and respects `PFB_SPINNER_LABEL` for the prefix
(including the empty-string no-prefix option). Colors degrade to ASCII `=` characters
when `NO_COLOR` is set:

```bash
# Color mode (default)
# [wait] ████████████░░░░░░░░░░░░░░░  42% Downloading...

# No-color mode
# [wait] [============               ]  42% Downloading...
```

### Text input

![video of pfb input](examples/input.gif)

Collect text input from the user with an optional default value:

`result=$(pfb input "prompt message" [default_value])`

Example:

```bash
name=$(pfb input "What's your name?" "Anonymous")
echo "Hello, $name!"
```

The default value is shown in brackets and used if the user presses enter without typing anything.

### Confirmation prompts

![video of pfb confirm](examples/confirm.gif)

Ask the user a yes/no question and get the result as an exit code:

`pfb confirm "question" [yes|no]`

Returns exit code 0 for yes, 1 for no. Use left/right arrow keys, `y`/`n`, or enter to select.
The selected option is highlighted and the hint capitalises the current default (`Y/n` or `y/N`).

An optional second argument sets the default answer (default is `yes`):

```bash
pfb confirm "Delete all files?" no    # Defaults to No
pfb confirm "Continue?" yes           # Defaults to Yes (explicit)
```

Example:

```bash
if pfb confirm "Delete this file?"; then
    rm file.txt
    pfb success "File deleted"
else
    pfb info "Cancelled"
fi
```

### Selection from a set of options

![video of pfb select](examples/select.gif)

pfb provides a way to select from a list of options using the up/down keys using

`pfb select array_of_options`

Example:

```bash
options=("Option 1" "Option 2" "Option 3")
selected=$(pfb select "${options[@]}")
echo "You selected: ${options[$selected]}"
```

### Prompt and answer

![video of pfb prompt-answer](examples/prompt-answer.gif)

For integrating with external tools like fzf, use the prompt/answer pattern:

`pfb prompt message`

The pfb answer message can be used to put a formatted answer after the prompt message.

`pfb answer message`

This pattern saves the cursor position after the prompt and restores it when displaying the answer, keeping everything on
one line. For simple text input, use `pfb input` instead.

## Helper functions and variables

Cursor helper functions and color variables are available when pfb is sourced into your script.
Use `source "$(command -v pfb)"` to load them — no prior `pfb` call is required.

> **Note:** Color variables (`INFO_COLOR`, `BOLD`, `RESET`, etc.) are set to ANSI codes only when
> stdout is a TTY at source time. In CI or piped contexts, set `PFB_FORCE_COLOR=1` **before**
> sourcing to force colors.

pfb uses ANSI/VT100 Terminal Control Escape Sequences which you can use yourself:

| Function Name | Use |
| :------- | ------- |
| cursor_on | Turn on the cursor |
| cursor_off | Turn off the cursor |
| get_cursor_row | Echo the current row number of the cursor |
| get_cursor_col | Echo the current column number of the cursor |
| cursor_to row [column] | Move the cursor to a position |
| cursor_up | Move the cursor to the row above |
| cursor_down | Move the cursor to the row below |
| cursor_sol | Move the cursor to the start of the current line |
| erase_down | Remove all content from the cursor down |
| erase_up | Remove all content from the cursor up |
| erase_screen | Remove all content from the screen |
| erase_eol | Remove all content from the cursor to the end of the line |
| erase_sol | Remove all content from the cursor to the start of the line |
| erase_line | Remove all content on the current line |
| save_pos | Store the current position of the cursor |
| restore_pos | Restore the position of the cursor to the last saved position |
| rgb_fg r g b | Set foreground color using RGB values (0-255) |
| rgb_bg r g b | Set background color using RGB values (0-255) |

Examples of how these area used can be seen in the pfb script.

| Variable Name | Use |
| :------- | ------- |
| BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE | Basic 8-color foreground colors |
| BBLACK BRED BGREEN BYELLOW BBLUE BMAGENTA BCYAN BWHITE | Basic 8-color background colors |
| INFO_COLOR | Soft blue-cyan (RGB: 100, 180, 220) for info messages |
| WARN_COLOR | Warm amber (RGB: 255, 180, 80) for warnings |
| ERROR_COLOR | Clear red (RGB: 240, 90, 90) for errors |
| SUCCESS_COLOR | Fresh green (RGB: 90, 200, 120) for success |
| SPINNER_COLOR | Claude orange (RGB: 215, 119, 87) for spinners |
| PROMPT_COLOR | Bright cyan (RGB: 120, 220, 240) for prompts |
| BOLD DIM REV RESET | Display attributes |

Examples using these variables:

`printf "${BYELLOW}${RED}${BOLD}This is bold red text on a yellow background${RESET}"`

`echo "${REV}This is reversed text${RESET}"`

`printf "${INFO_COLOR}Informational message${RESET}\n"`

`printf "${SUCCESS_COLOR}Success message${RESET}\n"`

Examples using RGB color functions:

`printf "$(rgb_fg 215 119 87)Orange text${RESET}\n"`

`printf "$(rgb_bg 50 150 50)Green background${RESET}\n"`

`printf "$(rgb_fg 255 100 200)$(rgb_bg 50 50 100)Custom colors${RESET}\n"`

## Comparison with gum

[gum](https://github.com/charmbracelet/gum) is a more comprehensive TUI toolkit that offers similar functionality with
additional components like file browsers, tables, pagers, and advanced text filtering.

**When to use pfb:**

- Zero dependencies - a single bash file (~10KB) installed to your PATH
- Maximum portability (works anywhere with bash 4.0+)
- No external binary installation required
- Direct function calls (no process spawning overhead)
- Basic terminal feedback is sufficient for your needs

**When to use gum:**

- Need advanced components (file browser, tables, fuzzy filtering, pagers)
- Building sophisticated interactive scripts
- Prefer standalone binaries over sourced libraries
- Want extensive styling options via CLI flags

pfb occupies the lightweight, dependency-free niche — ideal for scripts you distribute or run in constrained
environments where installing external tools adds friction.
