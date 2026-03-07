## Imports
import colorsys
import hashlib
import math
import re
import socket
import subprocess
import sys
import typing as t
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from functools import partial
from pathlib import Path
from types import ModuleType
from typing import Any, Callable, Iterator, List, Sequence, TypeAlias, TypeVar

import cv2
import fnvhash
import numpy as np
import pydantic_core
import pyfiglet
from bf_typer import log
from imgui_bundle import hello_imgui, imgui, immapp
from imgui_bundle.demos_python import (
  demo_im_anim,
  demo_imgui_bundle_intro,
  demo_imgui_md,
  demo_imgui_show_demo_window,
  demo_imguizmo_launcher,
  demo_immapp_launcher,
  demo_immvision_launcher,
  demo_implot,
  demo_logger,
  demo_nanovg_launcher,
  demo_node_editor_launcher,
  demo_tex_inspect_launcher,
  demo_text_edit,
  demo_themes,
  demo_utils,
  demo_widgets,
)
from PIL import Image, ImageChops, ImageDraw, ImageEnhance
from pydantic import BaseModel
from pyglm import glm
from pyglm.glm import mat3, mat4, vec2, vec3

##

T = TypeVar("T")

ColorLike: TypeAlias = tuple[int, int, int, int] | tuple[int, int, int] | str

ConveyorDatum: TypeAlias = tuple[Image.Image, Path]
ConveyorCallable: TypeAlias = Callable[[Image.Image, Path], ConveyorDatum]


@dataclass(slots=True)
class _GameSettings:
  ##
  itch_target: str = "hulvdan/game-template"
  languages: list[str] = field(default_factory=lambda: ["russian", "english"])
  yandex_metrica_counter_id: int | None = None
  colors: list[str] = field(default_factory=lambda: ["#ffffff", "#000000"])

  computed_color_names: list[str] = field(default_factory=list)
  ##


game_settings = _GameSettings()


glib_processing_functions = []


def glib_processor(func):
  glib_processing_functions.append(func)
  return func


class StrEnum(str, Enum):
  def __str__(self):
    return self.value


class BuildType(StrEnum):
  Debug = "debug"
  Release = "release"


class BuildPlatform(StrEnum):
  WebPlaygama = "web_playgama"
  Win = "windows"
  # Web = "web"
  # WebYandex = "web_yandex"
  # WebItch = "web_itch"

  def is_web(self) -> bool:
    return self.lower().startswith("web")


class BuildTarget(StrEnum):
  game = "game"


ALLOWED_BUILDS = (  ##
  (BuildTarget.game, BuildPlatform.Win, BuildType.Debug),
  (BuildTarget.game, BuildPlatform.Win, BuildType.Release),
  # (BuildTarget.game, BuildPlatform.Web, BuildType.Debug),
  # (BuildTarget.game, BuildPlatform.Web, BuildType.Release),
  # (BuildTarget.game, BuildPlatform.WebItch, BuildType.Release),
  # (BuildTarget.game, BuildPlatform.WebYandex, BuildType.Release),
  (BuildTarget.game, BuildPlatform.WebPlaygama, BuildType.Release),
)  ##


REPLACING_SPACES_PATTERN = re.compile(r"\ +")
REPLACING_NEWLINES_PATTERN = re.compile(r"\n+")


# !banner: constants
#  ██████╗ ██████╗ ███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗███████╗
# ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝██╔════╝
# ██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║   ██║   ███████╗
# ██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║   ╚════██║
# ╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║   ██║   ███████║
#  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝

PROJECT_DIR = Path(__file__).parent.parent
TEMP_DIR = PROJECT_DIR / ".temp"
CLI_DIR = Path("cli")
ASSETS_DIR = PROJECT_DIR / "assets"
ART_DIR = ASSETS_DIR / "art"
ART_SRC_DIR = ART_DIR / "src"
ART_TEXTURES_DIR = ART_DIR / "textures"
SRC_DIR = Path("src")

BUTLER_PATH = "C:/Users/user/Programs/butler/butler.exe"

AUDIO_EXTENSIONS = {".wav", ".mp3", ".flac", ".aac", ".m4a", ".wma", ".ogg"}


# !banner: utils
# ██╗   ██╗████████╗██╗██╗     ███████╗
# ██║   ██║╚══██╔══╝██║██║     ██╔════╝
# ██║   ██║   ██║   ██║██║     ███████╗
# ██║   ██║   ██║   ██║██║     ╚════██║
# ╚██████╔╝   ██║   ██║███████╗███████║
#  ╚═════╝    ╚═╝   ╚═╝╚══════╝╚══════╝


def replace_double_spaces(string: str) -> str:
  return re.sub(REPLACING_SPACES_PATTERN, " ", string)


def replace_double_newlines(string: str) -> str:
  return re.sub(REPLACING_NEWLINES_PATTERN, "\n", string)


def test_replace_double_spaces():  ##
  assert replace_double_spaces("") == ""
  assert replace_double_spaces(" ") == " "
  assert replace_double_spaces("  ") == " "
  assert replace_double_spaces("   ") == " "
  assert replace_double_spaces("\n") == "\n"
  assert replace_double_spaces("\n\n") == "\n\n"
  assert replace_double_spaces("\n\n\n") == "\n\n\n"
  ##


def test_replace_double_newlines():  ##
  assert replace_double_newlines("") == ""
  assert replace_double_newlines(" ") == " "
  assert replace_double_newlines("  ") == "  "
  assert replace_double_newlines("   ") == "   "
  assert replace_double_newlines("\n") == "\n"
  assert replace_double_newlines("\n\n") == "\n"
  assert replace_double_newlines("\n\n\n") == "\n"
  ##


def remove_spaces(string: str) -> str:
  return re.sub(REPLACING_SPACES_PATTERN, "", string)


def run_command(
  cmd: list[str | Path] | str,
  stdin_input: str | None = None,
  cwd=None,
  timeout_seconds: int | None = None,
) -> None:  ##
  if isinstance(cmd, str):
    cmd = replace_double_spaces(cmd.replace("\n", " ").strip())

  c = cmd
  if not isinstance(c, str):
    c = " ".join(str(i) for i in cmd)

  log.info(f"Executing command: {c}")

  p = subprocess.run(  # noqa: PLW1510
    cmd,
    shell=True,
    stdout=sys.stdout,
    stderr=sys.stderr,
    text=True,
    encoding="utf-8",
    input=stdin_input,
    cwd=cwd,
    timeout=timeout_seconds,
  )

  if p.returncode:
    msg = f'Failed to execute: "{c}"'
    log.critical(msg)
    assert False, msg
  ##


def recursive_mkdir(path: Path | str) -> None:
  Path(path).mkdir(parents=True, exist_ok=True)


def batched(list_: list[T], n: int) -> Iterator[list[T]]:  ##
  for i in range(0, len(list_), n):
    yield list_[i : i + n]
  ##


def check_duplicates(values: list | tuple) -> None:  ##
  for i in range(len(values)):
    for k in range(i + 1, len(values)):
      assert values[i] != values[k], f"Found duplicate value: {values[i]}"
  ##


def only_one_is_not_none(values: Iterator | list | tuple) -> bool:  ##
  found = False
  for v in values:
    if v:
      if found:
        return False
      found = True
  return found
  ##


def test_only_one_is_not_none() -> None:  ##
  assert only_one_is_not_none([2, None, None])
  assert only_one_is_not_none([2])
  assert not only_one_is_not_none([])
  assert not only_one_is_not_none([1, 2])
  ##


def all_are_not_none(values: Iterator | list | tuple) -> bool:
  return all(v is not None for v in values)


def all_are_none(values: Iterator | list | tuple) -> bool:
  return all(v is None for v in values)


def get_local_ip() -> str:  ##
  ip_address = socket.gethostbyname(socket.gethostname())
  assert ip_address != "127.0.0.1"
  return ip_address
  ##


# !banner: codegen
#  ██████╗ ██████╗ ██████╗ ███████╗ ██████╗ ███████╗███╗   ██╗
# ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝ ██╔════╝████╗  ██║
# ██║     ██║   ██║██║  ██║█████╗  ██║  ███╗█████╗  ██╔██╗ ██║
# ██║     ██║   ██║██║  ██║██╔══╝  ██║   ██║██╔══╝  ██║╚██╗██║
# ╚██████╗╚██████╔╝██████╔╝███████╗╚██████╔╝███████╗██║ ╚████║
#  ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝


def generate_binary_file_header(
  genline, source_path: Path, variable_name: str
) -> None:  ##
  data = source_path.read_bytes()
  genline(f"const u8 {variable_name}[] = {{")
  for i in range(0, len(data), 12):
    chunk = ", ".join(f"0x{b:02x}" for b in data[i : i + 12])
    genline(f"    {chunk},")
  genline("};\n")
  ##


def genenum(
  genline,
  name: str,
  values: Sequence[str],
  *,
  add_count: bool = False,
  flag_values: bool = False,
  overridden_values: Sequence[Any] | None = None,
  enumerate_values: bool = False,
  add_to_string: bool = False,
  comments: list[str] | None = None,
) -> None:  ##
  assert not (flag_values and enumerate_values)
  assert not (overridden_values and enumerate_values)

  if add_count or flag_values:
    assert add_count != flag_values

  string = f"enum {name}"
  string += " {"
  genline(string)

  def genline_with_comment(line: str, i: int) -> None:
    if comments and comments[i]:
      line += "  # " + comments[i]
    genline(line)

  if flag_values:
    for i, value in enumerate(values):
      genline_with_comment("    {} = {},".format(value, hex(2**i)), i)
  elif overridden_values:
    i = 0
    for value, value2 in zip(values, overridden_values, strict=True):
      genline_with_comment("    {} = {},".format(value, value2), i)
      i += 1
  else:
    for i, value in enumerate(values):
      if enumerate_values:
        genline_with_comment("    {} = {},".format(value, i), i)
      else:
        genline_with_comment("    {},".format(value), i)

  if add_count:
    genline("    COUNT,")

  genline("}\n")

  if add_to_string:
    genline(f"const char* {name}ToString({name} type) {{")
    genline("  ASSERT(type >= 0);")
    if add_count:
      genline(f"  ASSERT(type <= {len(values)});")
    else:
      genline(f"  ASSERT(type < {len(values)});")
    genline("  static constexpr const char* strings[] = {")
    for value in values:
      genline(f'    "{name}_{value}",')
    if add_count:
      genline(f'    "{name}_COUNT",')
    genline("  };")
    genline("  return strings[type];")
    genline("};\n")
  ##


_call_stack: list[str | int] = []


_recursive_replace_transform_patterns: Any = None


def _recursive_visiter_setter_list(value, l, i) -> None:
  l[i] = value


def _recursive_visiter_setter_dict(value, d, k) -> None:
  d[k] = value


_recursive_visiter_patterns: tuple[Any, Any] | None = None


def recursive_visiter(
  glib_recursed,
  key_suffix_single: str | None,
  key_suffix_list: str | None,
  callback: Callable[[Any, Callable[[Any], None]], None],
  *,
  root: bool = True,
) -> None:  ##
  global _recursive_visiter_patterns

  if not isinstance(glib_recursed, dict):
    return

  if root:
    assert key_suffix_single or key_suffix_list
    p1 = None
    if key_suffix_single:
      p1 = re.compile(f"(.*_)?{key_suffix_single}(_\\d+)?$")
    p2 = None
    if key_suffix_list:
      p2 = re.compile(f"(.*_)?{key_suffix_list}(_\\d+)?$")
    _recursive_visiter_patterns = (p1, p2)

  assert _recursive_visiter_patterns is not None
  p1, p2 = _recursive_visiter_patterns

  for key, value in glib_recursed.items():
    p1v = p1 and re.match(p1, key)
    p2v = p2 and re.match(p2, key)
    if p1v or p2v:
      if p2v:
        assert isinstance(value, list)
        for i, v in enumerate(value):
          assert isinstance(v, str)
          callback(v, partial(_recursive_visiter_setter_list, l=value, i=i))
      else:
        callback(value, partial(_recursive_visiter_setter_dict, d=glib_recursed, k=key))

    elif isinstance(value, dict):
      recursive_visiter(value, key_suffix_single, key_suffix_list, callback, root=False)

    elif isinstance(value, list):
      for v in value:
        if isinstance(v, dict):
          recursive_visiter(v, key_suffix_single, key_suffix_list, callback, root=False)
  ##


def recursive_replace_transform(
  glib_recursed,
  key_suffix_single: str,
  key_suffix_list: str,
  codename_to_index: dict[str, int],
  *,
  root: bool = True,
) -> list[str] | None:  ##
  global _recursive_replace_transform_patterns
  errors = None

  if not isinstance(glib_recursed, dict):
    return None

  if root:
    _recursive_replace_transform_patterns = (
      re.compile(f"(.*_)?{key_suffix_single}(_\\d+)?$"),
      re.compile(f"(.*_)?{key_suffix_list}(_\\d+)?$"),
    )

  for key, value in glib_recursed.items():
    _call_stack.append(key)

    added_type = False

    if isinstance(value, dict):
      if "type" in value:
        _call_stack.append("(type={})".format(value["type"]))
        added_type = True

      more_errors = recursive_replace_transform(
        value, key_suffix_single, key_suffix_list, codename_to_index, root=False
      )
      if more_errors:
        if not errors:
          errors = more_errors
        else:
          errors.extend(more_errors)

    elif isinstance(key, str) and (
      re.match(_recursive_replace_transform_patterns[0], key)
      or re.match(_recursive_replace_transform_patterns[1], key)
    ):
      if re.match(_recursive_replace_transform_patterns[1], key):
        assert isinstance(value, list)
        for i in range(len(value)):
          assert isinstance(value[i], str), f"value: {value[i]}"
          v = value[i]
          try:
            value[i] = codename_to_index[v]
          except KeyError:
            if not errors:
              errors = []
            errors.append(v)
      else:
        assert isinstance(value, str), "key: {}, value: {}, stack: {}".format(
          key, value, _call_stack
        )
        try:
          glib_recursed[key] = codename_to_index[value]
        except KeyError:
          if not errors:
            errors = []
          errors.append(value)

    elif isinstance(value, list):
      for i, v in enumerate(value):
        if not isinstance(v, dict):
          continue

        _call_stack.append(i)

        added_type2 = False
        if "type" in v:
          _call_stack.append("(type={})".format(v["type"]))
          added_type2 = True

        more_errors = recursive_replace_transform(
          v,
          key_suffix_single,
          key_suffix_list,
          codename_to_index,
          root=False,
        )
        if more_errors:
          if not errors:
            errors = more_errors
          else:
            errors.extend(more_errors)

        if added_type2:
          _call_stack.pop()

        _call_stack.pop()

    if added_type:
      _call_stack.pop()
    _call_stack.pop()

  if root:
    _recursive_replace_transform_patterns = None

  if root and errors:
    message = "recursive_replace_transform({}, {}):\nNot found:\n{}".format(
      key_suffix_single, key_suffix_list, "\n".join(sorted(set(errors)))
    )
    raise AssertionError(message)

  return errors
  ##


def recursive_flattenizer(
  glib_recursed,
  key_suffix_single: str,
  key_suffix_list: str,
  root_list_field: str,
  *,
  list_to_fill: list | None = None,
) -> None:  ##
  if not isinstance(glib_recursed, dict):
    return

  should_emplace_list_in_glib = False
  if list_to_fill is None:
    assert root_list_field not in glib_recursed
    should_emplace_list_in_glib = True
    list_to_fill = [{}]

  for key, value in glib_recursed.items():
    if isinstance(key, str) and (key.endswith((key_suffix_single, key_suffix_list))):
      if key.endswith(key_suffix_list):
        assert isinstance(value, list)
        start = len(list_to_fill)
        list_to_fill.extend(value)
        glib_recursed[key] = {"start": start, "end": len(list_to_fill)}
      else:
        list_to_fill.append(glib_recursed[key])
        glib_recursed[key] = len(list_to_fill) - 1

    elif isinstance(value, dict):
      recursive_flattenizer(
        value,
        key_suffix_single,
        key_suffix_list,
        root_list_field,
        list_to_fill=list_to_fill,
      )

    elif isinstance(value, list):
      for v in value:
        if not isinstance(v, dict):
          continue

        recursive_flattenizer(
          v,
          key_suffix_single,
          key_suffix_list,
          root_list_field,
          list_to_fill=list_to_fill,
        )

  if should_emplace_list_in_glib:
    glib_recursed[root_list_field] = list_to_fill
  ##


# !banner: git
#  ██████╗ ██╗████████╗
# ██╔════╝ ██║╚══██╔══╝
# ██║  ███╗██║   ██║
# ██║   ██║██║   ██║
# ╚██████╔╝██║   ██║
#  ╚═════╝ ╚═╝   ╚═╝


def git_check_no_unstashed() -> None:  ##
  process = subprocess.run(
    "git status --porcelain", check=True, shell=True, capture_output=True, text=True
  )
  git_status_text = process.stdout.strip()
  assert not git_status_text, "You have unstashed changes! Won't proceed!"
  ##


@contextmanager
def git_stash():  ##
  process = subprocess.run(
    "git status --porcelain", check=True, shell=True, capture_output=True, text=True
  )
  git_status_text = process.stdout.strip()
  should_stash = bool(git_status_text)

  if should_stash:
    log.info("git_stash: stashing changes...")
    stash_message = datetime.now().strftime("%Y%m%d-%H%M%S template-update autostash")
    subprocess.run(f'git stash push -u -m "{stash_message}"', check=True, shell=True)
  else:
    log.info("git_stash: no changes - not stashing")

  try:
    yield

  finally:
    if should_stash:
      log.info("git_stash: applying previously stashed changes...")
      subprocess.run("git stash apply", check=True, shell=True)
  ##


def _git_get_current_commit_version_tag() -> str | None:  ##
  process = subprocess.run(
    'git tag -l "v1\\.*" --points-at HEAD',
    check=True,
    shell=True,
    capture_output=True,
    text=True,
  )
  return process.stdout.strip()
  ##


def _git_get_current_branch() -> str:  ##
  return subprocess.run(
    "git branch --show-current",
    check=True,
    shell=True,
    capture_output=True,
    text=True,
  ).stdout.strip()
  ##


def git_bump_tag() -> str:  ##
  assert _git_get_current_branch() in ("master", "main")

  if version := _git_get_current_commit_version_tag():
    log.info("Skipping bumping tag")
    return version

  version_tags = subprocess.run(
    'git tag -l "v1\\.*"', check=True, shell=True, capture_output=True, text=True
  ).stdout.strip()

  next_version = 0
  if version_tags:
    next_version = max(int(t.split(".")[-1]) for t in version_tags.split("\n")) + 1

  version_file = SRC_DIR / "codegen" / "version.gd"
  recursive_mkdir(version_file.parent)
  version_file.write_text(
    f"""# automatically generated by bf_cli.py, do not modify
class_name CodegenVersion

const VERSION: String = "1.{next_version}"
""",
    newline="\n",
  )

  run_command("git reset")
  run_command(f"git add {version_file}")
  run_command(f'git commit -m "Release v1.{next_version}"')
  run_command(f"git tag v1.{next_version}")
  # run_command("git push")
  # run_command(f"git push origin v1.{next_version}")
  return f"v1.{next_version}"
  ##


def get_git_commit_message_from_tasks_txt_plan() -> str:  ##
  started = False
  last_line = None
  with open("TASKS.txt", encoding="utf-8") as in_file:
    for line_ in in_file:
      line = line_.strip()
      if not started:
        if line.strip() == "PLAN":
          started = True
          continue
      else:
        if not line.strip():
          break
        last_line = line
  assert started
  commit_message = last_line
  if commit_message is None or set(commit_message) == {"="}:
    commit_message = "f"
  for prefix in ("* ", "x ", "- ", "+ "):
    commit_message = commit_message.removeprefix(prefix)
  return commit_message.strip()
  ##


# !banner: color
#  ██████╗ ██████╗ ██╗      ██████╗ ██████╗
# ██╔════╝██╔═══██╗██║     ██╔═══██╗██╔══██╗
# ██║     ██║   ██║██║     ██║   ██║██████╔╝
# ██║     ██║   ██║██║     ██║   ██║██╔══██╗
# ╚██████╗╚██████╔╝███████╗╚██████╔╝██║  ██║
#  ╚═════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝


def hex_to_rgb_ints(hex_color: str) -> tuple[int, int, int]:  ##
  hex_color = hex_color.lstrip("#")
  r = int(hex_color[0:2], 16)
  g = int(hex_color[2:4], 16)
  b = int(hex_color[4:6], 16)
  return (r, g, b)
  ##


def hex_to_rgb_floats(hex_color: str) -> tuple[float, float, float]:  ##
  hex_color = hex_color.lstrip("#")
  r = int(hex_color[0:2], 16)
  g = int(hex_color[2:4], 16)
  b = int(hex_color[4:6], 16)
  return (r / 255, g / 255, b / 255)
  ##


def rgb_floats_to_hex(rgb_floats: tuple[float, float, float]) -> str:  ##
  r, g, b = rgb_floats
  r_int = round(r * 255)
  g_int = round(g * 255)
  b_int = round(b * 255)
  return "#{:02X}{:02X}{:02X}".format(r_int, g_int, b_int)
  ##


def transform_color(
  rgb: tuple[float, float, float],
  *,
  saturation_scale: float = 1,
  value_scale: float = 1.0,
) -> tuple[float, float, float]:  ##
  assert saturation_scale >= 0
  assert value_scale >= 0
  r, g, b = rgb
  h, s, v = colorsys.rgb_to_hsv(r, g, b)
  s = min(s * saturation_scale, 1.0)
  v = min(v * value_scale, 1.0)
  return colorsys.hsv_to_rgb(h, s, v)
  ##


def palette_color_tuple3(name: str) -> tuple[int, int, int]:  ##
  for i, c in enumerate(game_settings.computed_color_names):
    if c.upper().replace(" ", "_") == name:
      return hex_to_rgb_ints(game_settings.colors[i])
  assert False
  ##


# !banner: hashing
# ██╗  ██╗ █████╗ ███████╗██╗  ██╗██╗███╗   ██╗ ██████╗
# ██║  ██║██╔══██╗██╔════╝██║  ██║██║████╗  ██║██╔════╝
# ███████║███████║███████╗███████║██║██╔██╗ ██║██║  ███╗
# ██╔══██║██╔══██║╚════██║██╔══██║██║██║╚██╗██║██║   ██║
# ██║  ██║██║  ██║███████║██║  ██║██║██║ ╚████║╚██████╔╝
# ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝


def stable_hash(value: str | int) -> int:  ##
  if isinstance(value, int):
    value = str(value)
  if isinstance(value, str):
    return int(hashlib.md5(value.encode("utf-8")).hexdigest(), 16)
  assert False, "Not supported type of value"
  ##


def hash32(value: str) -> int:
  return fnvhash.fnv1a_32(value.encode(encoding="ascii"))


def hash32_utf8(value: str) -> int:
  return fnvhash.fnv1a_32(value.encode(encoding="utf-8"))


def hash32_file_utf8(filepath) -> int:  ##
  with open(filepath, encoding="utf-8") as in_file:
    d = in_file.read()
  return hash32_utf8(d)
  ##


# !banner: banners
# ██████╗  █████╗ ███╗   ██╗███╗   ██╗███████╗██████╗ ███████╗
# ██╔══██╗██╔══██╗████╗  ██║████╗  ██║██╔════╝██╔══██╗██╔════╝
# ██████╔╝███████║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝███████╗
# ██╔══██╗██╔══██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗╚════██║
# ██████╔╝██║  ██║██║ ╚████║██║ ╚████║███████╗██║  ██║███████║
# ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝

BANNERIFY_PATTERN = "!" + "banner: "


def bannerify(lines: list[str]) -> str:  ##
  out = ""
  bannering_prefix = ""
  current_line_index = 0
  off = 0
  while current_line_index + off < len(lines):
    line = lines[current_line_index + off]

    if BANNERIFY_PATTERN in line:
      if bannering_prefix:
        print("Found line inside bannering")
        exit(1)

      if line.count(BANNERIFY_PATTERN) > 1:
        print("Found line with more than 1 pattern inside")
        exit(1)

      bannering_prefix = line[: line.find(BANNERIFY_PATTERN)]
      if not bannering_prefix:
        print("Found line with no prefix")
        exit(1)

      if not line.removeprefix(bannering_prefix + BANNERIFY_PATTERN).strip():
        print("Found line that has prefix but no content to bannerify")
        exit(1)

      for i in range(current_line_index + off + 1, len(lines)):
        if lines[i].startswith(bannering_prefix):
          off += 1
        else:
          out += lines[i]
          break

      out += line
      out += "\n"
      out += "\n".join(
        bannering_prefix + x.rstrip()
        for x in pyfiglet.figlet_format(
          line.removeprefix(bannering_prefix + BANNERIFY_PATTERN),
          font="ansi_shadow",
          width=90,
        ).splitlines()
        if x.strip()
      )
      out += "\n"
      bannering_prefix = ""

    else:
      out += line + "\n"

    current_line_index += 1

  return out
  ##


def test_bannerify():  ##
  assert bannerify([]) == ""
  assert bannerify(["a"]) == "a\n"
  assert bannerify(["a", " b"]) == "a\n b\n"

  got = bannerify(
    [
      f"// {BANNERIFY_PATTERN}a",
      "// ASDASAD",
      "",
      f"// {BANNERIFY_PATTERN}b",
      "",
      "a",
      "b",
      "c",
      "",
      "",
      "d",
    ]
  )
  expected = "".join(
    x.rstrip() + "\n"
    for x in (
      f"// {BANNERIFY_PATTERN}a",
      "//  █████╗",
      "// ██╔══██╗",
      "// ███████║",
      "// ██╔══██║",
      "// ██║  ██║",
      "// ╚═╝  ╚═╝",
      "",
      f"// {BANNERIFY_PATTERN}b",
      "// ██████╗",
      "// ██╔══██╗",
      "// ██████╔╝",
      "// ██╔══██╗",
      "// ██████╔╝",
      "// ╚═════╝",
      "",
      "a",
      "b",
      "c",
      "",
      "",
      "d",
    )
  )
  if got != expected:
    print("EXPECTED:")
    print(expected)
    print("\nGOT:")
    print(got)
  assert got == expected
  ##


# !banner: image
# ██╗███╗   ███╗ █████╗  ██████╗ ███████╗
# ██║████╗ ████║██╔══██╗██╔════╝ ██╔════╝
# ██║██╔████╔██║███████║██║  ███╗█████╗
# ██║██║╚██╔╝██║██╔══██║██║   ██║██╔══╝
# ██║██║ ╚═╝ ██║██║  ██║╚██████╔╝███████╗
# ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝


def _change_matrix_outline(input_mat, radius: int):  ##
  mat = np.ones(input_mat.shape)
  check_size = radius + 1.0
  mat[input_mat > check_size] = 0
  border = (input_mat > radius) & (input_mat <= check_size)
  mat[border] = 1.0 - (input_mat[border] - radius)
  return mat
  ##


def _change_matrix_shadow(input_mat, radius: int):  ##
  mat = np.ones(input_mat.shape)
  mat[input_mat > radius] = 0
  border = input_mat <= radius

  # mat[border] = (radius - input_mat[border]) / radius

  # NOTE: Squared easing of shadow decay.
  mat[border] = (
    (radius - input_mat[border]) * (radius - input_mat[border]) / radius / radius
  )
  return mat
  ##


def _cv2pil(cv_img):
  return Image.fromarray(cv_img.astype("uint8"))


def im_outline(
  image: Image.Image,
  *,
  radius: int,
  color: tuple[int, int, int, int] | tuple[int, int, int] = (0, 0, 0, 255),
  is_shadow: bool = False,
  threshold: int = 0,
  blend_image_on_top: bool = True,
  extend: bool = True,
) -> Image.Image:  ##
  assert threshold >= 0

  if len(color) == 3:
    color = (*color, 255)

  img = np.asarray(image)

  h = img.shape[0]
  w = img.shape[1]

  padding = radius
  alpha = img[:, :, 3]
  rgb_img = img[:, :, 0:3]
  extend_padding = padding
  if not extend:
    extend_padding = 0
  bigger_img = cv2.copyMakeBorder(
    rgb_img,
    extend_padding,
    extend_padding,
    extend_padding,
    extend_padding,
    cv2.BORDER_CONSTANT,
    value=(0, 0, 0, 0),
  )
  alpha = cv2.copyMakeBorder(  #  type: ignore
    alpha,
    extend_padding,
    extend_padding,
    extend_padding,
    extend_padding,
    cv2.BORDER_CONSTANT,
    value=0,  # type: ignore
  )
  bigger_img = cv2.merge((bigger_img, alpha))
  h, w, _ = bigger_img.shape

  _, alpha_without_shadow = cv2.threshold(
    alpha, threshold, 255, cv2.THRESH_BINARY
  )  # threshold=0 in photoshop
  alpha_without_shadow = 255 - alpha_without_shadow
  dist = cv2.distanceTransform(
    alpha_without_shadow, cv2.DIST_L2, cv2.DIST_MASK_5
  )  # dist l1 : L1 , dist l2 : l2

  if is_shadow:
    stroked = _change_matrix_shadow(dist, radius)
  else:
    stroked = _change_matrix_outline(dist, radius)

  stroke_b = np.full((h, w), color[0], np.uint8)
  stroke_g = np.full((h, w), color[1], np.uint8)
  stroke_r = np.full((h, w), color[2], np.uint8)
  stroke_alpha = (stroked * color[3]).astype(np.uint8)

  stroke = cv2.merge((stroke_b, stroke_g, stroke_r, stroke_alpha))
  stroke = _cv2pil(stroke)
  if blend_image_on_top:
    bigger_img = _cv2pil(bigger_img)
    stroke = Image.alpha_composite(stroke, bigger_img)  # type: ignore
  return stroke
  ##


def im_extract_white(grayscale_image: Image.Image) -> Image.Image:  ##
  img = np.asarray(grayscale_image)
  h, w, _ = img.shape
  one = np.full((h, w), 255, np.uint8)
  img_r = img[:, :, 0]
  img_alpha = img[:, :, 3]
  img_front = cv2.merge((one, one, one, cv2.min(img_r, img_alpha)))
  return _cv2pil(img_front)
  ##


def im_extract_black(grayscale_image: Image.Image) -> Image.Image:  ##
  img = np.asarray(grayscale_image)
  h, w, _ = img.shape
  one = np.full((h, w), 255, np.uint8)
  img_r = img[:, :, 0]
  img_alpha = img[:, :, 3]
  alpha = cv2.min(255 - img_r, img_alpha)
  out_img = cv2.merge((one, one, one, alpha))
  return _cv2pil(out_img)
  ##


def im_replace_color(image: Image.Image, color: tuple[int, int, int]) -> Image.Image:  ##
  img = np.asarray(image)
  h, w, _ = img.shape
  alpha = img[:, :, 3]
  out_img = cv2.merge(
    (
      np.full((h, w), color[0], np.uint8),
      np.full((h, w), color[1], np.uint8),
      np.full((h, w), color[2], np.uint8),
      alpha,
    )
  )
  return _cv2pil(out_img)
  ##


def imc_replace_color(color: tuple[int, int, int]) -> ConveyorCallable:  ##
  def inner(image_: Image.Image, path_: Path) -> ConveyorDatum:
    image = im_replace_color(image_, color)
    return image, path_

  return inner
  ##


def im_multiply(
  image: Image.Image, color: tuple[int, int, int] | tuple[int, int, int, int] | str
) -> Image.Image:  ##
  return ImageChops.multiply(image, Image.new("RGBA", image.size, color))
  ##


def imc_multiply(color: tuple[int, int, int]) -> ConveyorCallable:  ##
  def inner(image_: Image.Image, path_: Path) -> ConveyorDatum:
    image = im_multiply(image_, color)
    return image, path_

  return inner
  ##


im_red = lambda image: im_replace_color(image, (255, 0, 0))
im_green = lambda image: im_replace_color(image, (0, 255, 0))
im_blue = lambda image: im_replace_color(image, (0, 0, 255))
im_white = lambda image: im_replace_color(image, (255, 255, 255))
im_black = lambda image: im_replace_color(image, (0, 0, 0))

imc_red = imc_replace_color((255, 0, 0))
imc_green = imc_replace_color((0, 255, 0))
imc_blue = imc_replace_color((0, 0, 255))
imc_white = imc_replace_color((255, 255, 255))
imc_black = imc_replace_color((0, 0, 0))


def im_invert(image: Image.Image) -> Image.Image:
  return ImageChops.invert(image)


def im_remap(
  grayscale_image: Image.Image,
  black_to: tuple[int, int, int],
  white_to: tuple[int, int, int],
) -> Image.Image:  ##
  img = np.asarray(grayscale_image)
  img_r = img[:, :, 0]
  img_g = img[:, :, 1]
  img_b = img[:, :, 2]
  out_img = cv2.merge(
    (
      (255 - img_r) * (black_to[0] / 255) + (img_r * (white_to[0] / 255)),
      (255 - img_g) * (black_to[1] / 255) + (img_g * (white_to[1] / 255)),
      (255 - img_b) * (black_to[2] / 255) + (img_b * (white_to[2] / 255)),
      img[:, :, 3] * 1.0,
    )
  )
  return _cv2pil(out_img)
  ##


def im_remap_grayscale(
  grayscale_image: Image.Image, black_to: int, white_to: int
) -> Image.Image:  ##
  return im_remap(
    grayscale_image, (black_to, black_to, black_to), (white_to, white_to, white_to)
  )
  ##


def im_conveyor(
  folder_name: str,
  conveyor_name: str,
  *args: ConveyorCallable,
  out_dir: Path | str = ART_TEXTURES_DIR,
) -> None:  ##
  log.info(f"conveyor: `{folder_name}`: {conveyor_name}...")
  folder = ART_TEXTURES_DIR / folder_name
  assert folder.exists(), f"`{folder}` does not exist!"

  files = list(folder.glob("*.png"))
  for f in files:
    img: Image.Image = Image.open(f)
    for func in args:
      img2, f = func(img, f)  # noqa: PLW2901
      img = img2
    img.save(Path(out_dir) / f.name)
  log.info(f"conveyor: `{folder_name}`: {conveyor_name}... Success!")
  ##


def imc_prefix(prefix: str) -> ConveyorCallable:  ##
  def inner(image_: Image.Image, path_: Path) -> ConveyorDatum:
    extension = path_.name.rsplit(".", 1)[-1]
    path = path_.parent / "{}_{}.{}".format(prefix, path_.stem, extension)
    return image_, path

  return inner
  ##


def imc_suffix(suffix: str) -> ConveyorCallable:  ##
  def inner(image_: Image.Image, path_: Path) -> ConveyorDatum:
    extension = path_.name.rsplit(".", 1)[-1]
    path = path_.parent / "{}_{}.{}".format(path_.stem, suffix, extension)
    return image_, path

  return inner
  ##


def im_scale(
  image: Image.Image, scale: float, scale2: float = float("inf")
) -> Image.Image:  ##
  if scale2 == float("inf"):
    scale2 = scale
  return image.resize((round(image.size[0] * scale), round(image.size[1] * scale2)))
  ##


def imc_scale(factor: float) -> ConveyorCallable:  ##
  def inner(image_: Image.Image, path_: Path) -> ConveyorDatum:
    image = image_.resize(
      (round(image_.size[0] * factor), round(image_.size[1] * factor))
    )
    return image, path_

  return inner
  ##


def imc_outline(**kwargs: Any) -> ConveyorCallable:  ##
  def inner(image_: Image.Image, path_: Path) -> ConveyorDatum:
    image = im_outline(image=image_, **kwargs)
    return image, path_

  return inner
  ##


def imc_remap(
  black_to: tuple[int, int, int], white_to: tuple[int, int, int]
) -> ConveyorCallable:  ##
  def inner(image_: Image.Image, path_: Path) -> ConveyorDatum:
    image = im_remap(image_, black_to, white_to)
    return image, path_

  return inner
  ##


def imc_extract_white() -> ConveyorCallable:  ##
  def inner(image_: Image.Image, path_: Path) -> ConveyorDatum:
    return im_extract_white(image_), path_

  return inner
  ##


def imc_extract_black() -> ConveyorCallable:  ##
  def inner(image_: Image.Image, path_: Path) -> ConveyorDatum:
    return im_extract_black(image_), path_

  return inner
  ##


def imc_brightness(factor: float) -> ConveyorCallable:  ##
  def inner(image_: Image.Image, path_: Path) -> ConveyorDatum:
    image = ImageEnhance.Brightness(image_).enhance(factor)
    return image, path_

  return inner
  ##


def _shape(
  func_name: str,
  size: int | tuple[int, int],
  *,
  radius: int = 0,
  fill: tuple[int, int, int, int] = (255, 255, 255, 255),
  outline: tuple[int, int, int, int] = (0, 0, 0, 255),
  width: int = 0,
) -> Image.Image:  ##
  if isinstance(size, int):
    size = (size, size)

  assert size[0] > radius * 2
  assert size[1] > radius * 2
  assert radius >= 0
  assert width >= 0

  original_size = size

  scale_to_smooth_later = 2
  size = (size[0] * scale_to_smooth_later, size[1] * scale_to_smooth_later)
  radius *= scale_to_smooth_later
  width *= scale_to_smooth_later

  image = Image.new("RGBA", size)
  d = ImageDraw.ImageDraw(image, "RGBA")

  kw = {}
  if func_name == "rounded_rectangle":
    kw["radius"] = radius
  else:
    assert radius == 0

  getattr(d, func_name)(xy=(0, 0, *size), fill=fill, outline=outline, width=width, **kw)

  return image.resize(original_size)
  ##


def im_rectangle(*args: Any, **kwargs: Any) -> Image.Image:
  return _shape("rounded_rectangle", *args, **kwargs)


def im_ellipse(*args: Any, **kwargs: Any) -> Image.Image:
  return _shape("ellipse", *args, **kwargs)


def im_star(size: int, inner_radius_scale: float = 0.5, color: ColorLike = "white"):  ##
  points = []

  outer_r = size / 2
  inner_r = outer_r * inner_radius_scale

  for i in range(10):
    r = inner_r if i % 2 else outer_r
    a = i * math.pi / 5 - math.pi / 2
    x = outer_r + math.cos(a) * r
    y = outer_r + math.sin(a) * r
    points.append((x, y))

  img = Image.new("RGBA", (size, size))
  draw = ImageDraw.Draw(img)

  draw.polygon(points, fill=color)
  return img
  ##


def im_spritesheetify(
  image_path: Path,
  *,
  origin: tuple[int, int] = (0, 0),
  cell_size: tuple[int, int] | int,
  size: tuple[int, int],
  gap: tuple[int, int] | int,
  out_dir: Path,
  out_filename_prefix: str = "",
  out_filenames: list[str] | None = None,
  trim_transparent: bool = True,
  stop_on_finding_empty_sprite: bool = True,
) -> None:  ##
  recursive_mkdir(out_dir)

  image = Image.open(image_path)
  X, Y = size

  assert isinstance(gap, (int, tuple))
  if isinstance(gap, int):
    gap = (gap, gap)

  assert isinstance(cell_size, (int, tuple))
  if isinstance(cell_size, int):
    cell_size = (cell_size, cell_size)

  log.info(f"spritesheetify: {image_path}...")

  for y in range(Y):
    for x in range(X):
      t = y * X + x

      if (out_filenames is not None) and (t >= len(out_filenames)):
        break

      x0 = origin[0] + (cell_size[0] + gap[0]) * x
      y0 = origin[1] + (cell_size[1] + gap[1]) * y
      img = image.crop((x0, y0, x0 + cell_size[0], y0 + cell_size[1]))
      bbox = img.getbbox()

      if bbox is None:
        if out_filenames:
          assert False, (
            "In named spritesheet (`{}`) found a cell ({}, {}) that's named but doesn't contain anything".format(
              str(out_filenames)[:200], x, y
            )
          )
        if stop_on_finding_empty_sprite:
          break

      if out_filenames is None:
        filename = str(t + 1)
      else:
        filename = out_filenames[t]

      if trim_transparent:
        img2 = img.crop(bbox)
      else:
        img2 = img
      img2.save(out_dir / (out_filename_prefix + filename + ".png"))

  log.info(f"spritesheetify: {image_path}... Success!")
  ##


def im_draw_on_top(
  background: Image.Image,
  overlay: Image.Image,
  overlay_color: tuple[int, int, int, int] = (255, 255, 255, 255),
) -> Image.Image:  ##
  assert (
    background.size[0] / background.size[1] - overlay.size[0] / overlay.size[1]
  ) <= 0.0001, "Aspect ratios of images must be the same!"

  arr = np.asarray(overlay.resize(background.size), dtype=np.float32)
  arr *= np.array(overlay_color, dtype=np.float32) / 255.0
  o = Image.fromarray(arr.clip(0, 255).astype("uint8"), "RGBA")

  return Image.alpha_composite(background.convert("RGBA"), o)
  ##


# !banner: ldtk
# ██╗     ██████╗ ████████╗██╗  ██╗
# ██║     ██╔══██╗╚══██╔══╝██║ ██╔╝
# ██║     ██║  ██║   ██║   █████╔╝
# ██║     ██║  ██║   ██║   ██╔═██╗
# ███████╗██████╔╝   ██║   ██║  ██╗
# ╚══════╝╚═════╝    ╚═╝   ╚═╝  ╚═╝


def as_dict(pos: tuple[int, int] | tuple[float, float]) -> dict[str, int | float]:
  return {"x": pos[0], "y": pos[1]}


class LdtkEntity(BaseModel):  ##
  identifier: str
  # uid: int
  # tags: [str]
  # exportToToc: bool
  # allowOutOfBounds: bool
  # doc: null
  # width: 16
  # height: 16
  # resizableX: false
  # resizableY: false
  # minWidth: null
  # maxWidth: null
  # minHeight: null
  # maxHeight: null
  # keepAspectRatio: true
  # tileOpacity: 1
  # fillOpacity: 1
  # lineOpacity: 1
  # hollow: false
  # color: "#63C74D"
  # renderMode: "Ellipse"
  # showName: true
  # tilesetId: null
  # tileRenderMode: "FitInside"
  # tileRect: null
  # uiTileRect: null
  # nineSliceBorders: []
  # maxCount: 0
  # limitScope: "PerLevel"
  # limitBehavior: "MoveLastOne"
  # pivotX: 0.5
  # pivotY: 0.5
  # fieldDefs: []
  ##


class LdtkTilesetTileCustomdata(BaseModel):  ##
  data: str
  tileId: int
  ##


class LdtkTilesetTileEnumTag(BaseModel):  ##
  enumValueId: str
  tileIds: list[int]
  ##


class LdtkTileset(BaseModel):  ##
  identifier: str
  cHei_: int
  cWid_: int
  customData: list[LdtkTilesetTileCustomdata]
  enumTags: list[LdtkTilesetTileEnumTag]
  uid: int

  @property
  def size(self) -> tuple[int, int]:
    return (self.cWid_, self.cHei_)

  ##


class LdtkIntGridValueDef(BaseModel):  ##
  value: int
  identifier: str | None
  ##


class LdtkLayerDef(BaseModel):  ##
  identifier: str
  intGridValues: list[LdtkIntGridValueDef]
  ##


class LdtkDefs(BaseModel):  ##
  entities: list[LdtkEntity]
  tilesets: list[LdtkTileset]
  layers: list[LdtkLayerDef]
  ##


class LdtkFieldInstance(BaseModel):  ##
  identifier_: str  # direction
  type_: str
  # __type  :  LocalEnum.direction
  value_: Any  # right
  # __tile  :  null
  # defUid  :  60
  # realEditorValues: list
  ##


def ldtk_field_function(self, identifier: str, default: Any = None) -> Any:  ##
  try:
    value = next(
      field for field in self.fieldInstances if field.identifier_ == identifier
    )
    return value.value_

  except StopIteration:
    if default is not None:
      return default

    assert False, 'Field "{}" not found !\nAvailable values are: {}'.format(
      identifier,
      ", ".join(field.identifier_ for field in self.fieldInstances),
    )

  ##


def ldtk_field_ref_function(self, identifier: str, reference_layer) -> Any:  ##
  try:
    value = next(
      field for field in self.fieldInstances if field.identifier_ == identifier
    )

    assert value.type_ == "EntityRef"
    assert reference_layer is not None
    if value.value_ is not None:
      return ldtk_get_referenced_entity(reference_layer, value.value_["entityIid"])
    return None

  except StopIteration:
    assert False, 'Field "{}" not found !\nAvailable values are: {}'.format(
      identifier,
      ", ".join(field.identifier_ for field in self.fieldInstances),
    )
  ##


class LdtkEntityInstance(BaseModel):  ##
  identifier_: str  # "entities"
  grid_: tuple[int, int]
  pivot_: tuple[float, float]
  # tile_: TileEntityField | None
  tags_: list[str]
  # tile_: null
  # smartColor_: "#63C74D"
  iid: str
  width: int  # 16
  height: int  # 16
  # defUid: 51
  px: tuple[int, int]
  fieldInstances: list[LdtkFieldInstance]
  # worldX_: int  # 104
  # worldY_: int  # -61

  @property
  def pos(self) -> tuple[int, int]:
    return (self.grid_[0], self.grid_[1])

  @property
  def pos_center(self) -> tuple[float, float]:
    return (self.grid_[0] + self.width / 32, self.grid_[1] + self.height / 32)

  @property
  def size(self) -> tuple[int, int]:
    assert self.width % 16 == 0
    assert self.height % 16 == 0
    x = self.width // 16
    y = self.height // 16
    return (x, y)

  field = ldtk_field_function
  field_ref = ldtk_field_ref_function

  def direction_field(self, identifier: str) -> float | None:
    field = self.field(identifier)

    if field is None:
      return 0

    x = field["cx"]
    y = field["cy"]

    return math.atan2(y - self.grid_[1], x - self.grid_[0])

  ##


class LdtkLayerTile(BaseModel):  ##
  px: tuple[int, int]
  # src: list[int]
  ##


class LdtkLayerInstance(BaseModel):  ##
  identifier_: str  # "entities"
  # type_: str  # "Entities"
  cWid_: int  # 71
  cHei_: int  # 54
  # gridSize_: int  # 16
  # opacity_: int # 1
  # pxTotalOffsetX_: int # 0
  # pxTotalOffsetY_: int # 0
  # tilesetDefUid_: null
  # tilesetRelPath_: null
  # iid: "94e96550-c210-11ef-acf4-8363d5ef1ebd"
  # levelId: 0
  # layerDefUid: 52
  # pxOffsetX: 0
  # pxOffsetY: 0
  # visible: true
  # optionalRules: []
  intGridCsv: list[int]
  # autoLayerTiles: []
  # seed: 5679830
  # overrideTilesetUid: null
  gridTiles: list[LdtkLayerTile]
  entityInstances: list[LdtkEntityInstance]

  @property
  def size(self) -> tuple[int, int]:
    return (self.cWid_, self.cHei_)

  def entities(self, identifier: str) -> Iterator[LdtkEntityInstance]:
    return (x for x in self.entityInstances if x.identifier_ == identifier)

  ##


class LdtkLevel(BaseModel):  ##
  identifier: str
  iid: str
  uid: int
  worldX: int
  worldY: int
  worldDepth: int
  pxWid: int
  pxHei: int
  # bgColor_: "#000000"
  # bgColor: null
  # useAutoIdentifier: true
  # bgRelPath: null
  # bgPos: null
  # bgPivotX: 0.5
  # bgPivotY: 0.5
  # smartColor_: "#737373"
  # bgPos_: null
  # externalRelPath: null
  fieldInstances: list[LdtkFieldInstance]
  layerInstances: list[LdtkLayerInstance]
  # neighbours_: [

  field = ldtk_field_function
  field_ref = ldtk_field_ref_function

  def get_layer(self, name: str) -> LdtkLayerInstance:
    for layer in self.layerInstances:
      if layer.identifier_ == name:
        return layer
    assert False, f"Layer {name} not found"

  @property
  def size(self) -> tuple[int, int]:
    return (self.pxWid // 16, self.pxHei // 16)

  ##


class Ldtk(BaseModel):  ##
  defs: LdtkDefs
  levels: list[LdtkLevel]

  def get_level(self, name: str) -> LdtkLevel:
    for level in self.levels:
      if level.identifier == name:
        return level
    assert False, f"Level {name} not found"

  ##


def ldtk_try_get_single_entity(
  layer: LdtkLayerInstance, identifier: str
) -> LdtkEntityInstance | None:  ##
  found = None
  for e in layer.entityInstances:
    if e.identifier_ == identifier:
      assert found is None
      found = e
  return found
  ##


def ldtk_get_single_entity(
  layer: LdtkLayerInstance, identifier: str
) -> LdtkEntityInstance:  ##
  found = ldtk_try_get_single_entity(layer, identifier)
  assert found is not None
  return found
  ##


def ldtk_get_referenced_entity(
  layer: LdtkLayerInstance, referenced_iid: str
) -> LdtkEntityInstance:
  return next(e for e in layer.entityInstances if e.iid == referenced_iid)


def _ldtk_transform_field_names(data) -> None:
  """Перевод полей формата `__aboba` в `aboba_`."""
  ##
  if not isinstance(data, dict):
    return

  for key in [k for k in data if k.startswith("__")]:
    new_key = key[2:] + "_"
    data[new_key] = data.pop(key)

  for value in data.values():
    if isinstance(value, dict):
      _ldtk_transform_field_names(value)
    elif isinstance(value, list):
      for v in value:
        if isinstance(v, dict):
          _ldtk_transform_field_names(v)
  ##


def ldtk_load(filepath: Path | str) -> Ldtk:  ##
  with open(filepath) as in_file:
    data = in_file.read()
  loaded_json = pydantic_core.from_json(data)
  _ldtk_transform_field_names(loaded_json)
  return Ldtk.model_validate(loaded_json)
  ##


# !banner: imgui
# ██╗███╗   ███╗ ██████╗ ██╗   ██╗██╗
# ██║████╗ ████║██╔════╝ ██║   ██║██║
# ██║██╔████╔██║██║  ███╗██║   ██║██║
# ██║██║╚██╔╝██║██║   ██║██║   ██║██║
# ██║██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║
# ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝


@dataclass
class ImGuiPanel:  ##
  label: str
  gui_function: Callable[[], None]
  ##


def show_imgui(
  window_title: str,
  panels: list[ImGuiPanel],
  setup_imgui_style: hello_imgui.VoidFunction | None = None,
  before_exit: hello_imgui.VoidFunction | None = None,
) -> t.Coroutine[None, None, None]:  ##
  print(
    f"For information, demos sources are available in {demo_utils.demos_assets_folder()}"
  )

  # Part 1: Define the runner params

  runner_params = hello_imgui.RunnerParams()
  runner_params.app_window_params.window_title = window_title
  runner_params.app_window_params.restore_previous_geometry = True

  # Menu bar
  runner_params.imgui_window_params.show_menu_bar = True
  runner_params.imgui_window_params.show_status_bar = True
  runner_params.imgui_window_params.remember_theme = True

  # Part 2: Define the application layout and windows

  # First, tell HelloImGui that we want full screen dock space (this will create "MainDockSpace")
  runner_params.imgui_window_params.default_imgui_window_type = (
    hello_imgui.DefaultImGuiWindowType.provide_full_screen_dock_space
  )
  # In this demo, we also demonstrate multiple viewports.
  # you can drag windows outside out the main window in order to put their content into new native windows
  runner_params.imgui_window_params.enable_viewports = True

  #
  # Define our dockable windows : each window provide a Gui callback, and will be displayed
  # in a docking split.
  #
  dockable_windows: List[hello_imgui.DockableWindow] = []

  # --- Standalone tabs (no grouping) ---
  standalone_demos = [
    _DemoDetails("Intro", demo_imgui_bundle_intro),
    _DemoDetails("Dear ImGui", demo_imgui_show_demo_window),
    _DemoDetails("Demo Apps", demo_immapp_launcher),
  ]

  for demo in standalone_demos:
    window = hello_imgui.DockableWindow()
    window.label = demo.label
    window.dock_space_name = "MainDockSpace"
    demo_module_name = demo.demo_module.__name__.split(".")[-1]

    def make_win_fn(mod_name: str, mod: ModuleType, sc: bool) -> Callable[[], None]:
      def win_fn() -> None:
        _show_module_demo(mod_name, mod.demo_gui, sc)

      return win_fn

    window.gui_function = make_win_fn(demo_module_name, demo.demo_module, demo.show_code)
    dockable_windows.append(window)

  # --- Grouped tabs (sub-demos shown as collapsing headers) ---
  groups = [
    _DemoGroup(
      "Visualization",
      [
        _DemoDetails("Plots with ImPlot and ImPlot3D", demo_implot),
        _DemoDetails("ImmVision - Image analyzer", demo_immvision_launcher),
        _DemoDetails("ImGuizmo - Immediate Mode 3D Gizmo", demo_imguizmo_launcher),
        _DemoDetails("NanoVG - 2D Vector Drawing", demo_nanovg_launcher),
      ],
    ),
    _DemoGroup(
      "Widgets",
      [
        _DemoDetails("Markdown - Rich Text Rendering", demo_imgui_md, show_code=True),
        _DemoDetails("Text Editor - Code Editing Widget", demo_text_edit, show_code=True),
        _DemoDetails("Misc Widgets - Knobs, Toggles, ...", demo_widgets, show_code=True),
        _DemoDetails("Logger - Log Window Widget", demo_logger, show_code=True),
        _DemoDetails("Tex Inspect - Texture Inspector", demo_tex_inspect_launcher),
      ],
    ),
    _DemoGroup(
      "Tools",
      [
        _DemoDetails("Node Editor - Visual Node Graphs", demo_node_editor_launcher),
        _DemoDetails("Themes - Style & Color Customization", demo_themes, show_code=True),
        _DemoDetails("ImAnim - Animation Library", demo_im_anim),
      ],
    ),
  ]

  for group in groups:
    window = hello_imgui.DockableWindow()
    window.label = group.label
    window.dock_space_name = "MainDockSpace"

    def make_group_fn(g: _DemoGroup) -> Callable[[], None]:
      def win_fn() -> None:
        _show_group_gui(g)

      return win_fn

    window.gui_function = make_group_fn(group)
    dockable_windows.append(window)

  for panel in panels:
    window = hello_imgui.DockableWindow()
    window.label = panel.label
    window.dock_space_name = "MainDockSpace"
    window.gui_function = panel.gui_function
    dockable_windows.append(window)

  runner_params.docking_params.dockable_windows = dockable_windows
  if setup_imgui_style:
    runner_params.callbacks.setup_imgui_style = setup_imgui_style
  if before_exit:
    runner_params.callbacks.before_exit = before_exit

  # the main gui is only responsible to give focus to ImGui Bundle dockable window
  def show_gui():
    if g.frame == 1:
      # Focus cannot be given at frame 0, since some additional windows will
      # be created after (and will steal the focus)
      runner_params.docking_params.focus_dockable_window("Dear ImGui Bundle")
    g.frame += 1

  def show_edit_font_scale_in_status_bar():
    imgui.set_next_item_width(imgui.get_content_region_avail().x / 10)
    _, imgui.get_style().font_scale_main = imgui.slider_float(
      "Font scale", imgui.get_style().font_scale_main, 0.5, 2
    )

  runner_params.callbacks.show_status = show_edit_font_scale_in_status_bar

  runner_params.callbacks.show_gui = show_gui
  # runner_params.callbacks.post_new_frame = gizmo.begin_frame

  def setup_imgui_config() -> None:
    imgui.get_io().config_flags |= imgui.ConfigFlags_.nav_enable_keyboard.value

  runner_params.callbacks.setup_imgui_config = setup_imgui_config

  # Part 3: Run the app
  addons = immapp.AddOnsParams()
  addons.with_markdown = True
  addons.with_node_editor = True
  addons.with_implot = True
  addons.with_implot3d = True
  addons.with_im_anim = True

  return immapp.run_async(runner_params, addons)
  ##


_show_code_states: dict[str, bool] = {}


def imgui_id(value: str, id: str) -> str:  ##
  return str(value) + "#" + "#" + str(id)
  ##


@contextmanager
def imgui_colorify_button(hue: float):  ##
  im.push_style_color(im.Col_.button, im.ImColor.hsv(hue, 0.6, 0.6).value)
  im.push_style_color(im.Col_.button_hovered, im.ImColor.hsv(hue, 0.7, 0.7).value)
  im.push_style_color(im.Col_.button_active, im.ImColor.hsv(hue, 0.8, 0.8).value)
  yield
  im.pop_style_color(3)
  ##


def _show_module_demo(
  demo_filename: str, demo_function: Callable[[], None], show_code: bool = False
) -> None:  ##
  if imgui.get_frame_count() < 2:  # cf https://github.com/pthom/imgui_bundle/issues/293
    return
  if show_code:
    current = _show_code_states.get(demo_filename, False)
    _, current = imgui.checkbox(imgui_id("Show code", demo_filename), current)
    _show_code_states[demo_filename] = current
    if current:
      demo_utils.show_python_vs_cpp_file(demo_filename, 40)
  demo_function()
  ##


@dataclass
class _DemoDetails:  ##
  label: str
  demo_module: ModuleType
  show_code: bool = False
  ##


@dataclass
class _DemoGroup:  ##
  """A group of demos shown as collapsing headers inside a single tab."""

  label: str
  demos: List[_DemoDetails] = field(default_factory=list)
  ##


def _show_group_gui(group: _DemoGroup) -> None:  ##
  """Gui function for a grouped tab: each sub-demo is a collapsing header."""
  if imgui.get_frame_count() < 2:
    return
  for demo in group.demos:
    demo_module_name = demo.demo_module.__name__.split(".")[-1]
    if imgui.collapsing_header(demo.label):
      imgui.indent()
      _show_module_demo(demo_module_name, demo.demo_module.demo_gui, demo.show_code)
      imgui.unindent()
  ##


# !banner: math
# ███╗   ███╗ █████╗ ████████╗██╗  ██╗
# ████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
# ██╔████╔██║███████║   ██║   ███████║
# ██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
# ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
# ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝


@t.overload
def scale_to_fit(inner: tuple[int, int], outer: tuple[int, int]) -> float: ...


@t.overload
def scale_to_fit(inner: tuple[float, float], outer: tuple[float, float]) -> float: ...


@t.overload
def scale_to_fit(inner: glm.vec2, outer: glm.vec2) -> float: ...


def scale_to_fit(inner, outer):  ##
  if hasattr(inner, "x"):
    scale_x = outer.x / inner.x
    scale_y = outer.y / inner.y
  else:
    scale_x = outer[0] / inner[0]
    scale_y = outer[1] / inner[1]
  return min(scale_x, scale_y)
  ##


def mat_scale(m: mat3, v: float | vec2) -> mat3:
  return glm.scale(m, vec2(1, 1) * v)  # type: ignore


def mat_translate(m: mat3, offset: vec2) -> mat3:
  return glm.translate(m, offset)  # type: ignore


@t.overload
def m_pos(m: mat3, p: vec2, /) -> vec2: ...


@t.overload
def m_pos(m: mat4, p: vec3, /) -> vec3: ...  # pyright: ignore[reportOverlappingOverload]


def m_pos(m, p):
  if isinstance(m, mat3):
    return (m * vec3(p, 1)).xy  # type: ignore
  else:
    return (m * vec4(p, 1)).xyz  # type: ignore


@t.overload
def m_size(m: mat3, v: int | float) -> float | int: ...


@t.overload
def m_size(m: mat3, v: vec2) -> vec2: ...


def m_size(m: mat3, v: vec2 | float | int) -> vec2 | float | int:
  result = (m * vec3(vec2(1, 1) * v, 0)).xy  # type: ignore
  if isinstance(v, (int, float)):
    return result.x
  return result


from bf_game import *  # noqa
