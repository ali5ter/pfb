Output pfb_example.gif
Set FontSize 14
Set Width 1200
Set Height 800
Set Theme "Catppuccin Mocha"

# Hide the source and command execution
Hide
Type "source ./pfb.sh && pfb test"
Show
Enter

# Wait for the full demo to complete
# Adjust this timing based on how long pfb test takes
Sleep 40s
