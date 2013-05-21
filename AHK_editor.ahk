#Include <menu>

class EDITOR
{

  static __ := EDITOR.__main__()

	__main__() {
		this.menu := this.__MENU__.__main__()
		Gui, New, +LastFound +Resize +LabelEDITOR_
		this.hwnd := WinExist()
		Gui, Margin, 0, 0
		Gui, Font, s9, Consolas
		Gui, Add, Edit, w700 r25 HwndhEdit -Wrap WantTab T16
		this.hEdit := hEdit
		Gui, Menu, % this.menu.MenuBar.name
		Gui, Show
		return
	}

	__run__(code, pipename:="") {
		if (pipename == "")
			pipename := "AHK" A_TickCount

		for a, b in ["__PIPE_GA_", "__PIPE_"]
			%b% := DllCall("CreateNamedPipe"
			             , "Str", "\\.\pipe\" pipename
			             , "UInt", 2
			             , "Uint", 0
			             , "UInt", 255
			             , "UInt", 0
			             , "UInt", 0
			             , "Ptr", 0
			             , "Ptr", 0)
	
		if (__PIPE_ == -1 || __PIPE_GA_ == -1)
			return false
		
		Run, %A_AhkPath% "\\.\pipe\%pipename%",, UseErrorLevel HIDE, PID
		if ErrorLevel
			MsgBox, 262144, ERROR
			, % "Could not open file:`n" __AHK_EXE_ """\\.\pipe\" pipename """"
	
		DllCall("ConnectNamedPipe", "Ptr", __PIPE_GA_, "Ptr", 0)
		DllCall("CloseHandle", "Ptr", __PIPE_GA_)
		DllCall("ConnectNamedPipe", "Ptr", __PIPE_, "Ptr", 0)
		
		Script := (A_IsUnicode ? Chr(0xfeff) : (Chr(239) . Chr(187) . Chr(191))) code
		if !DllCall("WriteFile"
		          , "Ptr", __PIPE_
		          , "Str", Script
		          , "UInt", (StrLen(Script)+1)*(A_IsUnicode ? 2 : 1)
		          , "UInt*", 0
		          , "Ptr", 0)
			return A_LastError
		DllCall("CloseHandle", "Ptr", __PIPE_)
		return PID
	}

	__handler__(event) {
		if (event = "Close") {
			Gui, % this.hwnd ":Destroy"
			SetTimer, EDITOR_exit, -1
		}
		if (event = "Size")
			GuiControl, % this.hwnd ":Move", % this.hEdit, % "w" A_GuiWidth " h" A_GuiHeight
		return
		EDITOR_Close:
		EDITOR_Size:
		EDITOR.__handler__(SubStr(A_ThisLabel, StrLen("EDITOR_")+1))
		return
		EDITOR_Exit:
		ExitApp
	}

	class __MENU__
	{
		
		__main__() {
			src =
			(LTrim
			<MENU_Class>
			<Menu name="MenuBar">
			<Item name="Tools" target=":Tools"/>
			<Item name="About" target=":About"/>
			</Menu>
			<Menu name="Tools">
			<Item name="Run`tF5" target="EDITOR.__MENU__.__handler__"/>
			<Item name="Help`tF1" target="EDITOR.__MENU__.__handler__"/>
			</Menu>
			<Menu name="About">
			<Item name="About" target="EDITOR.__MENU__.__handler__"/>
			</Menu>
			</MENU_Class>
			)
			return MENU_from(src)
		}

		__handler__() {
			if (this.menu = EDITOR.menu.Tools) {
				if (this = EDITOR.menu.Tools.item["Run`tF5"]) {
					GuiControlGet, code, % EDITOR.hwnd ":", % EDITOR.hEdit
					EDITOR.__run__(code)
				}
				if (this = EDITOR.menu.Tools.item["Help`tF1"]) {
					SplitPath, A_AhkPath,, dir
					Run, % dir "\AutoHotkey.chm"
				}
			}
			if (this.menu = EDITOR.menu.About) {
				if (this = EDITOR.menu.About.item.About)
					MsgBox, AHK Editor
			}
		}
	
	}

}
