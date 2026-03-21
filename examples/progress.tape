Output progress.gif

Set Height 200
Source config.tape

Type `for i in {1..30} ; do \` Enter
Type `  pfb progress $i 30 "Downloading poodles..." ; \` Enter
Type `  sleep 0.1 ; \` Enter
Type `done; \` Enter
Type `cursor_up ; \` Enter
Type `erase_line ; \` Enter
Type `pfb success "Download complete!"`
Enter
Sleep 7s
