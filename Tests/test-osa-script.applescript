tell application "AnyBar"
	set message to "red"
	set message to "green"
	set message to "blue"
	set message to "#33cc44 Looking good"
	
	set dmode to dark mode of the app delegate
	set uport to udp port of the app delegate
	
	set output to name & �
		" " & version & �
		" (" & uport & ")" & �
		" dark mode: " & dmode & �
		" message : " & message �
		as Unicode text
	
	display notification output
end tell