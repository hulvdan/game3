## Imports
import os
import shlex
import shutil
import zipfile
from collections import Counter
from pathlib import Path

import bf_lib as bf
import bf_swatch
import colornames
from bf_game import *  # noqa
from bf_glib import do_generate, get_sounds_that_reaper_would_export
from bf_typer import app, command, global_timing_manager_instance, timing

##


def enrich_game_settings_colors() -> None:  ##
  palette_colors_with_darkened_ones = ["#ffffff", "#000000"]
  bf.game_settings.computed_color_names.append("WHITE")
  bf.game_settings.computed_color_names.append("BLACK")

  for i in range(len(bf.game_settings.colors)):
    color = bf.game_settings.colors[i]
    if color in ("#000000", "#ffffff"):
      continue
    darkened_color = bf.rgb_floats_to_hex(
      bf.transform_color(
        bf.hex_to_rgb_floats(color), saturation_scale=1.3, value_scale=0.52
      )
    )
    palette_colors_with_darkened_ones.append(color)
    palette_colors_with_darkened_ones.append(darkened_color)
    name = colornames.find(color)
    bf.game_settings.computed_color_names.append(name)
    bf.game_settings.computed_color_names.append(f"{name} Dark")
    bf.game_settings.colors.append(darkened_color)

  bf.game_settings.colors = palette_colors_with_darkened_ones
  ##


@timing
def make_web_build_archive(zip_path: Path, where_godot_exported_folder: Path) -> None:  ##
  with zipfile.ZipFile(zip_path, "w") as archive:
    for filepath in where_godot_exported_folder.glob("*"):
      archive.write(filepath, filepath.name)
  ##


@timing
def do_profile(godot_platform: str) -> None:  ##
  bf.run_command(
    [
      "uv",
      "run",
      "scons",
      "target=template_release",
      f"platform={godot_platform}",
      f"profile={bf.PROJECT_DIR}/src/engine/profile_{godot_platform}.py",
      f"build_profile={bf.PROJECT_DIR}/src/engine/profile.gdbuild",
    ],
    cwd=bf.PROJECT_DIR / "../godot-4.6-stable",
  )
  ##


@timing
def do_godot_lint() -> None:  ##
  bf.run_command("gdlint src", timeout_seconds=5)
  ##


@timing
def do_godot_check_errors() -> None:  ##
  bf.run_command("godot --quit --headless --check-only --debug", timeout_seconds=5)
  ##


@timing
def do_build(
  target: bf.BuildTarget, platform: bf.BuildPlatform, build_type: bf.BuildType
) -> None:  ##
  build_id = (target, platform, build_type)
  assert build_id in bf.ALLOWED_BUILDS, "{} is not allowed!".format(build_id)

  out_folder = Path(".export") / f"{platform}_{build_type}"

  bf.recursive_mkdir(out_folder)
  bf.run_command(f"del /f/s/q {out_folder}")

  exe_name: str | None = None
  if platform.is_web():
    exe_name = "index.html"
    async_data_pck_path = out_folder / "async_data.pck"
    try:
      bf.run_command(
        rf"godot --quit --headless --export-pack web_async_data {out_folder}/async_data.pck",
        timeout_seconds=30,
      )
    except Exception:
      assert async_data_pck_path.exists()
  elif platform == bf.BuildPlatform.Win:
    exe_name = "game.exe"
  else:
    assert False

  try:
    bf.run_command(
      rf"godot --quit --headless --export-{build_type} {platform} {out_folder}/{exe_name}",
      timeout_seconds=30,
    )
  except Exception:
    for f in ("index.pck", "index.html", "index.wasm"):
      assert (out_folder / f).exists()

  if platform.startswith("web"):
    shutil.copy("assets/GameAnalytics.min.js", out_folder)

  shutil.make_archive(base_name=str(out_folder), format="zip", root_dir=out_folder)
  ##


@timing
def do_test() -> None:  ##
  bf.run_command(
    "godot --no-header --headless -s addons/gut/gut_cmdln.gd -gdir src/tests -gexit -gprefix test -gdisable_colors",
    timeout_seconds=5,
  )
  ##


# def do_stop_debugger_ahk() -> None: ##
#     bf.run_command(r"autohotkey .nvim-personal\cli.ahk stop_debugger")
#     ##


def do_activate_godot_ahk() -> None:  ##
  bf.run_command(r"autohotkey .nvim-personal\cli.ahk activate")
  ##


def do_run_in_godot_ahk() -> None:  ##
  bf.run_command(r"autohotkey .nvim-personal\cli.ahk run_in_godot")
  ##


# @command
# def cog():  ##
#     files_to_cog_and_format = [
#         *SRC_DIR.rglob("*.cpp"),
#         *SRC_DIR.rglob("*.h"),
#         *(Path("codegen") / "cog").rglob("*.cpp"),
#         *(Path("codegen") / "cog").rglob("*.h"),
#     ]
#
#     for filepath in files_to_cog_and_format:
#         print(f"Processing {filepath}...")
#         assert filepath in files_to_cog_and_format
#
#         with open(filepath, encoding="utf-8") as in_file:
#             data = in_file.read()
#
#         if ("[[" + "[cog") in data:  # NOTE: string is split for cog.
#             result = subprocess.run(
#                 ".venv/Scripts/cog.exe -n UTF-8 -U -",
#                 check=True,
#                 input=data,
#                 stdout=subprocess.PIPE,
#                 text=True,
#                 encoding="utf-8",
#             )
#
#             result = subprocess.run(
#                 "clang-format",
#                 check=True,
#                 input=result.stdout,
#                 encoding="utf-8",
#                 text=True,
#                 shell=True,
#                 capture_output=True,
#             )
#
#             with open(filepath, "w", encoding="utf-8", newline="\n") as out_file:
#                 out_file.write(result.stdout)
#
#         else:
#             subprocess.run(
#                 f"clang-format -i {filepath}",
#                 check=True,
#                 input=data,
#                 encoding="utf-8",
#                 text=True,
#                 shell=True,
#             )
#   ##


@command
def profiles() -> None:  ##
  godot_platforms = {x.split("_", 1)[0] for x in bf.BuildPlatform}
  for x in godot_platforms:
    if 0 and x == "windows":
      continue
    do_profile(x)
  ##


@command
def codegen(platform: bf.BuildPlatform, build_type: bf.BuildType):  ##
  do_generate(platform, build_type)
  do_activate_godot_ahk()
  ##


@command
def codegen_and_lint(platform: bf.BuildPlatform, build_type: bf.BuildType):  ##
  do_generate(platform, build_type)
  do_godot_lint()
  do_godot_check_errors()
  do_activate_godot_ahk()
  ##


@command
def build(
  target: bf.BuildTarget, platform: bf.BuildPlatform, build_type: bf.BuildType
):  ##
  do_generate(platform, build_type)
  do_godot_lint()
  do_godot_check_errors()
  do_build(target, platform, build_type)
  ##


# @command
# def build_all_and_test():  ##
#
#     test()
#     for target, platform, build_type in bf.ALLOWED_BUILDS:
#         if target != bf.BuildTarget.game:
#             continue
#         do_generate(platform, build_type)
#         build(bf.BuildTarget.game, platform, build_type)
#         bf._glib = None
#     ##


@command
def run():  ##
  platform = bf.BuildPlatform.Win
  build_type = bf.BuildType.Debug
  do_generate(platform, build_type)
  do_godot_lint()
  do_godot_check_errors()
  do_run_in_godot_ahk()
  ##


@command
def test():  ##
  platform = bf.BuildPlatform.Win
  build_type = bf.BuildType.Debug
  do_generate(platform, build_type)
  do_godot_lint()
  do_godot_check_errors()
  do_test()
  ##


@command
def deploy_itch():  ##
  bf.git_bump_tag()

  bf.git_check_no_unstashed()

  with bf.git_stash():
    build(bf.BuildTarget.game, bf.BuildPlatform.WebPlaygama, bf.BuildType.Release)

  zip_path = bf.TEMP_DIR / "itch.zip"
  make_web_build_archive(zip_path, Path(".export/web_playgama_release"))

  target = "{}:html".format(bf.game_settings.itch_target)
  bf.run_command([bf.BUTLER_PATH, "push", zip_path, target])
  ##


@command
def banner(filepaths: list[Path]) -> None:  ##
  for fp in filepaths:
    fp.write_text(
      bf.bannerify([x.rstrip() for x in fp.read_text("utf-8").splitlines()]),
      "utf-8",
      newline="\n",
    )
  ##


@command
def list_sounds() -> None:  ##
  a = Counter()
  a.update(x.split("__", 1)[0] for x in get_sounds_that_reaper_would_export())
  print(a)
  ##


@command
def make_swatch():  ##
  colors = bf.game_settings.colors

  def process_color(color: str) -> dict:
    return {
      "name": color,
      "type": "Global",
      "data": {
        "mode": "RGB",
        "values": bf.hex_to_rgb_floats(color),
      },
    }

  # swatch_data = [process_color(c) for c in colors]
  # bf_swatch.write(swatch_data, "aboba.ase")

  def process_color2(color: str) -> bf_swatch.RawColor:
    r, g, b = bf.hex_to_rgb_ints(color)
    r = int(r * 65535 / 255)
    g = int(g * 65535 / 255)
    b = int(b * 65535 / 255)
    assert r < 65536, r
    assert g < 65536, g
    assert b < 65536, b
    assert r >= 0, r
    assert g >= 0, g
    assert b >= 0, b

    return bf_swatch.RawColor(
      name=color,
      color_space=bf_swatch.ColorSpace.RGB,
      component_1=r,
      component_2=g,
      component_3=b,
      component_4=65535,
    )

  with open("aboba.aco", "wb") as out_file:
    bf_swatch.save_aco_file([process_color2(c) for c in colors], out_file)

  with open("aboba.pal", "w") as out_file_2:
    out_file_2.write(
      "JASC-PAL\n0100\n{}\n".format(
        len(colors),
      )
    )
    color_lines = []
    for color in colors:
      r, g, b = bf.hex_to_rgb_ints(color)
      color_lines.append(f"{r} {g} {b}")
    color_lines = color_lines[2:] + color_lines[:2]
    out_file_2.write("\n".join(color_lines))
  ##


@command
def proto_renumber():  ##
  for f in Path("src").rglob("*.proto"):
    bf.run_command(["proto-renumber", "-replace", f])
  ##


@command
def godot_reimport_localization():  ##
  bf.run_command("""
        godot --headless --editor --import --quit assets/localization.csv
    """)
  ##


@command
def gitf():  ##
  message = bf.get_git_commit_message_from_tasks_txt_plan()
  pre_commit_runs = 3
  for i in range(pre_commit_runs):
    try:
      bf.run_command("git add -A")
      bf.run_command("pre-commit run")
      break
    except Exception:
      if i == pre_commit_runs - 1:
        raise
      continue
  for x in (
    "git add -A",
    ["git", "commit", "-m", shlex.quote(message)],
    "git push",
  ):
    bf.run_command(x)  # type: ignore
  ##


def main() -> None:  ##
  # Исполняем файл относительно корня проекта.
  os.chdir(bf.PROJECT_DIR)

  caught_exc = None
  with global_timing_manager_instance:
    try:
      app()
    except Exception as e:
      caught_exc = e
  if caught_exc is not None:
    raise caught_exc
  ##


if __name__ == "__main__":
  enrich_game_settings_colors()
  main()
