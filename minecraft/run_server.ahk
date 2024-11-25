#Requires AutoHotkey v2.0

instance := ""
if (A_Args.Length < 1) {
	servers := []
	Loop Files A_AppData . "\PrismLauncher\instances\*", "D" {
		if (FileExist(A_LoopFilePath . "\server\launch.bat"))
			servers.Push(A_LoopFileName)
	}

	selector := Gui("-MaximizeBox -MinimizeBox", "Select instance")
	selector.OnEvent("Close", (theGui) => ExitApp())
	selector.OnEvent("Escape", (theGui) => ExitApp())
	list := selector.AddListBox("w150 r" . servers.Length . " vlist", servers)
	list.OnEvent("DoubleClick", HandleSelect)
	button := selector.AddButton("x+-34 y+8 Default", "Run")
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

SetWorkingDir(A_AppData . "\PrismLauncher\instances\" . instance . "\server\")

pidfile := FileOpen("latestpid", "rw")
pid := pidfile.Read()
pidfile.Close()

if (WinExist("ahk_pid " . pid)) {
	WinActivate("ahk_pid " . pid)
	Run("wt -w `"" . instance . " Server`" focus-tab -t 0")
} else {
	Run("wt -w `"" . instance . " Server`" --title `"" . instance . " Server`" --suppressApplicationTitle --tabColor #881798 " . A_WorkingDir . "\launch.bat")
	hWnd := WinWait("" . instance . " Server ahk_exe WindowsTerminal.exe")
	pid := WinGetPID(hWnd)
}

pidfile := FileOpen("latestpid", "w")
pidfile.Write(pid)
pidfile.Close()
return

HandleSelect(control, optionNumber) {
	global instance := list.Text
	selector.Destroy()
}