tell application "AnyBar" to set message to "blue Hello"
tell application "AnyBar" to set current to get message as Unicode text
display notification current