Output spinner.gif

Set Height 450
Source config.tape

Type `pfb wait "A default spinner message while performing some command." 'sleep 2' && pfb success "Done"`
Enter
Sleep 2s
Type `pfb wait "Spinner message with no command." && pfb wait-stop && pfb success "Done"`
Enter
Sleep 2s
Type `pfb list-spinner-styles`
Enter
Sleep 1s
Type "export PFB_SPINNER_STYLE=9"
Enter
Sleep 1s
Type `pfb wait "A different spinner style while performing some command." 'sleep 2' && pfb success "Done"`
Enter
Sleep 3s