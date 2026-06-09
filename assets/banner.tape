# infernal-init demo GIF — "new-shell sim" style
# Fresh prompt appears, banner auto-renders (as if fired from .bashrc),
# cursor blinks below, holds, loops.
Output assets/banner.gif

Set Shell bash
Set FontSize 14
Set Width 960
Set Height 1320
Set Padding 20
Set TypingSpeed 0ms

# Infernal theme: pin ANSI red (title block) -> deep red and ANSI yellow
# (@handle) -> gold, so they match the TrueColor orange/cream art instead of
# resolving to vhs's default hot-pink red.
Set Theme '{ "name": "infernal", "background": "#0d0d0d", "foreground": "#e0d6c0", "cursor": "#fcb648", "selection": "#333333", "black": "#1a1a1a", "red": "#b00000", "green": "#6a6a6a", "yellow": "#fcc04d", "blue": "#5a6a8a", "purple": "#aa3333", "cyan": "#88aaaa", "white": "#d8cdb5", "brightBlack": "#3a3a3a", "brightRed": "#e00000", "brightGreen": "#8a8a8a", "brightYellow": "#ffd166", "brightBlue": "#7a8aac", "brightPurple": "#cc5555", "brightCyan": "#99bbbb", "brightWhite": "#f0e6d2" }'

# --- hidden setup: clean prompt + USER, no echo in recording ---
Hide
Type `export USER=lowcache`
Enter
Type `export PS1='lowcache@localhost:\w\$ '`
Enter
Type "clear"
Enter
Show

# --- new shell just opened: empty prompt + blinking cursor beat ---
Sleep 800ms

# --- .bashrc auto-fires the banner; command text hidden so it reads as automatic ---
Hide
Type "./result/bin/infernalinit"
Enter
Show

# --- banner holds, cursor blinks below, then loop ---
Sleep 2800ms
