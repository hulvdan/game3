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
# * clone repo
# * open nvim inside it
git remote add template https://github.com/Hulvdan/godot-template.git
git fetch template
git merge template
git push
uv python install 3.11
uv sync
pre-commit install
pre-commit install --install-hooks
git submodule update --init --recursive
cd addons
cd godot-yaml
scons target=template_debug
scons target=template_release
scons platform=windows target=template_debug
scons platform=windows target=template_release
scons platform=web target=template_release
cd ..
cd ..
# * I checked out master branch of godot-template in lazygit
    -> renamed it into `template` in github desktop
# * Open Godot -> Project Settings -> Change name
```
