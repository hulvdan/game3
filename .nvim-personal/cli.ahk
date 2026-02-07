SendMode Input
SetKeyDelay, 150, 150

command := A_Args[1]
arg1 := A_Args[2]

switch command, 0
{

case "run_in_godot":
    WinGet, id, List
    Loop, %id% {
        this_id := id%A_Index%
        WinGetTitle, title, ahk_id %this_id%
        WinGet, exe, ProcessName, ahk_id %this_id%
        if RegExMatch(exe, "Godot_.*_win64\.exe") {
            WinActivate, ahk_id %this_id%
            ControlSend,, {f8}, ahk_id %this_id%
            break
        }
    }

    sleep 300

    WinGet, id, List
    Loop, %id% {
        this_id := id%A_Index%
        WinGetTitle, title, ahk_id %this_id%
        WinGet, exe, ProcessName, ahk_id %this_id%
        if RegExMatch(exe, "Godot_.*_win64\.exe") {
            WinActivate, ahk_id %this_id%
            ControlSend,, {f5}, ahk_id %this_id%
            break
        }
    }

Default:
    MsgBox, Invalid Argument, %command%
    Exit, 1
}

