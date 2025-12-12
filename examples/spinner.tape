Output spinner.gif

Set Height 400
Source config.tape

Type `pfb wait "A default spinner message while performing some command." 'sleep 2'`
Enter
Sleep 2s
Type `pfb list-spinner-styles`
Enter
Sleep 1s
Type "export PFB_SPINNER_STYLE=9"
Enter
Sleep 1s
Type `pfb wait "A different spinner style while performing some command." 'sleep 2'`
Enter
Sleep 3s