# pfb

A simple bash script to provide pretty feedback for your scripts.

![video of pfb example output](/pfb_example.gif)

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
export PFB_SPINNER_STYLE=18  # Use Claude Code style spinner
export PFB_DEFAULT_LOG_DIR="/var/log/myscripts"
source ./pfb.sh
```

### Log levels

pfb provides regular log level feedback using the following command.

`pfb [info|warn|error|success] message`

### Headings

pfb provides headings with a leading icon and sub-headings for adding detail under the heading.

A heading is echoed by using the following pfb command.

`pfb heading message [icon]`

Subheadings can be echoed after headings using

`pfb subheading message`

Not really a heading but a formatted subheading indicating a suggestion...

`pfb suggestion message`

### Long running commands

pfb can provide feedback that a command is being processed using

`pfb wait message some_command`

This is usefully follwed up with a pfb success log level message or a pfb answer message.

### Prompt and answer

For a formatted prompt message use

`pfb prompt message`

The pfb answer message can be used to put a formatted answer after the prompt message.

`pfb answer message`

### Selection from a set of options

pfb provides a way to select from a list of options using the up/down keys using

`pfb select-from array_of_options`

## Helper functions and variables

pfb uses ANSI/VT100 Terminal Control Escape Sequences which you can use yourself:

| Function Name | Use |
| :------- | ------- |
| cursor_on | Turn on the cursor |
| cursor_off | Turn off the cursor |
| get_cursor_row | Echo the current row number of the cursor |
| cursor_to row [column] | Move the cursor to a position |
| cursor_up | Move the cursor to the row above |
| cursor_down | Move the cursor to the row below |
| line_start | Move the cursor to the beginning of the current line |
| erase_down | Remove all content from the cursor down |
| erase_eol | Remove all content from the cursor to the end of the line |
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
| SPINNER_COLOR | Claude Code orange (RGB: 215, 119, 87) for spinners |
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
