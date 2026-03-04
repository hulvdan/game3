## Imports
import json
from math import radians
from pathlib import Path

import bf_lib as bf
import rpp
import yaml
from bf_game import *  # noqa
from bf_typer import timing
from google.protobuf import json_format

##


@timing
def get_sounds_that_reaper_would_export() -> set[str]:  ##
  sounds: set[str] = set()

  project = rpp.loads((bf.ASSETS_DIR / "sfx" / "src" / "sfx.rpp").read_text())
  for t in project.findall(".//TRACK"):
    for f in t.findall(".//FILE"):
      subproject_path = Path(f[1])
      subproject = rpp.loads(
        (bf.ASSETS_DIR / "sfx" / "src" / "_sfx" / subproject_path.name).read_text()
      )

      for marker in subproject.findall(".//MARKER"):
        marker_name = marker[3]
        marker_number = marker[1]
        if marker_name not in ("=START", "=END"):
          sounds.add("{}__{:02}".format(subproject_path.stem, int(marker_number)))

  return sounds
  ##


@timing
def do_audio(_platform: bf.BuildPlatform) -> None:  ##
  AUDIO_SRC_DIR = bf.ASSETS_DIR / "sfx"
  src_files = {p for p in AUDIO_SRC_DIR.glob("*.ogg") if p.is_file()}

  # Removing sound files that wouldn't be exported by reaper.
  allowed_sounds = get_sounds_that_reaper_would_export()
  for src_file in src_files:
    if src_file.stem.startswith("music_"):
      continue
    if src_file.stem not in allowed_sounds:
      src_file.unlink()
  ##


# def downscale_images(downscale_factors: list[int]) -> None:  ##
#     assert downscale_factors, downscale_factors
#
#     images_to_downscale = list(bf.ART_TEXTURES_DIR.glob("*.png"))
#
#     for factor in downscale_factors:
#         assert factor >= 1, factor
#
#         bf.log.info("Downscaling by {}".format(factor))
#
#         export_dir = bf.TEMP_ART_DIR / f"d{factor}"
#         bf.recursive_mkdir(export_dir)
#
#         for image_path in images_to_downscale:
#             s1 = image_path.stat()
#
#             export_image_path = export_dir / image_path.name
#
#             if export_image_path.exists() and (
#                 s1.st_mtime_ns == export_image_path.stat().st_mtime_ns
#             ):
#                 continue
#
#             im = Image.open(image_path)
#             im.thumbnail(
#                 (im.size[0] // factor, im.size[1] // factor), Image.Resampling.LANCZOS
#             )
#             im.save(export_image_path, "PNG")
#             os.utime(export_image_path, ns=(s1.st_atime_ns, s1.st_mtime_ns))
#     ##


@timing
def do_generate(platform: bf.BuildPlatform, _build_type: bf.BuildType) -> None:
  bf.run_command("uv run yamllint src/game/glib.yaml -s -f parsable")
  with open("src/game/glib.yaml", encoding="utf-8") as glib_file:
    glib = yaml.safe_load(glib_file)
    glib.pop("_anchors", None)

  ## Codegen glib.gd + glib.binpb + glib itself
  temp_glib_path = Path(".temp/glib.gd")
  temp_glib_path.unlink(missing_ok=True)
  bf.run_command("""
        godot
        --headless
        -s addons/protobuf/protobuf_cmdln.gd
        --input=src/game/glib.proto
        --output=.temp/glib.gd
    """)
  assert temp_glib_path.exists(), "Failed to generate glib.gd from glib.proto!"
  Path("src/game/glib_pb2.py").unlink(missing_ok=True)
  bf.run_command(r"""
        .\cli\protoc.exe
        --python_out=cli
        --proto_path=src/game
        src/game/glib.proto
    """)
  assert Path("cli/glib_pb2.py").exists(), (
    "Failed to generate glib_pb2.py from glib.proto!"
  )

  with Path("src/codegen/nolint/glib.gd").open(
    "w", encoding="utf-8", newline="\n"
  ) as codegen_file:
    codegen_file.write("""extends Node
static var v: Lib = Lib.new()

func ToV2(value: GV2) -> Vector2:
    return Vector2(value.get_x(), value.get_y())

func ToV2i(value: GV2i) -> Vector2i:
    return Vector2i(value.get_x(), value.get_y())

func ToV3(value: GV3) -> Vector3:
    return Vector3(value.get_x(), value.get_y(), value.get_z())

func ToV3i(value: GV3i) -> Vector3i:
    return Vector3i(value.get_x(), value.get_y(), value.get_z())

static var _glib_mtime: int = -1

const glib_binary_path: String = "res://assets/glib.binpb"

func _reload_gamelib() -> void:
    _glib_mtime = FileAccess.get_modified_time(glib_binary_path)
    var glib_file = FileAccess.open(glib_binary_path, FileAccess.READ)
    assert(glib_file)
    var glib_bytes: PackedByteArray = glib_file.get_buffer(glib_file.get_length())
    glib_file.close()
    var err = v.from_bytes(glib_bytes)
    assert(not err)

func _ready() -> void:
    _reload_gamelib()
    # get_tree().debug_collisions_hint = glib.v.get_debug_collisions() != 0

func _physics_process(_dt: float) -> void:
    if _glib_mtime != FileAccess.get_modified_time(glib_binary_path):
        v = Lib.new()
        _reload_gamelib()

""")

    codegen_file.write(Path(".temp/glib.gd").read_text(encoding="utf-8"))

    def genline(value):
      codegen_file.write(value)
      codegen_file.write("\n")

    do_audio(platform)
    for func in bf.glib_processing_functions:
      func(genline, glib)

  bf.run_command("gdscript-formatter src/codegen/nolint/glib.gd")
  ##

  degrees_to_radians_recursive_transform(glib)

  out_path = Path(".temp") / "glib.json"
  bf.recursive_mkdir(out_path.parent)
  with open(out_path, "w", encoding="utf-8") as out_file:
    json.dump(glib, out_file, indent=2)

  ## Validating no invalid fields specified in glib.
  import glib_pb2  # noqa: PLC0415

  lib = glib_pb2.Lib()  # type: ignore
  json_format.Parse(json.dumps(glib), lib)
  ##

  bf.run_command(
    rf"buf convert src/game/glib.proto --type=Lib --from={out_path} --to=assets/glib.binpb --validate"
  )


def degrees_to_radians_recursive_transform(gamelib_recursed) -> None:  ##
  if not isinstance(gamelib_recursed, dict):
    return

  keys_to_replace = [
    key for key in gamelib_recursed if key.endswith(("_degrees", "_radians"))
  ]

  for key in keys_to_replace:
    value = gamelib_recursed.pop(key)
    if isinstance(value, (int, float)):
      if key.endswith("_degrees"):
        value = radians(value)
      gamelib_recursed[key.removesuffix("_degrees").removesuffix("_radians")] = value
    else:
      assert value is None

  del keys_to_replace

  for value in gamelib_recursed.values():
    if isinstance(value, dict):
      degrees_to_radians_recursive_transform(value)

    elif isinstance(value, list):
      for v in value:
        if isinstance(v, dict):
          degrees_to_radians_recursive_transform(v)
  ##
