Output progress.gif

Set Height 350
Source config.tape

Type `for i in {1..30} ; do \` Enter
Type `  pfb progress $i 30 "Downloading poodles..." ; \` Enter
Type `  sleep 0.1 ; \` Enter
Type `done; \` Enter
Type `cursor_up ; \` Enter
Type `erase_line ; \` Enter
Type `pfb success "Download complete!"`
Enter
Sleep 4s
Type `pfb list-progress-styles`
Enter
Sleep 1s
Type "export PFB_PROGRESS_STYLE=6"
Enter
Sleep 4s
Type `for i in {1..30} ; do \` Enter
Type `  pfb progress $i 30 "A different progress style..." ; \` Enter
Type `  sleep 0.1 ; \` Enter
Type `done; \` Enter
Type `cursor_up ; \` Enter
Type `erase_line ; \` Enter
Type `pfb success "Download complete!"`
Enter
Sleep 3s
