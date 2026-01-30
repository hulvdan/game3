# Imports.  {  ###
import json
import os
import re
import shutil
import string
import tempfile
from collections import defaultdict
from dataclasses import dataclass
from enum import Enum, unique
from functools import partial
from math import radians
from pathlib import Path
from typing import Any, TypeAlias

import bf_lib as bf
import pytest
import rpp
from bf_game import *  # noqa
from bf_typer import timing, timing_mark
from PIL import Image

# }


@timing
def get_sounds_that_reaper_would_export() -> set[str]:
    # {  ###
    sounds: set[str] = set()

    project = rpp.loads((bf.ASSETS_DIR / "sfx" / "src" / "sfx.rpp").read_text())
    for t in project.findall(".//TRACK"):
        for f in t.findall(".//FILE"):
            subproject_path = Path(f[1])
            subproject = rpp.loads(
                (
                    bf.ASSETS_DIR / "sfx" / "src" / "_sfx" / subproject_path.name
                ).read_text()
            )

            for marker in subproject.findall(".//MARKER"):
                marker_name = marker[3]
                marker_number = marker[1]
                if marker_name not in ("=START", "=END"):
                    sounds.add(
                        "{}__{:02}".format(subproject_path.stem, int(marker_number))
                    )

    return sounds
    # }


@timing
def do_audio(platform: bf.BuildPlatform) -> None:
    # {  ###
    AUDIO_SRC_DIR = bf.ASSETS_DIR / "sfx"
    AUDIO_DST_DIR = bf.RES_DIR
    AUDIO_POST_DST_DIR = bf.RES_DIR
    if platform.is_web():
        AUDIO_POST_DST_DIR = bf.PROJECT_DIR / "resp"
    bf.recursive_mkdir(AUDIO_DST_DIR)
    bf.recursive_mkdir(AUDIO_POST_DST_DIR)
    for folder in {AUDIO_DST_DIR, AUDIO_POST_DST_DIR}:
        for f in folder.glob("*.ogg"):
            f.unlink()

    src_files = {p for p in AUDIO_SRC_DIR.glob("*.ogg") if p.is_file()}

    # Removing sound files that wouldn't be exported by reaper.
    allowed_sounds = get_sounds_that_reaper_would_export()
    for src_file in src_files:
        if src_file.stem.startswith("music_"):
            continue
        if src_file.stem not in allowed_sounds:
            src_file.unlink()
    # }


# def downscale_images(downscale_factors: list[int]) -> None:
#     # {  ###
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
#     # }


@timing
def do_generate(platform: bf.BuildPlatform, build_type: bf.BuildType) -> None:
    do_audio(platform)


###
