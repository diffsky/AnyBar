#!/usr/bin/env osascript

tell application "AnyBar.app"
    launch
    activate
end tell

delay 3

tell application "AnyBar.app"
    set message to "green"
    display notification message as Unicode text
end tell

delay 3

tell application "AnyBar.app"
    set message to "#ffcc33 A nice shade of orange"
    display notification message as Unicode text
end tell

delay 3

tell application "AnyBar.app"
    quit
end tell

