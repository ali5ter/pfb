# @file pfb_demo.tape
# @brief Generate animated gif for pfb demo of styles
#        using `vhs pfb_demo.tape`
# @note Make sure to adjust environment settings as needed
#       before running vhs, e.g. `unset PROMPT_COMMAND`
# @ref VHS documentation: https://github.com/charmbracelet/vhs
# @ref _test() function in pfb.sh

Output pfb_demo.gif

Source config.tape

Sleep 1s
Type "pfb test"
Enter

# Section 1: Log levels (auto-displays, then clears after 2s)
Sleep 5s

# Section 2: Headings (auto-displays, then clears after 2s)
Sleep 5s

# Section 3: Long running commands (5s sleep + 2s pause)
Sleep 9s

# Section 4: Spinner styles (19 spinners × 2s each ≈ 38s, then 2s pause)
Sleep 45s

# Section 5: Text input
# Wait for "What's your name?" prompt, then type response
Sleep 1s
Type "Kermit"
Sleep 500ms
Enter
Sleep 5s

# Section 6: Prompt/answer with fzf (only if fzf installed)
Sleep 1s
Type "wonderful"
Sleep 300ms
Enter
Sleep 5s

# Section 7: Selection menu for tie preferences
# Use arrow keys to navigate, then select
Sleep 1s
Down 6
Sleep 500ms
Up 2
Sleep 500ms
Enter
Sleep 5s

# Section 8: Confirmation prompt
# Toggle with arrows to show interaction, then confirm
Sleep 1s
Right      # Switch to "No"
Sleep 500ms
Left       # Switch back to "Yes"
Sleep 500ms
Enter      # Confirm "Yes"
Sleep 5s