# pfb

<p align="center">
  <img src="assets/pfb-hero.png" width="800" alt="pfb – pretty feedback for bash scripts">
</p>
<p align="center">
  <strong>Pretty feedback for Bash scripts.</strong><br>
  Lightweight • Dependency-free • Pleasant by default
</p>

![video of pfb example output](examples/pfb_demo.gif)

## Usage

Use the functions in this script by sourcing it in your scripts, e.g.
`source [path_to]/pfb.sh`

An example of pretty feedback provided by pfb can be shown by running the following command.

`source ./pfb.sh && pfb test`

### Configuration

pfb can be configured using environment variables:

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `PFB_SPINNER_STYLE` | `2` | Spinner style (0-18). Run `pfb test` to see all styles |
| `PFB_DEFAULT_LOG_DIR` | `$HOME/logs` | Directory where command logs are stored |
| `PFB_DEFAULT_LOG` | `scripts` | Base name for log files (creates `$PFB_DEFAULT_LOG.log`) |

Example:

```bash
export PFB_SPINNER_STYLE=18
export PFB_DEFAULT_LOG_DIR="/var/log/myscripts"
source ./pfb.sh
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

`pfb spinner start message`
`pfb spinner stop`

This is usefully followed up with a pfb success log level message or a pfb answer message.

### Text input

![video of pfb inpur](examples/input.gif)

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

`pfb confirm "question"`

Returns exit code 0 for yes, 1 for no. Use left/right arrow keys, y/n, or enter to select.

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

![video of pfb select-from](examples/select-from.gif)

pfb provides a way to select from a list of options using the up/down keys using

`pfb select array_of_options`

Example:

```bash
options=("Option 1" "Option 2" "Option 3")
pfb select "${options[@]}"
selected=$?
echo "You selected: ${options[$selected]}"
```

### Prompt and answer

![video of pfb prompt-answer](examples/prompt-answer.gif)

For integrating with external tools like fzf, use the prompt/answer pattern:

`pfb prompt message`

The pfb answer message can be used to put a formatted answer after the prompt message.

`pfb answer message`

This pattern saves the cursor position after the prompt and restores it when displaying the answer, keeping everything on one line. For simple text input, use `pfb input` instead.

## Helper functions and variables

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

[gum](https://github.com/charmbracelet/gum) is a more comprehensive TUI toolkit that offers similar functionality with additional components like file browsers, tables, pagers, and advanced text filtering.

**When to use pfb:**

- Zero dependencies - just source a single bash file (~10KB)
- Maximum portability (works anywhere with bash 4.0+)
- No external binary installation required
- Direct function calls (no process spawning overhead)
- Basic terminal feedback is sufficient for your needs

**When to use gum:**

- Need advanced components (file browser, tables, fuzzy filtering, pagers)
- Building sophisticated interactive scripts
- Prefer standalone binaries over sourced libraries
- Want extensive styling options via CLI flags

pfb occupies the lightweight, dependency-free niche - ideal for scripts you distribute or run in constrained environments where installing external tools adds friction.
