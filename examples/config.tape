# @file config.tape
# @brief Configuration to source in other vhs tape files
# @note Make sure to adjust environment settings as needed
#       before running vhs, e.g. `unset PROMPT_COMMAND`
# @ref VHS documentation: https://github.com/charmbracelet/vhs

Set FontSize 14
Set Width 1024
Set Height 480
Set Shell bash

Hide
Type `PS1="❯ "` Enter
Type "source ../pfb.sh" Enter
Type "clear" Enter
Sleep 100ms
Show