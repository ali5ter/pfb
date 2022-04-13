# pfb
A simple bash script to provide pretty feedback for your scripts.

![video of pfb example output](/pfb_example.gif)

## Use
Use the functions in this script by sourcing it in your scripts, e.g.
`source [path_to]/pfb.sh`

An example of pretty feedback provided by pfb can be shown by running the following command.

`source ./pfb.sh && pfb_test`

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

`pfb_wait message some_command`

This is usefully follwed up with a pfb success log level message or a pfb answer message.

### Prompt and answer
For a formatted prompt message use

`pfb prompt message`

The pfb answer message can be used to put a formatted answer after the prompt message.

`pfb answer message`

### Selection from a set of options
pfb provides a way to select from a list of options using the up/down keys using

`pfb_select_option array_of_options`