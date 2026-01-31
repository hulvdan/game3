# Imports.  {  ###
import os
import shutil
import zipfile
from collections import Counter
from pathlib import Path

import bf_lib as bf
import bf_swatch
import colornames
from bf_game import *  # noqa
from bf_gamelib import do_generate, get_sounds_that_reaper_would_export
from bf_typer import app, command, global_timing_manager_instance, timing

# }


def enrich_game_settings_colors() -> None:
    # {  ###
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
    # }


@timing
def make_web_build_archive(zip_path: Path, where_godot_exported_folder: Path) -> None:
    # {  ###
    with zipfile.ZipFile(zip_path, "w") as archive:
        for filepath in where_godot_exported_folder.glob("*"):
            archive.write(filepath, filepath.name)
    # }


@timing
def do_profile(godot_platform: str) -> None:
    # {  ###
    bf.run_command(
        [
            "scons",
            "target=template_release",
            f"platform={godot_platform}",
            f"profile=../{bf.PROJECT_DIR.name}/src/engine/profile.py",
            f"build_profile=../{bf.PROJECT_DIR.name}/src/engine/profile.gdbuild",
        ],
        cwd="../godot-4.6-stable",
    )
    # }


@timing
def do_check_godot_errors() -> None:
    bf.run_command(
        "godot --quit --headless --check-only --debug --ignore-error-breaks --disable-crash-handler --gpu-abort",
        timeout_seconds=5,
    )


@timing
def do_build(
    target: bf.BuildTarget, platform: bf.BuildPlatform, build_type: bf.BuildType
) -> None:
    # {  ###
    build_id = (target, platform, build_type)
    assert build_id in bf.ALLOWED_BUILDS, "{} is not allowed!".format(build_id)

    exe_name: str | None = None
    if platform.is_web():
        exe_name = "index.html"
    elif platform == bf.BuildPlatform.Win:
        exe_name = "game.exe"
    else:
        assert False

    out_folder = Path(".export") / f"{platform}_{build_type}"
    bf.recursive_mkdir(out_folder)
    bf.run_command(f"del /f/s/q {out_folder}")

    bf.run_command(
        rf"godot --quit --headless --export-{build_type} {platform} {out_folder}/{exe_name}",
        timeout_seconds=30,
    )

    shutil.make_archive(base_name=out_folder, format="zip", root_dir=out_folder)
    # }


@timing
def do_test() -> None:
    # {  ###
    bf.run_command(
        "godot --no-header --headless -s addons/gut/gut_cmdln.gd -gdir src/engine -gdir src/game -gexit -gprefix test -gdisable_colors",
        timeout_seconds=5,
    )
    # }


# @timing
# def do_lint() -> None:
#     # {  ###
#     files_to_lint = [
#         *bf.SRC_DIR.rglob("*.cpp"),
#         *bf.SRC_DIR.rglob("*.h"),
#     ]
#     bf.run_command(["poetry", "run", "cpplint", "--quiet", *files_to_lint])
#
#     (Path(".cmake") / "cppcheck").mkdir(exist_ok=True)
#     defines = (
#         "BF_DEBUG=1",
#         "BF_PLATFORM_Win=1",
#         "TESTS=1",
#     )
#     bf.run_command(
#         [
#             bf.CPPCHECK_PATH,
#             "-j 4",
#             "--cppcheck-build-dir=.cmake/cppcheck",
#             "--project=compile_commands.json",
#             "-ivendor",
#             "--enable=all",
#             "--inline-suppr",
#             "--platform=win64",
#             "--suppress=*:*codegen*",
#             "--suppress=*:*vendor*",
#             "--suppress=checkLevelNormal",
#             "--suppress=checkersReport",
#             "--suppress=constParameterCallback",
#             "--suppress=constParameterPointer",
#             "--suppress=constParameterReference",
#             "--suppress=constStatement",
#             "--suppress=constVariable",
#             "--suppress=constVariablePointer",
#             "--suppress=constVariableReference",
#             "--suppress=cstyleCast",
#             "--suppress=duplicateBreak",
#             "--suppress=invalidPointerCast",
#             "--suppress=knownConditionTrueFalse",
#             "--suppress=memsetClassFloat",
#             "--suppress=missingIncludeSystem",
#             "--suppress=moduloofone",
#             "--suppress=normalCheckLevelMaxBranches",
#             "--suppress=nullPointerArithmetic",
#             "--suppress=passedByValue",
#             "--suppress=selfAssignment",
#             "--suppress=unmatchedSuppression",
#             "--suppress=unreadVariable",
#             "--suppress=useStlAlgorithm",
#             "--suppress=uselessAssignmentArg",
#             "--suppress=variableScope",
#             "--std=c++20",
#             "-q",
#             *[f"-D{d}" for d in defines],
#         ]
#     )
#
#     bf.run_command(
#         rf"""
#             "{bf.CLANG_TIDY_PATH}"
#             src/engine/bf_engine.cpp
#         """
#         # Убираем абсолютный путь к проекту из выдачи линтинга.
#         # Тут куча экранирования происходит, поэтому нужно дублировать обратные слеши.
#         + r'| sed "s/{}//"'.format(
#             str(bf.PROJECT_DIR).replace(os.path.sep, os.path.sep * 3) + os.path.sep * 3
#         )
#     )
#     # }


# @timing
# def do_stop_debugger_ahk() -> None:
#     bf.run_command(r"autohotkey .nvim-personal\cli.ahk stop_debugger")


# @timing
# def do_run_in_debugger_ahk(target: bf.BuildTarget, build_type: bf.BuildType) -> None:
#     # {  ###
#     exe_path = f".cmake/vs17/{build_type}/{target}.exe"
#     bf.run_command(rf"autohotkey .nvim-personal\cli.ahk run_in_debugger {exe_path}")
#     # }


# @command
# def cog():
#     # {  ###
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
#   # }


# @timing
# def do_activate_game_ahk() -> None:
#     bf.run_command(r"autohotkey .nvim-personal\cli.ahk activate_game")


# @command
# def codegen(platform: bf.BuildPlatform, build_type: bf.BuildType):
#     # {  ###
#     do_cmake(platform, build_type)
#     do_generate(platform, build_type)
#     do_activate_game_ahk()
#     # }


@command
def profiles() -> None:
    # {  ###
    godot_platforms = {x.split("_", 1)[0] for x in bf.BuildPlatform}
    for x in godot_platforms:
        do_profile(x)
    # }


@command
def build(target: bf.BuildTarget, platform: bf.BuildPlatform, build_type: bf.BuildType):
    # {  ###
    # do_cmake(platform, build_type)
    do_generate(platform, build_type)
    do_check_godot_errors()
    do_build(target, platform, build_type)
    # }


# @command
# def build_all_and_test():
#     # {  ###
#
#     test()
#     for target, platform, build_type in bf.ALLOWED_BUILDS:
#         if target != bf.BuildTarget.game:
#             continue
#         do_generate(platform, build_type)
#         build(bf.BuildTarget.game, platform, build_type)
#         bf._gamelib = None
#     # }


# @command
# def run_in_debugger(target: bf.BuildTarget, build_type: bf.BuildType):
#     # {  ###
#     platform = bf.BuildPlatform.Win
#
#     do_stop_debugger_ahk()
#
#     do_cmake(platform, build_type)
#     do_generate(platform, build_type)
#     do_build(target, platform, build_type)
#
#     do_run_in_debugger_ahk(target, build_type)
#     # }


# @command
# def update_template():
#     # {  ###
#     bf.run_command("git fetch template")
#
#     with bf.git_stash():
#         bf.run_command("git merge template/template")
#         bf.run_command("poetry install")
#     # }


@command
def test():
    # {  ###
    platform = bf.BuildPlatform.Win
    build_type = bf.BuildType.Debug
    do_generate(platform, build_type)
    do_check_godot_errors()
    do_test()
    # }


# @command
# def deploy_itch():
#     # {  ###
#     bf.git_check_no_unstashed()
#
#     bf.git_bump_tag()
#
#     with bf.git_stash():
#         build(bf.BuildTarget.game, bf.BuildPlatform.WebItch, bf.BuildType.Release)
#
#     zip_path = bf.TEMP_DIR / "itch.zip"
#     make_web_build_archive(zip_path, Path(".export/web_release"))
#
#     target = "{}:html".format(bf.game_settings.itch_target)
#     bf.run_command([bf.BUTLER_PATH, "push", zip_path, target])
#     # }
#
#
# @command
# def deploy_yandex():
#     # {  ###
#     bf.git_check_no_unstashed()
#
#     bf.git_bump_tag()
#
#     with bf.git_stash():
#         build(bf.BuildTarget.game, bf.BuildPlatform.WebYandex, bf.BuildType.Release)
#     # }


# @command
# def receive_ws_logs(port: int):
#     # {  ###
#     get_time = lambda: datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
#
#     async def handler(ws):
#         print(f"{get_time()} I: CONNECTED")
#         try:
#             async for msg in ws:
#                 print(f"{get_time()} {msg}")
#         except websockets.exceptions.ConnectionClosedError:
#             print(f"{get_time()} I: DISCONNECTED")
#
#     async def main():
#         async with websockets.serve(handler, "0.0.0.0", port):
#             print(f"Listening on ws://0.0.0.0:{port}")
#             await asyncio.Future()
#
#     asyncio.run(main())
#     # }


# @command
# def lint():
#     # {  ###
#     do_cmake_ninja_files()
#     do_compile_commands_json()
#     do_lint()
#     # }


# CREDITING SFX {  ###
def _credit_sfx(_folder: Path, _credit: str = "") -> None:
    pass
    # assert isinstance(credit, str)
    #
    # credits_file = folder / "_credits.txt"
    # if credits_file.exists():
    #     credit = credits_file.read_text("utf-8")
    #
    # for file in folder.iterdir():
    #     is_audio = file.is_file() and any(file.name.endswith(x) for x in AUDIO_EXTENSIONS)
    #     if credit:
    #         run_command(
    #             [
    #                 "ffmpeg",
    #                 "-i",
    #                 "-i",
    #             ]
    #         )
    #     else:
    #         log.warning()


# @command
# @timing
# def credit_sfx() -> None:
#     stack = [Path("e:/Media/SFX CREDIT REQUIRED")]
#     while stack:
#         p = stack.pop(0)
#         stack = stack[1:]


@command
def banner(filepath: Path) -> None:
    # {  ###
    filepath.write_text(
        bf.bannerify([x.rstrip() for x in filepath.read_text("utf-8").splitlines()]),
        "utf-8",
        newline="\n",
    )
    # }


@command
def list_sounds() -> None:
    a = Counter()  # type: ignore[var-annotated]
    a.update(x.split("__", 1)[0] for x in get_sounds_that_reaper_would_export())
    print(a)


@command
def make_swatch():
    # {  ###
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
    # }


def main() -> None:
    # {  ###
    test_value = bf.hash32("test")
    assert test_value == 0xAFD071E5, test_value
    test_value = bf.hash32("test")  # Checking that it's stable.
    assert test_value == 0xAFD071E5, test_value

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
    # }


if __name__ == "__main__":
    enrich_game_settings_colors()
    main()

###
