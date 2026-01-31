# godot-template

## Setting Up The Machine

- Download godot source to c:\Users\user\dev\home\godot-4.6-stable
- Inside of it execute:
  ```
  python misc\scripts\install_d3d12_sdk_windows.py
  ```
- Create godot.exe, godot_console.exe in PATH
  ```
  mklink c:\Users\user\Programs\PATH\godot.exe c:\Users\user\Programs\godot\Godot_v4.6-stable_win64.exe
  mklink c:\Users\user\Programs\PATH\godot_console.exe c:\Users\user\Programs\godot\Godot_v4.6-stable_win64_console.exe
  ```
- Optional. For nvim:
  - Download and put in PATH
    https://github.com/GDQuest/GDScript-formatter/releases
- Optional. For local testing
  ```
  npm install -g serve
  ```

## Quickstart

TODO copy from emberveil2

```
uv sync
pre-commit --install
pre-commit --install-hooks
```
