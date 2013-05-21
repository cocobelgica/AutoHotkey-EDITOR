#Include <menu>

class EDITOR
{

	static _ := EDITOR.__init__()
	static exec := EDITOR.__main__()

	class __PROPERTIES__ {

		__Call(target, name, params*) {
			if !(name ~= "i)^(base|__Class)$") {
				return ObjHasKey(this, name)
				       ? this[name].(target, params*)
				       : this.__.(target, name, params*)
			}
		}
	}

	__New() {
		return false
	}

	__main__() {
		this.menu := this.__MENU__.__main__()
		Gui, New, +LastFound +Resize +LabelEDITOR_
		this.hwnd := WinExist()
		Gui, Margin, 0, 0
		Gui, Color, White
		Gui, Font, s9, Consolas
		Gui, Add, Edit, w600 r50 HwndhEdit -Wrap +HScroll WantTab T16
		this.hEdit := hEdit
		Gui, Menu, % this.menu.MenuBar.name
		Gui, Show,, Untitled - EDITOR
		return
	}

	__open__(file) {
		if !(fileObj := FileOpen(file, "rw"))
			throw Exception("ERROR! Cannot open file: " file, -1)
		this.text := fileObj.Read() , this.title := file
		fileObj.Close()
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
			DllCall("SetWindowPos"
			      , "Ptr", this.hEdit
			      , "Ptr", 0
			      , "UInt", 0
			      , "UInt", 0
			      , "UInt", A_GuiWidth
			      , "UInt", A_GuiHeight
			      , "UInt", 0x0010|0x0002|0x0004) ; SWP_NOACTIVATE|SWP_NOMOVE|SWP_NOZORDER
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
			<EDITOR_Menu>
			<Menu name="MenuBar">
			<Item name="File" target=":File"/>
			<Item name="Edit" target=":Edit"/>
			<Item name="Tools" target=":Tools"/>
			<Item name="Format" target=":Format"/>
			<Item name="About" target=":About"/>
			</Menu>
			<Menu name="File">
			<Item name="New File" target="EDITOR.__MENU__.__handler__"/>
			<Item name="Open File`tCtrl+O" target="EDITOR.__MENU__.__handler__"/>
			<Item name="Save" target="EDITOR.__MENU__.__handler__"/>
			<Item/>
			<Item name="Exit" target="EDITOR.__MENU__.__handler__"/>
			</Menu>
			<Menu name="Edit">
			<Item name="Undo`tCtrl+Z" target="EDITOR.__MENU__.__handler__"/>
			<Item/>
			<Item name="Copy`tCtrl+C" target="EDITOR.__MENU__.__handler__"/>
			<Item name="Cut`tCtrl+X" target="EDITOR.__MENU__.__handler__"/>
			<Item name="Paste`tCtrl+V" target="EDITOR.__MENU__.__handler__"/>
			</Menu>
			<Menu name="Tools">
			<Item name="Run`tF5" target="EDITOR.__MENU__.__handler__"/>
			</Menu>
			<Menu name="Format">
			<Item name="Read Only" target="EDITOR.__MENU__.__handler__"/>
			<Item name="Word Wrap" target="EDITOR.__MENU__.__handler__"/>
			</Menu>
			<Menu name="About">
			<Item name="Help`tF1" target="EDITOR.__MENU__.__handler__"/>
			<Item/>
			<Item name="About" target="EDITOR.__MENU__.__handler__"/>
			</Menu>
			</EDITOR_Menu>
			)
			return MENU_from(src)
		}

		__handler__() {
			
			if (this.menu = EDITOR.menu.File) {
				if (this = EDITOR.menu.File.item["Open File`tCtrl+O"]) {
					Gui, % EDITOR.hwnd ":+OwnDialogs"
					FileSelectFile, file,, % A_WorkingDir
					if !ErrorLevel
						EDITOR.__open__(file)
				}
				
				if (this = EDITOR.menu.File.item.Save) {
					
				}
				
				if (this = EDITOR.menu.File.item.Exit)
					EDITOR.__handler__("Close")
			}

			if (this.menu = EDITOR.menu.Edit) {
				if (this = EDITOR.menu.Edit.item["Undo`tCtrl+Z"])
					EDITOR.__undo()

				if (this = EDITOR.menu.Edit.item["Copy`tCtrl+C"])
					EDITOR.__copy()

				if (this = EDITOR.menu.Edit.item["Cut`tCtrl+X"])
					EDITOR.__cut()

				if (this = EDITOR.menu.Edit.item["Paste`tCtrl+V"])
					EDITOR.__paste()
			}
			
			if (this.menu = EDITOR.menu.Tools) {
				if (this = EDITOR.menu.Tools.item["Run`tF5"])
					EDITOR.__run__(EDITOR.text)
			}
			
			if (this.menu = EDITOR.menu.Format) {
				if (this = EDITOR.menu.Format.item["Read Only"]) {
					EDITOR.readonly := !EDITOR.readonly
					this.check := EDITOR.readonly
				}

				if (this = EDITOR.menu.Format.item["Word Wrap"]) {
					this.check := 2
					EDITOR.wordwrap := this.check
				}
			}
			
			if (this.menu = EDITOR.menu.About) {
				if (this = EDITOR.menu.About.item["Help`tF1"]) {
					SplitPath, A_AhkPath,, dir
					Run, % dir "\AutoHotkey.chm"
				}
				
				if (this = EDITOR.menu.About.item.About)
					MsgBox, AHK Editor
			}
		}
	
	}

	__init__() {
		static init

		if init ; call once
			return
		EDITOR.base := EDITOR.__BASE__
		init := true
		return []
	}

	class __BASE__
	{

		__Set(key, value, p*) {
			
			if (key = "text") {
				; WM_SETTEXT:=0xC
				SendMessage, 0xC, 0, &value,, % "ahk_id " this.hEdit
			}

			if (key = "title") {
				isVisible := DllCall("IsWindowVisible", "Ptr", this.hwnd)
				Gui, % this.hwnd ":Show"
				   , % isVisible ? "" : "Hide"
				   , % value
			}

			if (key = "readonly") {
				; EM_SETREADONLY:=0xCF
				SendMessage, 0xCF, % value, 0,, % "ahk_id " this.hEdit
			}

			if (key = "wordwrap") {
				text := this.text , sel := this.sel
				GuiControlGet, p, % this.hwnd ":Pos", % this.hEdit
				vpos := DllCall("GetScrollPos", "Ptr", this.hEdit, "Int", 1) ; SB_VERT:=1

				; Should I use 2 Edit controls instead?
				DllCall("DestroyWindow", "Ptr", this.hEdit)
				
				Gui, % this.hwnd ":Add"
				   , Edit
				   , % "x" pX " y" pY " w" pW " h" pH " HwndhEdit WantTab T16"
				     . (value ? "" : " -Wrap +HScroll")
				
				this.hEdit := hEdit , this.text := text
				ControlFocus,, % "ahk_id " this.hEdit
				this.sel := {startpos:sel.startpos, endpos:sel.startpos}
				if (sel.startpos <> sel.endpos)
					this.sel := {startpos:sel.startpos, endpos:sel.endpos}
				if vpos
					SendMessage, 0x00B6, 0, vpos,, % "ahk_id " this.hEdit ; EM_LINESCROLL
			}

			if (key ~= "i)^sel(ection|$)$") {
				SendMessage, 0x0B1 ; EM_SETSEL
				           , % value.startpos
				           , % value.endpos,
				           , % "ahk_id " this.hEdit
			}

			return this._[key] := value
		}

		class __Get extends EDITOR.__PROPERTIES__
		{

			__(k, p*) {
				if this._.HasKey(k)
					return this._[k, p*]
			}

			title(p*) {
				WinGetTitle, title, % "ahk_id " this.hwnd
				return title
			}

			text(p*) {
				static WM_GETTEXTLENGTH := 0xE , WM_GETTEXT := 0xD

				SendMessage, WM_GETTEXTLENGTH, 0, 0,, % "ahk_id " this.hEdit
				len := ErrorLevel
				VarSetCapacity(text, len*(A_IsUnicode ? 2 : 1)+1, 0)
				SendMessage, WM_GETTEXT, len+1, &text,, % "ahk_id " this.hEdit
				return text
			}

			readonly(p*) {
				static ES_READONLY := 0x800
				
				ControlGet, style, Style,,, % "ahk_id " this.hEdit
				return (style & ES_READONLY) ? true : false
			}

			sel(p*) {
				static EM_GETSEL := 0xB0
				
				VarSetCapacity(ssp, 4, 0) ; StartSelPos
				VarSetCapacity(esp, 4, 0) ; EndSelPos
				SendMessage, EM_GETSEL, &ssp, &esp,, % "ahk_id " this.hEdit
				sel := {startpos:NumGet(ssp), endpos:NumGet(esp)}
				return p.MinIndex() ? sel[p.1] : sel
			}

			hEdit__(p*) {
				GuiControlGet, hEdit, % this.hwnd ":Hwnd", Edit1
				return hEdit
			}
		
		}

		__Call(method, p*) {
			if (method ~= "i)^__(undo|copy|cut|paste)$")
				return this.__uccp__(SubStr(method, 3), p*)
		}

		__uccp__(m, p*) { ; Undo|Copy|Cut|Paste
			static action := {undo:0xC7, copy:0x301, cut:0x300, paste:0x302}
			SendMessage, % action[m], 0, 0,, % "ahk_id " this.hEdit
		}
	
	}

}
