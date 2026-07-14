# VHS tape for the chromeshot usage GIF.
# Regenerate with:  vhs docs/demo.tape   (run from a dir with a demo capture.toml)
Output docs/demo.gif

Set Shell "bash"
Set FontSize 20
Set Width 1300
Set Height 460
Set Padding 26
Set Theme "Dracula"
Set TypingSpeed 55ms

Hide
Type "cd /tmp/chromeshot-demo && export PATH=$HOME/bin:$PATH && clear"
Enter
Show

Sleep 600ms
Type "capture --version"
Sleep 400ms
Enter
Sleep 1200ms

Type "capture --list"
Sleep 400ms
Enter
Sleep 2s

Type "capture"
Sleep 400ms
Enter
Sleep 13s
