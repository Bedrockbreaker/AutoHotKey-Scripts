;@Ahk2Exe-ExeName %A_Desktop%\Projects\JavaSwitcher.exe

#Requires AutoHotkey v2.0
#SingleInstance

try {
	Run("*RunAs `"cmd`" /d /c `"" . A_MyDocuments . "\AutoHotkey\JavaSwitcher\JavaSwitcher.bat`"")
}