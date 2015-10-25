#Include <Misc.au3>
#Include <Color.au3>

Opt("PixelCoordMode", 2)
Opt("MouseCoordMode", 2)
Local $wow = "World of Warcraft"
Local $iniPath = @ScriptDir & "\kbd.ini"
Local $bindings = IniReadSection($iniPath, "bindings")
If @error Then
    MsgBox(4096, "Error", "Error occurred, probably INI file not found." & @CRLF & $iniPath)
	exit
EndIf
Local $buttonsCount = $bindings[0][0]
Local $buttons[$buttonsCount+1]
For $i = 1 To $buttonsCount
	$buttons[Number(StringReplace($bindings[$i][0], "button", ""))] = $bindings[$i][1]
Next


$debug = IniRead($iniPath, "options", "debug", false)
$exit_bind = IniRead($iniPath, "options", "exit_bind", "{MEDIA_STOP}")
$check_interval = IniRead($iniPath, "options", "check_interval", 50)
$delay_after_send = IniRead($iniPath, "options", "delay_after_send ", 250)

HotKeySet($exit_bind, "quit")
Func quit()
   exit 
EndFunc

While 1
	if WinActive($wow) Then
		$flag = PixelGetColor(1,1)
		;ToolTip('Flag: ' & $flag, 10,0)
		if $flag > 0 and $flag <= $buttonsCount Then
			Local $button = $buttons[$flag]
			if StringLen($button) < 1 Then 
				ToolTip("Button not set! flag:" & $flag, 10,0) 
				ContinueLoop
			EndIf
			if $debug Then 
				ToolTip(" Button" & $button & " flag:" & $flag, 10,0) 
			EndIf
			Send($button)
			Sleep($delay_after_send)
		EndIf
	EndIf
	Sleep($check_interval)
WEnd











