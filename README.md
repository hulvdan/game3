# [godot-template](https://github.com/Hulvdan/godot-template)

## Setting Up The Machine

- Download godot source to ..\godot-4.6-stable
- Inside of it execute:
  ```
  python misc\scripts\install_d3d12_sdk_windows.py
  ```
- Make godot.exe, godot_console.exe accessible
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
- (for proto)
  ```
  go install github.com/mariomakdis/proto-renumber@v1.1.0
  ```

## Bootstrap A New Repo

```
# * Create a repo in GitHub
# * Clone it
git remote add template https://github.com/hulvdan/godot-template.git
git fetch template
git merge template
git push
uv sync
uv run pre-commit install
uv run pre-commit install --install-hooks
# * Open Godot -> Project Settings -> Change name
```

<!-- [[[cog
from pathlib import Path
for filepath in sorted(Path("docs").glob("*.png"), key=lambda x: -int(x.stem)):
  print(f"![](docs/{filepath.name})")
cog]]] -->
![](docs/18.png)
![](docs/17.png)
![](docs/16.png)
![](docs/15.png)
![](docs/14.png)
![](docs/13.png)
![](docs/12.png)
![](docs/11.png)
![](docs/10.png)
![](docs/9.png)
![](docs/8.png)
![](docs/7.png)
![](docs/6.png)
![](docs/5.png)
![](docs/4.png)
![](docs/3.png)
![](docs/2.png)
![](docs/1.png)
<!-- [[[end]]] -->
