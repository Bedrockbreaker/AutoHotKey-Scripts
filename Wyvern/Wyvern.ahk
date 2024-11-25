;@Ahk2Exe-ExeName %A_Startup%\Wyvern.exe
;@Ahk2Exe-SetMainIcon %A_MyDocuments%\AutoHotkey\Wyvern\wyvern.ico
;@Ahk2Exe-SetDescription Wyvern

#Requires AutoHotkey v2.0
#Include <ImagePut>
#Include <Media>
#Include <Serializer>
#Include <ShinsImageScanClass>
#SingleInstance

A_WorkingDir := A_MyDocuments . "\AutoHotkey"
A_IconTip := "Wyvern"
A_MaxHotkeysPerInterval := 200 ; Specifically for volume controls

autoclick := false
replPID := -1
doColorPick := false
blockMouseG9 := false
rdpDisplayMode := false
AudioDevices := { ; name: id
	Game: "SteelSeries Sonar - Gaming (SteelSeries Sonar Virtual Audio Device)",
	Chat: "SteelSeries Sonar - Chat (SteelSeries Sonar Virtual Audio Device)",
	Media: "SteelSeries Sonar - Media (SteelSeries Sonar Virtual Audio Device)"
}

A_TrayMenu.Insert("1&", "Clear REPL PID", clearReplPID)
A_TrayMenu.Insert("2&", "Open Node REPL", openNodeREPL)
A_TrayMenu.Insert("3&") ; Insert a horizontal separator
A_TrayMenu.Insert("4&", "Toggle RDP Display Settings", toggleRDPDisplaySettings)
A_TrayMenu.Insert("5&") ; Insert a horizontal separator
A_TrayMenu.Insert("6&", "Run MC Server", (*) => Run(A_WorkingDir . "\minecraft\run_server.exe"))
A_TrayMenu.Insert("7&", "Init MC Git Repo", (*) => Run(A_WorkingDir . "\minecraft\init_git.exe"))
A_TrayMenu.Insert("8&") ; Insert a horizontal separator
A_TrayMenu.Insert("9&", "Edit Wyvern", editWyvern)

Serializer.Serialized("rgbProfIndex", &rgbProfIndex, -1)
Serializer.Serialized("rgbOverlayFlags", &rgbOverlayFlags, 0)
Serializer.Serialized("blackout", &blackout, false)
Serializer.Serialized("wanikaniLastVisited", &wanikaniLastVisited, "2000") ; Defaults to the year 2000
Serializer.Serialized("wanikaniLastReminder", &wanikaniLastReminder, "2000")
;SetTimer(scheduler, 60000)
updateRGBProfile()
return

:*?:`:flushed`:::😳
:*?:`:grimace`:::😬
:*?:`:lol`:::😂
:*?:`:pensive`:::😔
:*?:`:sweat`:::😅
:*?:`:thinking`:::🤔
:*?:`:thumbsup`:::👍
:*?:`:triumph`:::😤
:*?:`:b`:::🅱️
:*?:`:shrug`:::¯\_(ツ)_/¯
:*?:`:pog`:::( ՞ਊ ՞)
:*?:`:dab`:::ㄥ(⸝ ، ⸍ )‾‾‾‾‾
:*?:`:xd`:::(≧∇≦)
:*?:`:glasses`:::(⌐■͜ʖ■)
:*?:`:lenny`:::( ͡° ͜ʖ ͡°)
:*?:`:uwu`:::(。U⁄ ⁄ω⁄ ⁄ U。)
:*?:`:tm`:::™️
:*?:`:amogus`:::ඞ
:*?:`:waagone`::: {
	pasteFile(A_WorkingDir . "\Wyvern\waagone.clip")
}
:*?:`:letsgo`::: {
	pasteFile(A_WorkingDir . "\Wyvern\letsgo.clip")
}

!#Left:: {
	Send("^#{Left}")
}

!#Right:: {
	Send("^#{Right}")
}

; TODO: functions for DPI down, keyboard G6 (f13)

; G1: Open VSCode, if it's not already open
; Otherwise, open workspace folder in explorer
$F24:: {
	if (WinActive("ahk_exe code.exe")) {
		Send("{F24}")
	} else {
		MouseGetPos(,, &hoveredWindow)
		if (WinGetProcessName(hoveredWindow) == "Code.exe") {
			WinActivate(hoveredWindow)
			Send("{F24}")
		} else {
			Run("cmd /c code",, "Hide")
		}
	}
}

; Shift+G1: Format and save the current file
#HotIf WinActive("ahk_exe code.exe")
~+F24:: {
	Sleep(100)
	Send("4{Enter}^s")
}
#HotIf

; G2: Cycle between the rgb profiles in the "Special" category
/* F23:: {
	global rgbProfIndex := Mod(rgbProfIndex + 1, 4) ; Cycle 0-3, corresponding to 3 rgb profiles (0-2) and an empty slot (3)
	updateRGBProfile()
} */

; G2: Toggle the Blackout rgb profile
/* ^F23:: {
	global blackout := !blackout
	updateRGBProfile()
} */

; G3
F22:: {
	openNodeREPL()
}

openNodeREPL(*) {
	global replPID
	if (WinExist("ahk_pid " . replPID)) {
		WinActivate("ahk_pid " . replPID)
		Run("wt -w `"Node REPL`" focus-tab -t 0")
	} else {
		Run("wt -w `"Node REPL`" --title `"Node REPL`" --suppressApplicationTitle --tabColor #3cb371 node")
		hWnd := WinWait("Node REPL ahk_exe WindowsTerminal.exe")
		replPID := WinGetPID(hWnd)
	}
}

; G5: Open default terminal at desktop
F21:: {
	Run("wt -d " . A_Desktop)
}

; ^G5: Open elevated default terminal
^F21:: {
	try {
		Run("*RunAs `"cmd`" /k `"echo Running with elevated permissions & cd " . A_Desktop . "`"")
	}
}

; +G5: Open Task Manager
+F21:: {
	Run("C:\Windows\System32\Taskmgr.exe")
}

; G4: Open explorer
F19:: {
	Run("explorer")
}

; ^G4: Open explorer at projects folder
^F19:: {
	Run("explorer " . A_Desktop . "\Projects")
}

; DPI up (Mouse G8): Toggle autoclicker
#MaxThreadsPerHotkey 2
F20:: {
	global autoclick := !autoclick
	clicker({delay: 10, left: true, num: 0, shift: false})
}
#MaxThreadsPerHotkey 1

; G-Shift + Mouse Button (G-Shift + Mouse G9): Color picker
*F18:: {
	global doColorPick := true

	static radius := 5
	static pixelSize := 15
	static scanner := ShinsImageScanClass()

	picker := Gui("+ToolWindow -Caption +AlwaysOnTop", "Wyvern Color Picker")
	picker.MarginX := 0
	picker.MarginY := 0

	dpi := getMouseDPI()

	CoordMode("Mouse", "Screen")

	; Construct the enlarged pixel grid
	Loop (radius * 2 + 1) {
		y := A_Index
		Loop (radius * 2 + 1) {
			x := A_Index
			; Add a square progress bar for each pixel in the picker
			pixel := picker.AddProgress("x" . (pixelSize * (x-1)) . " y" . (pixelSize * (y-1)) . " w" . (pixelSize) . " h" . (pixelSize) . " vPixel" . x . "_" . y)
			pixel.Value := 100
			pixel.Opt("+Background000000")
		}
	}
	picker["Pixel" . (radius+1) . "_" . (radius+1)].Opt("+BackgroundFF0000")

	Loop {
		if (!doColorPick) {
			picker.Destroy()
			A_Clipboard := Format("{:06X}", scanner.GetPixel(mouseX, mouseY))
			ToolTip()
			break
		}

		MouseGetPos(&mouseX, &mouseY,, &hoveredWinHWND, 2)

		; Scan
		scanner.Update()
		colorHex := scanner.GetPixel(mouseX, mouseY)
		colorRGB := "(" . ((colorHex >> 16) & 0xFF) . ", " . ((colorHex >> 8) & 0xFF) . ", " . (colorHex & 0xFF) . ")"

		ToolTip("#" . Format("{:06X}", colorHex) . "`n" . colorRGB . "`n`n" . "@(" . mouseX . ", " . mouseY . ")`n")

		if (hoveredWinHWND == picker.Hwnd) {
			; Noop
		} else {
			Loop (radius * 2 + 1) {
				y := A_Index
				Loop (radius * 2 + 1) {
					x := A_Index
					picker["Pixel" . x . "_" . y].Opt("+c" . Format("{:x}",scanner.GetPixel(mouseX + x - radius - 1, mouseY + y - radius - 1, true)))
				}
			}
		}

		activeMonitorBB := getActiveMonitorBB()
		monitorWidth := activeMonitorBB[3]
		monitorHeight := activeMonitorBB[4]

		; Reflect across the mouse if near a monitor edge
		if (mouseX > monitorWidth - (radius * 2 + 1) * pixelSize * dpi && mouseX < monitorWidth)
			pickerX := Floor(mouseX - 13 * dpi - (radius * 2 + 1) * pixelSize * dpi)
		else
			pickerX := Floor(mouseX + 13 * dpi)

		if (mouseY < (radius * 2 + 1) * pixelSize * dpi)
			pickerY := Floor(mouseY + 80 * dpi)
		else
			pickerY := Floor(Min(mouseY - pixelSize * (radius * 2 + 1) * dpi, monitorHeight - (radius * 2 + 1) * pixelSize * dpi - 80 * dpi))

		if (!GetKeyState("Shift") || A_Index == 1)
			picker.Show("x" . pickerX . " y" . pickerY . " NA")

		Sleep(1000/30) ; 30 FPS
	}
}

*F18 Up:: {
	global doColorPick := false
}

; +DPI up (+Mouse G8): Advanced autoclicker
+F20:: {
	global autoclick := false
	display := Gui(, "Auto Clicker V2")
	display.Add("Edit", "w50")
	display.Add("UpDown", "vnum Range0-2147483647", 0)
	display.Add("Text", "x+5 yp+5", "回")
	display.Add("Edit", "w50 xm+70 ym")
	display.Add("UpDown", "vdelay Range-1-2147483647", 10)
	display.Add("Text", "xp+55 yp+5", "ms")
	display.Add("Radio", "vleft Checked xm", "Left Click")
	display.Add("Radio", "xp+70", "Right Click")
	display.Add("Checkbox", "vshift xp-70 yp+20", "Shift")
	display.Add("Button", "default", "Start").OnEvent("Click", (ctrl, info) => clicker(display.Submit()), autoclick := true)
	display.Add("Button", "xp+70", "Cancel").OnEvent("Click", (ctrl, info) => display.Submit())
	display.Show()
	WinWaitNotActive(display)
	display.Destroy()
}

; DPI down (Mouse G7)
F14:: {
	windowExe := activateHoveredWindow()
	switch(windowExe) {
		case "UnrealEditor.exe":
			Send("^!w")
		case "Discord.exe", "ms-teams.exe":
			WinClose("ahk_exe " . windowExe)
		default:
			Send("^w")
	}
}

; Tap Mouse Battery (Mouse G9)
; Hold Mouse Battery (Mouse G9)
F15:: {
	windowExe := activateHoveredWindow()
	releasedBeforeTimeout := KeyWait(ThisHotkey, "L T0.2")
	if (releasedBeforeTimeout) {
		switch(windowExe) {
			case "Code.exe":
				Send("{F5}")
			case "explorer.exe":
				Send("!{Up}")
			default:
				Send("^t")
		}
	} else {
		switch(windowExe) {
			case "brave.exe":
				Send("{F5}")
			case "Code.exe":
				Send("^+{F5}")
			case "explorer.exe":
				Send("^n")
		}
		KeyWait(ThisHotkey, "L")
	}
}

; ^v in Explorer: Pastes the image in the clipboard there, if there is any image.
#HotIf WinActive("ahk_exe explorer.exe")
$^v:: {
	didPaste := attemptPasteImage()
	if (!didPaste) {
		Send("^v")
	}
}
#HotIf

; +PrintScreen: Launches Snipping Tool and immediately saves the output to the desktop
+PrintScreen:: {
	clipdata := ClipboardAll()
	A_Clipboard := ""
	Send("{PrintScreen}")
	ClipWait(10, true)
	attemptPasteImage(A_Desktop . "\" . FormatTime(, "yyyy_MM_dd hh_mm_ss") . ".png")
	A_Clipboard := clipdata
}

; Pause/Break: Restart Artemis
Pause:: {
	DetectHiddenWindows(true)
	Run(A_ComSpec . " /c node `"" . A_WorkingDir . "\Artemis Interface\shutdown.js`"",, "Hide")
	WinWaitClose("ahk_exe C:\Program Files\Artemis\Artemis.UI.Windows.exe")
	Run(A_WorkingDir . "\Artemis Interface\Artemis")
	updateRGBProfile()
}

; Volume: Control the respective SteelSeries Sonar Virtual Audio Device (Game, Chat, and Media)
^Volume_Down::
^Volume_Up::
+Volume_Down::
+Volume_Up::
Volume_Down::
Volume_Up:: {
	if (!A_TimeSincePriorHotkey || A_TimeSincePriorHotkey < 15)
		return
	device := getAudioDeviceFromModifier(ThisHotkey)
	setVolume(getVolume(device.id) + (InStr(ThisHotkey, "Up",, 8) ? 2 : -2) * (A_TimeSincePriorHotkey < 100 ? 2 : 1), device.id)
}

; Volume Mute: Mute the respective SteelSeries Virtual Audio Device (Game, Chat, and Media)
^Volume_Mute::
+Volume_Mute::
Volume_Mute:: {
	device := getAudioDeviceFromModifier(ThisHotkey)
	setDeviceMuted(!isDeviceMuted(device.id), device.id)
}

; Stop Media: Show volume control/media player instead
; Pause/Play Media: Show the media volume (in case a different device's audio was changed last)
Media_Stop::
~Media_Play_Pause:: {
	volume := getVolume(AudioDevices.Media)
	setVolume(volume > 90 ? volume - 2 : volume + 2, AudioDevices.Media, false)
	setVolume(volume, AudioDevices.Media)
}

; ScrollLock: Open wanikani and reset the reminder timer
ScrollLock:: {
	global wanikaniLastVisited := FormatTime(, "yyyyMMddHHmm")
	Run("https://www.wanikani.com/")
	global rgbOverlayFlags := clearStringFlag(rgbOverlayFlags, "w")
	updateRGBProfile()
}

;@Ahk2Exe-IgnoreBegin
; Context/Menu Key: Debug purposes
AppsKey:: {
	RunWait("PowerShell -Command `"(Get-PnpDevice -Class 'Bluetooth' -FriendlyName 'WH-1000XM5' | Get-PnpDeviceProperty -KeyName 'DEVPKEY_Device_PowerData').Data > '" . A_WorkingDir . "\Wyvern\debug.txt'`"",, "Hide")
	data := FileRead(A_WorkingDir . "\Wyvern\debug.txt")
	MsgBox(data)
}

; Shift+Context/Menu Key: Debug purposes 2
+AppsKey:: {
	ExitApp()
}

; Ctrl+Context/Menu Key: Debug purposes 3
^AppsKey:: {
	session := Media.GetCurrentSession()

	MsgBox(
		"App with the current session: " . session.SourceAppUserModelId
		. "`nPlayback state: " . Media.PlaybackStatus[session.PlaybackStatus]
		. "`nTitle: " . session.Title
		. "`nArtist: " . session.Artist
	)

	ImageShow(session.Thumbnail.ptr)
}
;@Ahk2Exe-IgnoreEnd

/*@Ahk2Exe-Keep
; Context/Menu Key: Noop
AppsKey:: {
}
*/

pasteFile(path) {
	clipboard := ClipboardAll()
	A_Clipboard := ""
	A_Clipboard := ClipboardAll(FileRead(path, "RAW"))
	Send("^v")
	Sleep(100)
	A_Clipboard := clipboard
}

; Pass an object matching:
; ```
; {delay: number, left: boolean, num: number, shift: boolean}
; ```
; Auto `left`/right clicks with `delay` between `num` number of clicks, while possibly holding `shift`.
clicker(options) {
	global rgbOverlayFlags := autoclick ? setStringFlag(rgbOverlayFlags, "a") : clearStringFlag(rgbOverlayFlags, "a")
	updateRGBProfile()

	key := options.left == 1 ? "Left" : "Right"
	if (options.shift) {
		Send("{Shift Down}")
	}
	while (autoclick && (A_Index <= options.num || options.num == 0)) {
		Click(key)
		Sleep(options.delay)
	}
	if (options.shift) {
		Send("{Shift Up}")
	}
}

; Activates the window the mouse is hovering over
activateHoveredWindow() {
	MouseGetPos(,, &hoveredWinHWND)
	WinActivate(hoveredWinHWND)
	return WinGetProcessName(hoveredWinHWND)
}

clearReplPID(*) {
	global replPID := -1
}

; Asynchronously updates Artemis's local webserver
updateRGBProfile() {
	; TODO: add param which starts artemis if it's closed?
	; TODO: save PID and kill old node process if function is called multiple times before it can update the webserver (prevents race conditions and ensures the most recent process wins)
	Run(A_ComSpec . " /c node `"" . A_WorkingDir . "\Artemis Interface\main.js`" profile=" . (blackout ? "blackout" : rgbProfIndex) . "overlay=" . rgbOverlayFlags,, "Hide")
}

; Schedules alarms throughout the day.
scheduler() {
	global
	local todayAt12AM := FormatTime(, "yyyyMMdd")

	; Notify if it's past 6 am, wanikani hasn't been visited since 12am, and there hasn't been a reminder since 12 am
	; OR if it's past 7pm, wanikani hasn't been visited for at least 5 hours (SRS stage 1 time + an extra hour), and there hasn't been a reminder since 7pm.
	if ((A_Hour >= 6 && DateDiff(wanikaniLastVisited, todayAt12AM, "Minutes") < 0 && DateDiff(wanikaniLastReminder, todayAt12AM, "Minutes") < 0)
		|| (A_Hour >= 19 && DateDiff(A_Now, wanikaniLastVisited, "Hours") >= 4) && DateDiff(wanikaniLastReminder, todayAt12AM . "19", "Minutes") < 0) {
		wanikaniLastReminder := FormatTime(, "yyyyMMddHHmm")
		rgbOverlayFlags := setStringFlag(rgbOverlayFlags, "w")
		SoundPlay(A_WorkingDir . "\Wyvern\ding low.wav")
		updateRGBProfile()
	}
}

; Attempts to paste an image contained in the clipboard data. Returns whether the paste was successful or not
attemptPasteImage(path := "") {
	pngHeaderOffset := 24
	clipall := ClipboardAll()
	; if (Clipboard has PNG header - "‰PNG")
	if (clipall.Size < pngHeaderOffset + 4 || NumGet(clipall, pngHeaderOffset, "Int") != 0x474E5089) {
		return false
	}

	if (!path) {
		hwnd := WinExist("A")
		wClass := WinGetClass("ahk_id " . hwnd)
		if (!RegExMatch(wClass, "Progman|WorkerW|(Cabinet|Explore)WClass")) {
			return false
		}

		; No clue what's happening, but it grabs the full path to the active Explorer window
		shellFolderView := ""
		shellWindows := ComObject("Shell.Application").Windows
		if (RegExMatch(wClass, "Progman|WorkerW")) {
			shellFolderView := shellWindows.Item(ComValue(VT_UI4 := 0x13, SWC_DESKTOP := 0x8)).Document
		} else {
			for (window in shellWindows) {
				if (window.HWND && window.Document) {
					shellFolderView := window.Document
					break
				}
			}
		}

		path := shellFolderView.Folder.Self.Path . "\" . FormatTime(, "yyyy_MM_dd hh_mm_ss") . ".png"
	}

	try {
		; Write the raw data starting from the PNG header (offset 36), ending at the specified size (grabbed from offset 32)
		file := FileOpen(path, "w").RawWrite(clipall.Ptr + pngHeaderOffset, NumGet(clipall, pngHeaderOffset - 4, "Int"))
	} catch {
		MsgBox("Can't paste image into UAC protected folder`n(Or maybe some other error occurred idk)")
		return false
	}
	return true
}

; Returns [left, top, right, bottom] coords of the "active" monitor (whichever the active window is on)
getActiveMonitorBB() {
	WinGetPos(&winX, &winY, &winWidth, &winHeight, "A")
	static numMonitors := MonitorGetCount()
	static monitorBBs := []
	static retrievedMonitorData := false

	Loop (numMonitors) {
		if (!retrievedMonitorData) {
			MonitorGetWorkArea(A_Index, &monitorBBLeft, &monitorBBTop, &monitorBBRight, &monitorBBBottom)

			if (numMonitors > 1)
				monitorBBRight -= 10

			monitorBBs.Push([monitorBBLeft, monitorBBTop, monitorBBRight, monitorBBBottom])
		}

		if (winX >= monitorBBs[A_Index][1] && winX < monitorBBs[A_Index][3]) {
			; MsgBox(winX)
			retrievedMonitorData := true
			return monitorBBs[A_Index]
		}
	}

	; Return primary monitor BB if can't detect whether the active window is on a specific monitor
	retrievedMonitorData := true
	return monitorBBs[MonitorGetPrimary()]
}

; Returns the current DPI
getMouseDPI() {
	static dpi := 1
	try {
		dpi := RegRead("HKCU\Control Panel\Desktop\WindowMetrics", "AppliedDPI")
	} catch {
		dpi := 1
	}
	return dpi / 96
}

setStringFlag(str, flag) {
	if (!InStr(str, flag, true)) {
		str .= flag
	}
	return str
}

clearStringFlag(str, flag) {
	pos := InStr(str, flag, true)
	if (pos) {
		str := StrReplace(str, flag, "", true)
	}
	return str
}

xorStringFlag(str, flag) {
	pos := InStr(str, flag, true)
	if (pos) {
		str := StrReplace(str, flag, "", true)
	} else {
		str .= flag
	}
	return str
}

testStringFlag(str, flag) {
	return InStr(str, flag, true)
}

getAudioDeviceFromId(id) {
	return {id: id, name: getDeviceNickname(id)}
}

getAudioDeviceFromModifier(modifier) {
	device := ""

	switch (SubStr(modifier, 1, 1)) {
		case "^":
			device := AudioDevices.Game
		case "+":
			device := AudioDevices.Chat
		case "V":
			device := AudioDevices.Media
	}

	return {id: device, name: getDeviceNickname(device)}
}

getDeviceNickname(id) {
	for (key, value in AudioDevices.OwnProps()) {
		if (value == id) {
			return key
		}
	}
	return ""
}

displayVolume(message := "") {
	; I have absolutely no clue what any of this DLL/ComObject nonsense does, but thanks random redditor!
	static o := ComObject("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{00000000-0000-0000-C000-000000000046}")
	static q := ComObjQuery(o, "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}", "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}")
	DllCall(NumGet(NumGet(q.Ptr, 0, "UPtr") + 3 * A_PtrSize, 0, "UPtr"), "Ptr", q, "Int", 0, "UInt", 0)

	CoordMode("ToolTip", "Screen")
	ToolTip(message, 1385, 1390)
	SetTimer(() => ToolTip(), -2000)
}

getAudioStatus(device) {
	return device.name . (isDeviceMuted(device.id) ? " x " : " - ") . Round(getVolume(device.id))
}

getVolume(deviceId) {
	try {
		return SoundGetVolume(, deviceId)
	} catch {
		return SoundGetVolume()
	}
}

setVolume(volume, deviceId, display := true) {
	try {
		SoundSetVolume(Round(volume / 2) * 2,, deviceId)
	} catch {
		SoundSetVolume(Round(volume / 2) * 2)
	}
	if (display) {
		displayVolume(getAudioStatus(getAudioDeviceFromId(deviceId)))
	}
}

isDeviceMuted(deviceId) {
	try {
		return SoundGetMute(, deviceId)
	} catch {
		return SoundGetMute()
	}
}

setDeviceMuted(isMuted, deviceId, display := true) {
	try {
		SoundSetMute(isMuted,, deviceId)
	} catch {
		SoundSetMute(true)
	}
	if (display) {
		displayVolume(getAudioStatus(getAudioDeviceFromId(deviceId)))
	}
}

; Toggles the following settings:
; - Extend <-> Internal Monitor
; - HDR On <-> Off
; - 1440p <-> 1080p
toggleRDPDisplaySettings(*) {
	global rdpDisplayMode := !rdpDisplayMode

	Send("#!b") ; Toggle HDR
	if (rdpDisplayMode) {
		; Set display to main monitor only
		RunWait("C:\Windows\System32\DisplaySwitch.exe /internal")
		setDisplayResolution(1920, 1080)

		A_TrayMenu.Insert("5&", "Prev Virtual Desktop", (*) => Send("^#{Left}"))
		A_TrayMenu.Insert("6&", "Next Virtual Desktop", (*) => Send("^#{Right}"))
	} else {
		; Extend displays
		RunWait("C:\Windows\System32\DisplaySwitch.exe /extend")
		setDisplayResolution(2560, 1440)

		A_TrayMenu.Delete("6&")
		A_TrayMenu.Delete("5&")
	}
}

; Heck if I know
setDisplayResolution(width, height) {
	DM_PELSWIDTH := 0x80000
	DM_PELSHEIGHT := 0x100000
	DM_BITSSPERPEL := 0x40000

	DEVMODE := Buffer(156, 0)
	NumPut("uint", 156, DEVMODE, 36)
	DllCall("EnumDisplaySettingsA", "uint", 0, "uint", -1, "ptr", DEVMODE)

	NumPut("uint", width, DEVMODE, 108)
	NumPut("uint", height, DEVMODE, 112)
	NumPut("uint", 32, DEVMODE, 104) ; 32-bit color depth
	NumPut("uint", DM_PELSWIDTH | DM_PELSHEIGHT | DM_BITSSPERPEL, DEVMODE, 40)

	if (DllCall("ChangeDisplaySettingsA", "ptr", DEVMODE, "uint", 0) != 0)
		MsgBox("Failed to set display resolution!")
}

; Map right modifier keys to left ones
#HotIf rdpDisplayMode
RAlt::LWin
RControl::LAlt
#HotIf

; Open VSCode to edit Wyvern
editWyvern(*) {
	Run("cmd /c cd `"" . A_WorkingDir . "\Wyvern`" & code .",, "Hide")
}