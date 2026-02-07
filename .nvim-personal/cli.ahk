SendMode Input
SetKeyDelay, 150, 150

command := A_Args[1]
arg1 := A_Args[2]

switch command, 0
{

case "run_in_godot":
    if WinExist(ahk_exe godot.exe) {
        ControlSend,, {f8}{f5}, ahk_exe godot.exe
    }

Default:
    MsgBox, Invalid Argument, %command%
    Exit, 1
}

