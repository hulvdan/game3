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
            Send, {f8}
            break
        }
    }

    sleep 500

    WinGet, id, List
    Loop, %id% {
        this_id := id%A_Index%
        WinGetTitle, title, ahk_id %this_id%
        WinGet, exe, ProcessName, ahk_id %this_id%
        if RegExMatch(exe, "Godot_.*_win64\.exe") {
            WinActivate, ahk_id %this_id%
            Send, {ctrl down}s{ctrl up}
            sleep 300
            Send, {f5}
            break
        }
    }

Default:
    MsgBox, Invalid Argument, %command%
    Exit, 1
}

