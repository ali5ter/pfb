Output prompt-answer.gif

Set Height 400
Source config.tape

Type `pfb prompt "A formatted prompt message" && pfb answer "An answer"`
Enter
Sleep 2
Enter
Enter
Type `prompt="Prompt before showing a list of strings using fzf..." ; \` Enter
Type `pfb prompt "$prompt" ; \` Enter
Type `word=$(fzf --height=40% --layout=reverse --info=inline --border < <(ls /usr/bin | head -100 | sort)) ; \` Enter
Type `erase_line ; \` Enter
Type `pfb prompt "$prompt" && pfb answer "You chose $word"` Enter
Sleep 2
Type "caffe"
Sleep 500ms
Enter
Sleep 3