# @file headings.tape
# @brief Generate animated gif for pfb heading styles
#        using `vhs headings.tape`
# @note Make sure to adjust environment settings as needed
#       before running vhs, e.g. `unset PROMPT_COMMAND`
# @ref VHS documentation: https://github.com/charmbracelet/vhs

Output headings.gif

Source config.tape

Sleep 1s
Type `pfb heading "A default heading"`
Enter
Sleep 1s
Type `pfb heading "A default heading with an icon defined" "🐸"`
Enter
Sleep 1s
Type `pfb subheading "A subheading to go with to add more context"`
Enter
Sleep 1s
Type `pfb suggestion "A suggestion heading style to draw attention to something important."`
Enter
Sleep 3s