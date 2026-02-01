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
  - Web local testing
    ```
    npm install -g serve
    ```

## Bootstrap A New Repo

```
# * Create a repo in GitHub
# * Add ruleset to protect default branch in GitHub (disable deletions + disable force pushes)
# * Replace here `NEWGAME` with github-name of the repo
mkdir NEWGAME
cd NEWGAME
git init
git remote add template https://github.com/Hulvdan/godot-template.git
git fetch template
git rebase template/template
uv python install 3.11
uv sync
pre-commit install
pre-commit install --install-hooks
git remote add "origin" https://github.com/Hulvdan/NEWGAME.git
# Set alias in Github Desktop
```
