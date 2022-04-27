# pfb
A simple bash script to provide pretty feedback for your scripts.

![video of pfb example output](/pfb_example.gif)

## Use
Use the functions in this script by sourcing it in your scripts, e.g.
`source [path_to]/pfb.sh`

An example of pretty feedback provided by pfb can be shown by running the following command.

`source ./pfb.sh && pfb test`

### Log levels
pfb provides regular log level feedback using the following command.

`pfb [info|warn|error|success] message`

### Headings
pfb provides headings with a leading icon and sub-headings for adding detail under the heading.

A heading is echoed by using the following pfb command.

`pfb heading message [icon]`

Subheadings can be echoed after headings using

`pfb subheading message`

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
| erase_down | Remove all content from the cursor down |
| erase_line | Remove all content on the current line |
| save_pos | Store the current position of the cursor |
| restore_pos | Restore the position of the cursor to the last saved position |

Examples of how these area used can be seen in the pfb script.

| Variable Name | Use |
| :------- | ------- |
| BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE | Forground colors |
| BBLACK BRED BGREEN BYELLOW BBLUE BMAGENTA BCYAN BWHITE | Background colors |
| BOLD DIM REV RESET | Display attributes |

Examples using these variables:

`printf "${BYELLOW}${RED}${BOLD}This is bold red text on a yellow background${RESET}"`

`echo "${REV}This is reversed text${RESET}"`