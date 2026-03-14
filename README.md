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
- Download buf and place it into PATH
  https://github.com/bufbuild/buf/releases/tag/v1.65.0
- Download and put in PATH
  https://github.com/GDQuest/GDScript-formatter/releases
- (for stylua pre-commit) Install rust
  https://rust-lang.org/tools/install/
- (for proto) go install github.com/mariomakdis/proto-renumber@v1.1.0
- Optional. For web local testing:
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
uv run pre-commit install
uv run pre-commit install --install-hooks
# * I checked out master branch of godot-template in lazygit
    -> renamed it into `template` in github desktop
# * Open Godot -> Project Settings -> Change name
```

<!-- [[[cog
from pathlib import Path
for filepath in reversed(list(Path("docs").glob("*.png"))):
  print(f"![](docs/{filepath.name})")
cog]]] -->
![](docs/4.png)
![](docs/3.png)
![](docs/2.png)
![](docs/1.png)
<!-- [[[end]]] -->
