/************************************************************************
 * @description Automatically saves and loads data from a file
 * @author Bedrockbreaker
 * @date 2023/07/23
 * @version 1.0.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

OnExit(Serializer.SaveData)

class Serializer {
	static saveFile := A_MyDocuments . "\AutoHotkey\savedata\" . SubStr(A_ScriptName, 1, -4) . ".txt"
	static data := Serializer.Deserialize()

	; Pass a `&VarRef` into `ref` in order to track its value
	static Serialized(key, ref, fallback) { ; TODO: add revitalizer function argument?
		if (Serializer.data.Has(key)) {
			%ref% := Serializer.data[key]
		} else {
			%ref% := fallback
		}
		Serializer.data[key] := ref
		return %ref%
	}

	static Deserialize() {
		data := Map() ; Local variable
		
		if (!FileExist(Serializer.saveFile)) {
			return data ; Fail early
		}

		loop read Serializer.saveFile {
			key := ""
			value := ""
			undefined := true
			lineNumber := A_Index

			loop parse A_LoopReadLine, ":", A_Space A_Tab {
				if (A_Index == 1) {
					key := A_LoopField ; Yes, apparently key can be basically any string for a map key
				} else {
					lineText := A_LoopField
					terms := [
						; Parse double-quoted string
						["^`"((?:[^\`"]|\.)*)`"$", (str) => Serializer.Unstringify(str)],
						; Parse number
						["^(-?\d*\.?\d+)$", (str) => Number(str)]
					]
					for (pair in terms) {
						if (RegExMatch(A_LoopField, pair[1])) {
							value := pair[2](RegExReplace(A_LoopField, pair[1], "$1"))
							undefined := false
						}
					}
					if (undefined) {
						throw(Error("Unable to parse value", -1, Serializer.saveFile . "`n" . SubStr("00" . String(lineNumber), -3) . ": " . A_LoopReadLine))
					}
				}
				; Silently fail on lines which don't have a colon
				; TODO: Fix?
			}

			if (!undefined) {
				data[key] := value
			}
		}
		return data
	}

	static SaveData(*) {
		file := FileOpen(Serializer.saveFile, "w")
		for (key, refOrVal in Serializer.data) {
			file.WriteLine(key . ":" . Serializer.stringify(refOrVal is VarRef ? %refOrVal% : refOrVal))
		}
		file.Close()
	}

	static Delete(key) {
		Serializer.data.Delete(key)
	}

	static Stringify(value) {
		switch Type(value) {
			case "String":
				value := StrReplace(value, "\", "\\")
				value := StrReplace(value, "`n", "\n", true)
				value := StrReplace(value, "`r", "\r", true)
				value := RegExReplace(value, "\0", "") ; Eat all null characters
				return "`"" . value "`""
			case "Integer", "Float":
				return value
			default:
				throw(Error("Unable to serialize value", 0, value))
		}
	}

	; Technically, all this does is undo the Stringify() function. It still returns a string
	static Unstringify(str) {
		str2 := ""
		length := StrLen(str)
		position := 1

		for (index, section in StrSplit(str, ["\\", "\n", "\r"])) {
			position += StrLen(section) + 2
			str2 .= section
			if (position == length + 3) {
				break
			}
			switch (SubStr(str, position - 2, 2)) {
				case "\\":
					str2 .= "\"
				case "\n":
					str2 .= "`n"
				case "\r":
					str2 .= "`r"
				default:
					throw(Error("what the heck"))
			}
		}

		return str2
	}
}