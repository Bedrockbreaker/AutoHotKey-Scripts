#Requires AutoHotkey v2.0

instance := ""
if (A_Args.Length < 1) {
	uninitialized := []
	Loop Files A_AppData . "\PrismLauncher\instances\*", "D" {
		if (!DirExist(A_LoopFilePath . "\.git") && RegExMatch(A_LoopFileName, "^\.") == 0)
			uninitialized.Push(A_LoopFileName)
	}

	selector := Gui("-MaximizeBox -MinimizeBox", "Select instance")
	selector.OnEvent("Close", (gui) => ExitApp())
	selector.OnEvent("Escape", (gui) => ExitApp())
	list := selector.AddListBox("w200 r" . uninitialized.Length . " vlist", uninitialized)
	list.OnEvent("DoubleClick", HandleSelect)
	button := selector.AddButton("x+-34 y+8 Default", "Initialize")
	button.OnEvent("Click", HandleSelect)
	selector.Show()

	WinWaitClose(selector)
	instance := instance || list.Text
} else {
	for (i, arg in A_Args) {
		instance .= arg . " "
	}
	instance := SubStr(instance, 1, StrLen(instance) - 1)
}

SetWorkingDir(A_AppData . "\PrismLauncher\instances\" . instance)

FileCopy(A_MyDocuments . "\AutoHotkey\minecraft\.gitignore.template", A_WorkingDir . "\.gitignore")
FileCopy(A_MyDocuments . "\AutoHotkey\minecraft\.gitattributes.template", A_WorkingDir . "\.gitattributes")
RunWait("cmd /c git init & git config diff.jarbinary true & git config diff.jarbinary.textconv `"echo 'Binary File'`" & git add . & git commit -m `"Initial commit`"",, "Hide")
return

HandleSelect(control, optionNumber) {
	global instance := list.Text
	selector.Destroy()
}