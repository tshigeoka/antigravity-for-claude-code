# Antigravity for Claude Code — demo GIF script (for charmbracelet/vhs)
#
# Produces docs/demo.gif. Run from the REPO ROOT:
#   brew install vhs          # or: go install github.com/charmbracelet/vhs@latest
#   vhs docs/demo.tape
#
# It plays a representative `/antigravity:delegate` run (see docs/demo-playback.sh).

Output docs/demo.gif

Set Shell bash
Set FontSize 18
Set Width 1120
Set Height 460
Set Padding 26
Set Theme "Dracula"
Set TypingSpeed 45ms

# Launch the playback without showing the launch command (Hide), then capture its output.
Hide
Type "clear && bash docs/demo-playback.sh"
Enter
Show

# Keep recording until the playback (~7s) finishes; trailing pause for readability.
Sleep 9s
