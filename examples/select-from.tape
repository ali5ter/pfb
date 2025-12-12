Output select-from.gif

Set Height 400
Source config.tape

Type `pfb select-from 'Option 1' 'Option 2' 'Option 3' 'Option 4' 'Option 5' 'Option 6'`
Enter
Sleep 2
Enter
Enter
Type `pfb prompt "A prompt with a list of possible answers" ; \` Enter
Type `options=('Option 1' 'Option 2' 'Option 3' 'Option 4' 'Option 5' 'Option 6') ;\` Enter
Type `pfb select-from "${options[@]}" ; \` Enter
Type `selected=$? ; \` Enter
Type `cursor_up ; \` Enter
Type `erase_line ; \` Enter
Type `pfb prompt "A prompt with a list of possible answers" ; \` Enter
Type `pfb answer "${options[$selected]}"` Enter
Enter
Sleep 1
Down
Sleep 500ms
Down
Sleep 500ms
Down
Sleep 500ms
Down
Sleep 500ms
Down
Sleep 500ms
Down
Sleep 500ms
Down
Sleep 500ms
Down
Sleep 500ms
Down
Sleep 500ms
Up
Sleep 500ms
Up
Sleep 500ms
Enter
Sleep 3