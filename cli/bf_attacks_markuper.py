#
## Imports
import math
import random
import shutil
import tempfile
import typing as t
from abc import ABC, abstractmethod
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import IntEnum, unique
from functools import partial
from math import pi
from pathlib import Path
from typing import Any, Callable, Generator, Generic, Iterable, Self, TypeAlias, TypeVar

import bf_lib as bf
import glib_pb2
import numpy as np
import toml
import yaml
from bf_glib import load_glib
from bf_typer import command
from glib_pb2 import (
  GV2,
  GV3,
  GV4,
  GAbility,
  GAttack,
  GCollider,
  GColliderAnimated,
  GCreature,
  GImpulseData,
  GKeyframeBool,
  GKeyframeFloat,
  GKeyframeInt32,
  GKeyframeString,
  GKeyframeV2,
  GKeyframeV3,
  GKeyframeV4,
  Lib,
)
from google.protobuf.internal.containers import RepeatedCompositeFieldContainer
from google.protobuf.json_format import MessageToDict, ParseDict
from google.protobuf.message import Message
from imgui_bundle import ImVec2, ImVec2_Pydantic, hello_imgui, imguizmo
from imgui_bundle import imgui as im
from pydantic import BaseModel
from pydantic import Field as PydanticField
from pyglm import glm
from pyglm.glm import mat4, radians, vec2, vec3, vec4

##


class _ExportAttack(BaseModel):  ##
  class _Impulse(BaseModel):
    id: int
    at: int
    distance: float
    dur: int
    pow: float
    rotation: int

  class _ExportMelee(BaseModel):
    colliders: list[dict]

  duration_frames: int
  stamina_consumption_frame: int
  tracking: list[dict]
  impulses: list[_Impulse] = PydanticField(default_factory=list)
  melee: _ExportMelee | None = PydanticField(None)
  conditions: list[dict]
  ##


## def _into_proto(x)
@t.overload
def _to_proto(x: bool) -> bool: ...
@t.overload
def _to_proto(x: int) -> int: ...
@t.overload
def _to_proto(x: float) -> float: ...
@t.overload
def _to_proto(x: vec2) -> GV2: ...
@t.overload
def _to_proto(x: vec3) -> GV3: ...
@t.overload
def _to_proto(x: vec4) -> GV4: ...
@t.overload
def _to_proto(x: str) -> str: ...
def _to_proto(x):
  match x:
    case vec2():
      return GV2(x=x.x, y=x.y)
    case vec3():
      return GV3(x=x.x, y=x.y, z=x.z)
    case vec4():
      return GV4(x=x.x, y=x.y, z=x.z, w=x.w)
    case _:
      return x


##


## def _from_proto(x)
@t.overload
def _from_proto(x: bool) -> bool: ...
@t.overload
def _from_proto(x: int) -> int: ...
@t.overload
def _from_proto(x: float) -> float: ...
@t.overload
def _from_proto(x: GV2) -> vec2: ...
@t.overload
def _from_proto(x: GV3) -> vec3: ...
@t.overload
def _from_proto(x: GV4) -> vec4: ...
@t.overload
def _from_proto(x: str) -> str: ...
def _from_proto(x):
  match x:
    case GV2():
      return vec2(x.x, x.y)
    case GV3():
      return vec3(x.x, x.y, x.z)
    case GV4():
      return vec4(x.x, x.y, x.z, x.w)
    case _:
      return x


##


## _GKeyframe: TypeAlias
# [[[cog
# import re, pathlib
# keyframe_types = re.findall(
#   'message (GKeyframe[a-zA-Z0-9_]+) ',
#   pathlib.Path('src/game/glib.proto').read_text(encoding='utf-8')
# )
# print('_GKeyframe: TypeAlias = {}'.format(' | '.join(keyframe_types)))
# cog]]]
_GKeyframe: TypeAlias = (
  GKeyframeBool
  | GKeyframeInt32
  | GKeyframeFloat
  | GKeyframeString
  | GKeyframeV2
  | GKeyframeV3
  | GKeyframeV4
)
# [[[end]]] ##


def _set_proto_field(instance, field: str, value: Any) -> None:  ##
  if isinstance(f := getattr(instance, field), Message):
    f.CopyFrom(value)
  else:
    setattr(instance, field, value)
  ##


## _gcollider_keyframe_fields: list[str]
# [[[cog
# import ast, pathlib
# tree = ast.parse(pathlib.Path("cli/glib_pb2.pyi").read_text(encoding="utf-8"))
# _gcollider_keyframe_fields = [
#     a.target.id
#     for cls in tree.body if (isinstance(cls, ast.ClassDef) and cls.name == "GColliderAnimated")
#     for a in cls.body if isinstance(a, ast.AnnAssign)
#     and isinstance(a.annotation, ast.Subscript)
#     and isinstance(a.annotation.value, ast.Attribute)
#     and (a.annotation.value.attr == "RepeatedCompositeFieldContainer")
#     and a.annotation.slice.id.startswith("GKeyframe")
# ]
# print(f"{_gcollider_keyframe_fields=}")
# cog]]]
_gcollider_keyframe_fields = [
  "tr",
  "is_active",
  "circle__radius",
  "capsule__radius",
  "capsule__spread",
  "capsule__rotation",
  "polygon__dist_min",
  "polygon__dist_max",
  "polygon__rotation",
  "polygon__spread_angle",
]
# [[[end]]] ##


_GContainer: t.TypeAlias = RepeatedCompositeFieldContainer
_GKeyframesContainer: t.TypeAlias = _GContainer[_GKeyframe]

T = t.TypeVar("T")
T1 = t.TypeVar("T1")
T2 = t.TypeVar("T2")
T3 = t.TypeVar("T3")
T4 = t.TypeVar("T4")
T5 = t.TypeVar("T5")


## Consts
ASSETS_ATTACKS_DIR = bf.ASSETS_DIR / "attacks"
ATTACKS_FPS = 60
_MAX_ATTACK_FRAMES_DURATION = 10 * ATTACKS_FPS
_STEP_TRANSLATE = 0.25
_STEP_ROTATE = 15
_STEP_SCALE = 0.25
_MAX_OFFSET: float = 10.0
_MIN_RADIUS: float = 0.125
_MAX_RADIUS: float = 5.0
_MAX_SPREAD: float = 10.0
##


## Setup
_ImpulseID: TypeAlias = int
_ColliderID: TypeAlias = int
_ConditionID: TypeAlias = int
_KeyframeID: TypeAlias = int


_keyframe_off = ImVec2(5, 8)
_keyframe_quad_points = [
  ImVec2(_keyframe_off.x, 0),
  ImVec2(0, -_keyframe_off.y),
  ImVec2(-_keyframe_off.x, 0),
  ImVec2(0, _keyframe_off.y),
]


def imgui_error_top_bar(message: str) -> None:
  im.push_style_color(im.Col_.child_bg, (0.2, 0.1, 0.1, 1.0))
  im.begin_child("visualizer_error_bar", ImVec2(im.get_content_region_avail().x, 25))
  im.text(message)
  im.end_child()
  im.pop_style_color()


def imgui_draw_cross() -> None:
  draw = im.get_window_draw_list()
  size = im.get_content_region_avail()
  pos = im.get_cursor_screen_pos()
  draw.add_line(pos, pos + size, im.get_color_u32(im.Col_.border), 2)
  draw.add_line(
    pos + ImVec2(0, size.y), pos + ImVec2(size.x, 0), im.get_color_u32(im.Col_.border), 2
  )


def imgui_color_hsva(h: float, s: float = 1, v: float = 1, a: float = 1) -> im.ImColor:
  result = im.ImColor.hsv(h, s, v)
  result.value.w = a
  return result


def imgui_fade_replace(v: im.ImColor, a: float) -> im.ImColor:
  result = im.ImColor()
  result.value.x = v.value.x
  result.value.y = v.value.y
  result.value.z = v.value.z
  result.value.w = a
  return result


def imgui_fade_multiply(v: im.ImColor, a: float) -> im.ImColor:
  result = im.ImColor()
  result.value.x = v.value.x
  result.value.y = v.value.y
  result.value.z = v.value.z
  result.value.w = v.value.w * a
  return result


def imgui_color_to_u32(v: im.ImColor) -> int:
  return im.color_convert_float4_to_u32((v.value.x, v.value.y, v.value.z, v.value.w))


# [[[cog
# import cog
# for name, h, s, v in [
#   ('RED',        0 / 7, 1.0, 1.0),
#   ('YELLOW',     1 / 7, 1.0, 1.0),
#   ('GREEN',      2 / 7, 1.0, 1.0),
#   ('CYAN',       3 / 7, 1.0, 1.0),
#   ('LIGHT_BLUE', 4 / 7, 1.0, 1.0),
#   ('BLUE',       5 / 7, 1.0, 1.0),
#   ('PURPLE',     6 / 7, 1.0, 1.0),
#   ('WHITE',      0,     0.0, 1.0),
#   ('GRAY',       0,     0.0, 0.5),
#   ('BLACK',      0,     0.0, 0.0),
# ]:
#   print(f"HUE_{name} = {h:.3f}")
#   print(f"COLOR_{name} = imgui_color_hsva({h:.3f}, {s:.3f}, {v:.3f})")
#   print(f"COLOR_{name}_FADED = imgui_fade_replace(COLOR_{name}, 0.25)")
#   print(f"COLOR_{name}_U32 = imgui_color_to_u32(COLOR_{name})")
#   print(f"COLOR_{name}_FADED_U32 = imgui_color_to_u32(COLOR_{name}_FADED)")
# cog]]]
HUE_RED = 0.000
COLOR_RED = imgui_color_hsva(0.000, 1.000, 1.000)
COLOR_RED_FADED = imgui_fade_replace(COLOR_RED, 0.25)
COLOR_RED_U32 = imgui_color_to_u32(COLOR_RED)
COLOR_RED_FADED_U32 = imgui_color_to_u32(COLOR_RED_FADED)
HUE_YELLOW = 0.143
COLOR_YELLOW = imgui_color_hsva(0.143, 1.000, 1.000)
COLOR_YELLOW_FADED = imgui_fade_replace(COLOR_YELLOW, 0.25)
COLOR_YELLOW_U32 = imgui_color_to_u32(COLOR_YELLOW)
COLOR_YELLOW_FADED_U32 = imgui_color_to_u32(COLOR_YELLOW_FADED)
HUE_GREEN = 0.286
COLOR_GREEN = imgui_color_hsva(0.286, 1.000, 1.000)
COLOR_GREEN_FADED = imgui_fade_replace(COLOR_GREEN, 0.25)
COLOR_GREEN_U32 = imgui_color_to_u32(COLOR_GREEN)
COLOR_GREEN_FADED_U32 = imgui_color_to_u32(COLOR_GREEN_FADED)
HUE_CYAN = 0.429
COLOR_CYAN = imgui_color_hsva(0.429, 1.000, 1.000)
COLOR_CYAN_FADED = imgui_fade_replace(COLOR_CYAN, 0.25)
COLOR_CYAN_U32 = imgui_color_to_u32(COLOR_CYAN)
COLOR_CYAN_FADED_U32 = imgui_color_to_u32(COLOR_CYAN_FADED)
HUE_LIGHT_BLUE = 0.571
COLOR_LIGHT_BLUE = imgui_color_hsva(0.571, 1.000, 1.000)
COLOR_LIGHT_BLUE_FADED = imgui_fade_replace(COLOR_LIGHT_BLUE, 0.25)
COLOR_LIGHT_BLUE_U32 = imgui_color_to_u32(COLOR_LIGHT_BLUE)
COLOR_LIGHT_BLUE_FADED_U32 = imgui_color_to_u32(COLOR_LIGHT_BLUE_FADED)
HUE_BLUE = 0.714
COLOR_BLUE = imgui_color_hsva(0.714, 1.000, 1.000)
COLOR_BLUE_FADED = imgui_fade_replace(COLOR_BLUE, 0.25)
COLOR_BLUE_U32 = imgui_color_to_u32(COLOR_BLUE)
COLOR_BLUE_FADED_U32 = imgui_color_to_u32(COLOR_BLUE_FADED)
HUE_PURPLE = 0.857
COLOR_PURPLE = imgui_color_hsva(0.857, 1.000, 1.000)
COLOR_PURPLE_FADED = imgui_fade_replace(COLOR_PURPLE, 0.25)
COLOR_PURPLE_U32 = imgui_color_to_u32(COLOR_PURPLE)
COLOR_PURPLE_FADED_U32 = imgui_color_to_u32(COLOR_PURPLE_FADED)
HUE_WHITE = 0.000
COLOR_WHITE = imgui_color_hsva(0.000, 0.000, 1.000)
COLOR_WHITE_FADED = imgui_fade_replace(COLOR_WHITE, 0.25)
COLOR_WHITE_U32 = imgui_color_to_u32(COLOR_WHITE)
COLOR_WHITE_FADED_U32 = imgui_color_to_u32(COLOR_WHITE_FADED)
HUE_GRAY = 0.000
COLOR_GRAY = imgui_color_hsva(0.000, 0.000, 0.500)
COLOR_GRAY_FADED = imgui_fade_replace(COLOR_GRAY, 0.25)
COLOR_GRAY_U32 = imgui_color_to_u32(COLOR_GRAY)
COLOR_GRAY_FADED_U32 = imgui_color_to_u32(COLOR_GRAY_FADED)
HUE_BLACK = 0.000
COLOR_BLACK = imgui_color_hsva(0.000, 0.000, 0.000)
COLOR_BLACK_FADED = imgui_fade_replace(COLOR_BLACK, 0.25)
COLOR_BLACK_U32 = imgui_color_to_u32(COLOR_BLACK)
COLOR_BLACK_FADED_U32 = imgui_color_to_u32(COLOR_BLACK_FADED)
# [[[end]]]


T = TypeVar("T")


_APP_STATE_FILE_PATH = bf.PROJECT_DIR / "tool_attack_markuper_app_save_state.toml"


def _log(level, *args):
  hello_imgui.log(level, "".join((datetime.now().strftime("%H:%M:%S "), *args)))


LOGD = partial(_log, hello_imgui.LogLevel.debug)
LOGI = partial(_log, hello_imgui.LogLevel.info)
LOGW = partial(_log, hello_imgui.LogLevel.warning)
LOGE = partial(_log, hello_imgui.LogLevel.error)


gizmo = imguizmo.im_guizmo

Matrix16: TypeAlias = imguizmo.im_guizmo.Matrix16
Matrix6: TypeAlias = imguizmo.im_guizmo.Matrix6
Matrix3: TypeAlias = imguizmo.im_guizmo.Matrix3

SNAP_TRANSLATE = Matrix3()
SNAP_ROTATE = Matrix3()
SNAP_SCALE = Matrix3()
SNAP_TRANSLATE.values[:] = _STEP_TRANSLATE
SNAP_ROTATE.values[:] = _STEP_ROTATE
SNAP_SCALE.values[:] = _STEP_SCALE


# fmt: off
def identity_matrix() ->  Matrix16:
  return gizmo.Matrix16([
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1])
# fmt: on


def lerp_Matrix16(
  v1: Matrix16, v2: Matrix16, t: float, step_translate: float | None = None
) -> Matrix16:
  c1 = gizmo.decompose_matrix_to_components(v1)
  c2 = gizmo.decompose_matrix_to_components(v2)
  c = gizmo.MatrixComponents()
  c.translation.values[:] = c1.translation.values * (1 - t) + c2.translation.values * t
  if step_translate is not None:
    assert step_translate > 0
    for i in range(3):
      c.translation.values[i] = bf.round_to_step(c.translation.values[i], step_translate)
  c.rotation.values[:] = c1.rotation.values
  c.scale.values[:] = c1.scale.values
  return gizmo.recompose_matrix_from_components(c)


vec2_zero = vec2()
vec2_one = vec2(1, 1)
vec2_up = vec2(0, 1)
vec2_down = vec2(0, -1)
vec2_right = vec2(1, 0)
vec2_left = vec2(-1, 0)

vec3_zero = vec3()
vec3_one = vec3(1, 1, 1)
vec3_up = vec3(0, 1, 0)
vec3_down = vec3(0, -1, 0)
vec3_right = vec3(1, 0, 0)
vec3_left = vec3(-1, 0, 0)
vec3_forward = vec3(0, 0, 1)
vec3_backward = vec3(0, 0, -1)


def _dump_app_state():
  LOGD("Saving...")
  with tempfile.NamedTemporaryFile(
    "w", encoding="utf-8", delete=False, suffix=".toml", newline="\n"
  ) as out:
    out_path = Path(out.name)
    toml.dump(g.dump().model_dump(), out)
  shutil.move(out_path, _APP_STATE_FILE_PATH)


_gizmo_restricted: bool = False


@contextmanager
def _gizmo_restrict(
  m: Matrix16,
  mask: tuple[bool, bool, bool],
  disable_translation_x: bool = False,
  disable_translation_y: bool = False,
  disable_translation_z: bool = False,
):
  global _gizmo_restricted
  assert not _gizmo_restricted

  _gizmo_restricted = True
  gizmo.set_axis_mask(*mask)
  comps = gizmo.decompose_matrix_to_components(m)
  yield
  gizmo.set_axis_mask(True, True, True)
  comps_new = gizmo.decompose_matrix_to_components(m)

  should_override = False
  for i, v in enumerate(
    (disable_translation_x, disable_translation_y, disable_translation_z)
  ):
    if v:
      if comps_new.translation.values[i] != (c := comps.translation.values[i]):
        comps_new.translation.values[i] = c
        should_override = True
  if should_override:
    m.values[:] = gizmo.recompose_matrix_from_components(comps_new).values
  _gizmo_restricted = False


@t.overload
def _tuplify(v: vec2) -> tuple[float, float]: ...  # pyright: ignore[reportOverlappingOverload]


@t.overload
def _tuplify(v: vec3) -> tuple[float, float, float]: ...  # pyright: ignore[reportOverlappingOverload]


def _tuplify(v):
  if isinstance(v, vec2):
    return (v.x, v.y)
  else:
    return (v.x, v.y, v.z)


def _to_vec2(v: ImVec2_Pydantic) -> vec2:
  return vec2(v.x, v.y)


def _to_Matrix16(m: mat4) -> Matrix16:
  result = Matrix16()
  np.copyto(result.values, np.frombuffer(m.to_bytes(), dtype=np.float32))
  return result


def _to_mat4(m: Matrix16) -> mat4:
  return mat4(*m.values.reshape((4, 4)).flatten())


##


@command
def tool_attacks_markuper() -> None:
  ## Filling g.keyframe_field_types_per_collider_type
  field_tr = _KeyframeTypeV2(step=_STEP_TRANSLATE)
  field_is_active = _KeyframeTypeBool(True)
  _POLYGON_MIN_RADIUS = 0.125
  g.attack_keyframe_field_types = {"tracking": _KeyframeTypeBool(True)}
  g.keyframe_field_types_per_collider_type = {
    _ColliderType.CIRCLE.value: {
      "is_active": field_is_active,
      "tr": field_tr,
      "circle__radius": _KeyframeTypeFloat(
        default=0.5,
        step=_STEP_TRANSLATE,
        step_fast=1,
        min=_MIN_RADIUS,
        max=_MAX_RADIUS,
        fmt="%.2f",
      ),
    },
    _ColliderType.CAPSULE.value: {
      "is_active": field_is_active,
      "tr": field_tr,
      "capsule__radius": _KeyframeTypeFloat(
        default=0.5,
        step=_STEP_TRANSLATE,
        step_fast=1,
        min=_MIN_RADIUS,
        max=_MAX_RADIUS,
        fmt="%.2f",
      ),
      "capsule__spread": _KeyframeTypeFloat(
        default=1,
        step=_STEP_TRANSLATE,
        step_fast=1,
        min=0,
        max=_MAX_SPREAD,
        fmt="%.2f",
      ),
      "capsule__rotation": _KeyframeTypeFloat(
        default=0,
        step=_STEP_ROTATE,
        step_fast=90,
        fmt="%.2f",
      ),
    },
    _ColliderType.POLYGON.value: {
      "is_active": field_is_active,
      "tr": field_tr,
      "polygon__dist_min": _KeyframeTypeFloat(
        default=0.5, step=_STEP_TRANSLATE, step_fast=1, min=0, max=_MAX_OFFSET, fmt="%.2f"
      ),
      "polygon__dist_max": _KeyframeTypeFloat(
        default=0.5,
        step=_STEP_TRANSLATE,
        step_fast=1,
        min=_POLYGON_MIN_RADIUS,
        max=_MAX_OFFSET,
        fmt="%.2f",
      ),
      "polygon__rotation": _KeyframeTypeFloat(default=0, step=_STEP_ROTATE, step_fast=90),
      "polygon__spread_angle": _KeyframeTypeFloat(
        default=45,
        step=5,
        step_fast=15,
        min=5,
        max=165,
        fmt="%.0f",
      ),
    },
  }

  for field_name, field_type in GColliderAnimated.__annotations__:
    if t.get_origin(field_type) is not RepeatedCompositeFieldContainer:
      continue
    args = t.get_args(field_type)
    if len(args) != 1:
      continue

    if args[0].__name__.startswith("GKeyframe"):
      if "__" in field_name:
        # field is only for specific collider type (e.g. circle__*, capsule__*)
        collider_type = _ColliderType[field_name.split("__", 1)[0].upper()].value
        assert collider_type in g.keyframe_field_types_per_collider_type

      else:
        # field is shared among colliders (e.g. tr, is_active)
        for fields in g.keyframe_field_types_per_collider_type.values():
          assert field_name in fields
  ##

  ##
  glib = load_glib(bf.BuildPlatform.Win, bf.BuildType.Debug, is_game=False)
  g.glib = t.cast("Lib", ParseDict(glib, Lib()))

  def transform_gattack(
    attack_: GAttack, parent_ability, parent_creature
  ) -> _TransientAttack:
    colliders = []
    attack = _TransientAttack(
      ref=attack_,
      parent_ability=parent_ability,
      parent_creature=parent_creature,
      colliders=colliders,
    )
    if not attack.ref.tracking:
      attack.ref.tracking.append(GKeyframeBool(id=_next_keyframe_id(attack.ref.tracking)))
    if attack_.melee:
      for collider_ in attack_.melee.colliders:
        colliders.append(_TransientColliderAnimated(ref=collider_))
    return attack

  for ability_ in g.glib.abilities:
    attacks = []
    ability = _TransientAbility(ref=ability_, attacks=attacks)
    for attack in ability_.attacks:
      if not attack.debug_mirrored:
        attacks.append(transform_gattack(attack, ability, None))
    g.abilities.append(ability)

  for creature_ in g.glib.creatures[1:]:
    attacks = []
    creature = _TransientCreature(ref=creature_, attacks=attacks)
    for attack in creature_.attacks:
      if not attack.debug_mirrored:
        attacks.append(transform_gattack(attack, None, creature))
    g.creatures.append(creature)

  g.validate()

  loaded_state: _AppSaveState | None = None
  if _APP_STATE_FILE_PATH.exists():
    with bf.sane_readable_file(_APP_STATE_FILE_PATH) as in_file:
      state_data = toml.load(in_file)
    loaded_state = _AppSaveState(**state_data)
    g.load(loaded_state)

  g.validate()

  if atk := g.ref_selected_attack:
    if atk.ref.melee and atk.ref.melee.colliders:
      atk.collider.to_select = atk.colliders[0]

  def setup_imgui_style():
    if loaded_state:
      im.get_style().font_scale_main = loaded_state.font_scale_main

  bf.show_imgui(
    "Attacks Markuper",
    [
      bf.ImGuiPanel("Visualizer", _panel_visualizer),
      bf.ImGuiPanel("Explorer", _panel_explorer),
      bf.ImGuiPanel("Attack", _panel_attack_inspector),
      bf.ImGuiPanel("Timeline", _panel_timeline, scrollable=False),
      bf.ImGuiPanel("Logs", hello_imgui.log_gui),
    ],
    setup_imgui_style=setup_imgui_style,
    post_new_frame=_post_new_frame,
    before_exit=_dump_app_state,
    show_status=_show_status,
  )
  ##


@dataclass(slots=True, frozen=True)
class _SelectedKeyframe:  ##
  id: int
  key: str  # e.g. "keyframe_radius_0"
  field: str  # e.g. "radius" / "spread"
  index_timeline: int
  index_inside_list: int

  def validate(self):
    assert self.id > 0
    assert self.index_timeline >= 0

  ##


@unique
class _ColliderType(IntEnum):  ##
  INVALID = 0
  CIRCLE = 1
  CAPSULE = 2
  POLYGON = 3

  @classmethod
  def get_name(cls, value: int) -> str:
    return next(x.name for x in cls if x.value == value)

  ##


@unique
class _KeyframeTypeEnum(IntEnum):  ##
  BOOL = 1
  INT = 2
  FLOAT = 3
  VEC2 = 4
  ##


@dataclass(slots=True)
class _KeyframeType(ABC, Generic[T1, T2]):  ##
  line_spanning_rows: t.ClassVar[int] = 1

  @classmethod
  @abstractmethod
  def proto_class(cls) -> type[T2]: ...

  @abstractmethod
  def make_default(self) -> T1: ...

  @abstractmethod
  def make_copy(self, v: T1) -> T1: ...

  @abstractmethod
  def make_lerp(self, v1: T1, v2: T1, t: float) -> T1: ...

  ##


@dataclass(slots=True)
@t.final
class _KeyframeTypeBool(_KeyframeType[bool, GKeyframeBool]):  ##
  # type_class: t.ClassVar[tuple[type, ...]] = (bool,)
  # type: t.ClassVar[KeyframeTypeEnum] = KeyframeTypeEnum.BOOL

  @classmethod
  def proto_class(cls) -> type[GKeyframeBool]:
    return GKeyframeBool

  default: bool

  def make_default(self) -> bool:
    return self.default

  def make_copy(self, v: bool) -> bool:
    return v

  def make_lerp(self, v1: bool, v2: bool, t: float) -> bool:  # noqa: ARG002
    assert 0 <= t <= 1
    return v1

  ##


@dataclass(slots=True)
@t.final
class _KeyframeTypeFloat(_KeyframeType[float, GKeyframeFloat]):  ##
  # type_class: t.ClassVar[tuple[type, ...]] = (int, float)
  # type: t.ClassVar[KeyframeTypeEnum] = KeyframeTypeEnum.FLOAT

  @classmethod
  def proto_class(cls) -> type[GKeyframeFloat]:
    return GKeyframeFloat

  default: float
  step: float
  step_fast: float
  min: float = bf.FLOAT_INF_NEG
  max: float = bf.FLOAT_INF_POS
  fmt: str = "%.3f"

  def make_default(self) -> float:
    assert self.min <= self.default <= self.max
    return self.default

  def make_copy(self, v: float) -> float:
    assert self.min <= v <= self.max
    return v

  def make_lerp(self, v1: float, v2: float, t: float) -> float:
    assert 0 <= t <= 1
    result = bf.lerp(v1, v2, t)
    assert self.min <= v1 <= self.max
    assert self.min <= v2 <= self.max
    assert self.min <= result * 1.001 <= self.max * 1.002
    if g.visualizer.round_to_step:
      result = bf.round_to_step(result, self.step)
    return result

  ##


def _lerp_vec2(v1: vec2, v2: vec2, t: float, step: float | None = None) -> vec2:  ##
  result = bf.lerp(v1, v2, t)
  if step is not None:
    result = bf.round_to_step(result, step)
  return result
  ##


@dataclass(slots=True)
@t.final
class _KeyframeTypeV2(_KeyframeType[GV2, GKeyframeV2]):  ##
  # type_class: t.ClassVar[tuple[type, ...]] = (GV2,)
  # type: t.ClassVar[KeyframeTypeEnum] = KeyframeTypeEnum.VEC2

  @classmethod
  def proto_class(cls) -> type[GKeyframeV2]:
    return GKeyframeV2

  line_spanning_rows: t.ClassVar[int] = 2

  default: GV2 = field(default_factory=GV2)
  step: float = _STEP_TRANSLATE

  def make_default(self) -> GV2:
    result = GV2()
    result.x = self.default.x
    result.y = self.default.y
    return result

  def make_copy(self, v: GV2) -> GV2:
    result = GV2()
    result.x = v.x
    result.y = v.y
    return result

  def make_lerp(self, v1: GV2, v2: GV2, t: float) -> GV2:
    assert 0 <= t <= 1
    result = _to_proto(
      _lerp_vec2(
        _from_proto(v1),
        _from_proto(v2),
        t,
        self.step if g.visualizer.round_to_step else None,
      )
    )
    return result

  ##


# !banner: commands
#  ██████╗ ██████╗ ███╗   ███╗███╗   ███╗ █████╗ ███╗   ██╗██████╗ ███████╗
# ██╔════╝██╔═══██╗████╗ ████║████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝
# ██║     ██║   ██║██╔████╔██║██╔████╔██║███████║██╔██╗ ██║██║  ██║███████╗
# ██║     ██║   ██║██║╚██╔╝██║██║╚██╔╝██║██╔══██║██║╚██╗██║██║  ██║╚════██║
# ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║██████╔╝███████║
#  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝


@unique
class _CommandMergeType(IntEnum):  ##
  NONE = 1
  MERGED_OKAY = 2
  MERGED_SHOULD_BE_DESTROYED = 3
  ##


@dataclass(slots=True, kw_only=True)
class _Command(ABC):  ##
  merge_id: int = field(default_factory=lambda: g.action_id)

  @abstractmethod
  def do(self) -> None: ...

  @abstractmethod
  def undo(self) -> None: ...

  def try_merge(self, _newest, /) -> _CommandMergeType:
    return _CommandMergeType.NONE

  ##


@dataclass(slots=True)
class _CommandAttack(_Command):  ##
  atk: "_TransientAttack"
  ##


@dataclass(slots=True)
@t.final
class _CommandAttackColliderCreate(_CommandAttack):  ##
  id: int
  type: _ColliderType

  def do(self) -> None:
    for collider in self.atk.colliders:
      assert collider.ref.id < self.id
    c = _TransientColliderAnimated(
      ref=GColliderAnimated(id=self.id, type=self.type.value)
    )
    for f in g.keyframe_field_types_per_collider_type[self.type.value]:
      _make_default_keyframe_at(*c.get_keyframes(f), 0)
    self.atk.colliders.append(c)
    self.atk.ref.melee.colliders.append(self.atk.colliders[-1].ref)
    self.atk.collider.to_select = self.atk.colliders[-1]

  def undo(self) -> None:
    index = next(i for i, c in enumerate(self.atk.ref.melee.colliders) if c.id == self.id)
    del self.atk.colliders[index]
    del self.atk.ref.melee.colliders[index]

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackColliderDelete(_CommandAttack):  ##
  index: int
  instance: "_TransientColliderAnimated"

  def do(self) -> None:
    c = self.atk.colliders[self.index]
    del self.atk.colliders[self.index]
    del self.atk.ref.melee.colliders[self.index]
    if self.atk.collider.ref_selected is c:
      self.atk.collider.ref_selected = None
      self.atk.collider.to_select = next(iter(self.atk.colliders), None)

  def undo(self) -> None:
    self.atk.colliders.insert(self.index, self.instance)
    self.atk.ref.melee.colliders.insert(self.index, self.instance.ref)
    self.atk.collider.to_select = self.instance

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackConditionCreate(_CommandAttack):  ##
  id: int
  type: _ColliderType

  def do(self) -> None:
    for x in self.atk.ref.conditions:
      assert x.id < self.id
    c = GCollider(id=self.id, type=self.type)
    for field_name, ktype in g.keyframe_field_types_per_collider_type[
      self.type.value
    ].items():
      _set_proto_field(c, field_name, _to_proto(ktype.make_default()))
    self.atk.ref.conditions.append(c)
    self.atk.condition.to_select = self.atk.ref.conditions[-1]

  def undo(self) -> None:
    index = next(i for i, c in enumerate(self.atk.ref.conditions) if c.id == self.id)
    del self.atk.ref.conditions[index]

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackConditionDelete(_CommandAttack):  ##
  index: int
  instance: GCollider

  def do(self) -> None:
    c = self.atk.ref.conditions[self.index]
    del self.atk.ref.conditions[self.index]
    if self.atk.condition.ref_selected is c:
      self.atk.condition.ref_selected = None
      self.atk.condition.to_select = next(iter(self.atk.ref.conditions), None)

  def undo(self) -> None:
    self.atk.ref.conditions.insert(self.index, self.instance)
    self.atk.condition.to_select = self.instance

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackImpulseCreate(_CommandAttack):  ##
  id: int

  def do(self) -> None:
    for impulse in self.atk.ref.impulses:
      assert impulse.id < self.id
    self.atk.ref.impulses.append(
      glib_pb2.GImpulseData(
        id=self.id,
        distance=1,
        dur=min(self.atk.ref.duration_frames - 1, ATTACKS_FPS),
        pow=1,
      )
    )
    self.atk.impulse.to_select = self.atk.ref.impulses[-1]

  def undo(self) -> None:
    index = next(i for i, c in enumerate(self.atk.ref.impulses) if c.id == self.id)
    del self.atk.ref.impulses[index]

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackImpulseDelete(_CommandAttack):  ##
  index: int
  instance: glib_pb2.GImpulseData

  def do(self) -> None:
    i = self.atk.ref.impulses[self.index]
    del self.atk.ref.impulses[self.index]
    if self.atk.impulse.ref_selected is i:
      self.atk.impulse.ref_selected = None
      self.atk.impulse.to_select = next(iter(self.atk.ref.impulses), None)

  def undo(self) -> None:
    self.atk.ref.impulses.insert(self.index, self.instance)
    self.atk.impulse.to_select = self.instance

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackAlterField(_CommandAttack):  ##
  field: str
  old: Any
  new: Any

  def do(self) -> None:
    _set_proto_field(self.atk.ref, self.field, _to_proto(self.new))
    self.atk.validate()

  def undo(self) -> None:
    _set_proto_field(self.atk.ref, self.field, _to_proto(self.old))
    self.atk.validate()

  def try_merge(self, newest: Self, /) -> _CommandMergeType:
    if newest.atk is not self.atk:
      return _CommandMergeType.NONE

    self.new = newest.new
    return (
      _CommandMergeType.MERGED_SHOULD_BE_DESTROYED
      if (self.old == self.new)
      else _CommandMergeType.MERGED_OKAY
    )

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackAlterKeyframeField(_CommandAttack):  ##
  field: str
  index_inside_list: int
  old: Any
  new: Any

  def do(self) -> None:
    k: _GKeyframe = self.atk.get_keyframes(self.field)[0][self.index_inside_list]
    _set_proto_field(k, "value", _to_proto(self.new))

  def undo(self) -> None:
    k: _GKeyframe = self.atk.get_keyframes(self.field)[0][self.index_inside_list]
    _set_proto_field(k, "value", _to_proto(self.old))

  def try_merge(self, newest: Self, /) -> _CommandMergeType:
    if newest.field != self.field:
      return _CommandMergeType.NONE
    if newest.index_inside_list != self.index_inside_list:
      return _CommandMergeType.NONE

    self.new = newest.new
    return (
      _CommandMergeType.MERGED_SHOULD_BE_DESTROYED
      if (self.old == self.new)
      else _CommandMergeType.MERGED_OKAY
    )

  ##


@dataclass(slots=True)
class _CommandAttackImpulse(_CommandAttack):  ##
  impulse_id: _ImpulseID

  def i(self, atk: "_TransientAttack") -> glib_pb2.GImpulseData:
    return next(x for x in atk.ref.impulses if x.id == self.impulse_id)

  ##


@dataclass(slots=True)
class _CommandAttackCollider(_CommandAttack):  ##
  collider_id: _ColliderID

  def c(self, atk: "_TransientAttack") -> "_TransientColliderAnimated":
    return next(x for x in atk.colliders if x.ref.id == self.collider_id)

  ##


@dataclass(slots=True)
class _CommandAttackCondition(_CommandAttack):  ##
  condition_id: _ConditionID

  def c(self, atk: "_TransientAttack") -> GCollider:
    return next(x for x in atk.ref.conditions if x.id == self.condition_id)

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackKeyframeAdd(_CommandAttack):  ##
  field: str
  index_timeline: int

  def do(self) -> None:
    _make_default_keyframe_at(*self.atk.get_keyframes(self.field), self.index_timeline)
    self.atk.timeline_at = self.index_timeline

  def undo(self) -> None:
    frames = self.atk.get_keyframes(self.field)[0]
    assert len(frames) > 1
    for i, fr in enumerate(frames):
      if fr.index_timeline == self.index_timeline:
        del frames[i]
        return
    raise ValueError

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackKeyframeMove(_CommandAttack):  ##
  field: str
  index_timeline_from: int
  index_timeline_to: int

  def do(self) -> None:
    frames = self.atk.get_keyframes(self.field)[0]
    fr = next(x for x in frames if x.index_timeline == self.index_timeline_from)
    fr.index_timeline = self.index_timeline_to
    self.atk.timeline_at = self.index_timeline_to

  def undo(self) -> None:
    frames = self.atk.get_keyframes(self.field)[0]
    fr = next(x for x in frames if x.index_timeline == self.index_timeline_to)
    fr.index_timeline = self.index_timeline_from
    self.atk.timeline_at = self.index_timeline_from

  def try_merge(self, newest: Self, /) -> _CommandMergeType:
    if newest.field != self.field:
      return _CommandMergeType.NONE

    self.index_timeline_to = newest.index_timeline_to
    return (
      _CommandMergeType.MERGED_SHOULD_BE_DESTROYED
      if (self.index_timeline_from == self.index_timeline_to)
      else _CommandMergeType.MERGED_OKAY
    )

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackKeyframeRemove(_CommandAttack):  ##
  field: str
  index_timeline: int
  value: Any

  def do(self) -> None:
    frames = self.atk.get_keyframes(self.field)[0]
    assert len(frames) > 1
    for i, k in enumerate(frames):
      if k.index_timeline == self.index_timeline:
        del frames[i]
        return
    assert 0

  def undo(self) -> None:
    _, k = _make_default_keyframe_at(
      *self.atk.get_keyframes(self.field), self.index_timeline
    )
    k.value = self.value
    self.atk.timeline_at = self.index_timeline

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackColliderKeyframeAdd(_CommandAttackCollider):  ##
  field: str
  index_timeline: int

  def do(self) -> None:
    c = self.c(self.atk)
    _make_default_keyframe_at(*c.get_keyframes(self.field), self.index_timeline)
    self.atk.timeline_at = self.index_timeline

  def undo(self) -> None:
    c = self.c(self.atk)
    frames = c.get_keyframes(self.field)[0]
    assert len(frames) > 1
    for i, fr in enumerate(frames):
      if fr.index_timeline == self.index_timeline:
        del frames[i]
        return
    raise ValueError

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackColliderKeyframeMove(_CommandAttackCollider):  ##
  field: str
  index_timeline_from: int
  index_timeline_to: int

  def do(self) -> None:
    c = self.c(self.atk)
    frames = c.get_keyframes(self.field)[0]
    fr = next(x for x in frames if x.index_timeline == self.index_timeline_from)
    fr.index_timeline = self.index_timeline_to
    self.atk.timeline_at = self.index_timeline_to

  def undo(self) -> None:
    c = self.c(self.atk)
    frames = c.get_keyframes(self.field)[0]
    fr = next(x for x in frames if x.index_timeline == self.index_timeline_to)
    fr.index_timeline = self.index_timeline_from
    self.atk.timeline_at = self.index_timeline_from

  def try_merge(self, newest: Self, /) -> _CommandMergeType:
    if newest.field != self.field:
      return _CommandMergeType.NONE

    self.index_timeline_to = newest.index_timeline_to
    return (
      _CommandMergeType.MERGED_SHOULD_BE_DESTROYED
      if (self.index_timeline_from == self.index_timeline_to)
      else _CommandMergeType.MERGED_OKAY
    )

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackColliderKeyframeRemove(_CommandAttackCollider):  ##
  field: str
  index_timeline: int
  value: Any

  def do(self) -> None:
    c = self.c(self.atk)
    frames = c.get_keyframes(self.field)[0]
    assert len(frames) > 1
    for i, k in enumerate(frames):
      if k.index_timeline == self.index_timeline:
        del frames[i]
        return
    assert 0

  def undo(self) -> None:
    c = self.c(self.atk)
    _, k = _make_default_keyframe_at(*c.get_keyframes(self.field), self.index_timeline)
    k.value = self.value
    self.atk.timeline_at = self.index_timeline

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackColliderAlterKeyframeField(_CommandAttackCollider):  ##
  field: str
  index_inside_list: int
  old: Any
  new: Any

  def do(self) -> None:
    c = self.c(self.atk)
    k: _GKeyframe = c.get_keyframes(self.field)[0][self.index_inside_list]
    _set_proto_field(k, "value", _to_proto(self.new))

  def undo(self) -> None:
    c = self.c(self.atk)
    k: _GKeyframe = c.get_keyframes(self.field)[0][self.index_inside_list]
    _set_proto_field(k, "value", _to_proto(self.old))

  def try_merge(self, newest: Self, /) -> _CommandMergeType:
    if newest.field != self.field:
      return _CommandMergeType.NONE
    if newest.index_inside_list != self.index_inside_list:
      return _CommandMergeType.NONE

    self.new = newest.new
    return (
      _CommandMergeType.MERGED_SHOULD_BE_DESTROYED
      if (self.old == self.new)
      else _CommandMergeType.MERGED_OKAY
    )

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackConditionAlterField(_CommandAttackCondition):  ##
  field: str
  old: Any
  new: Any

  def do(self) -> None:
    c = self.c(self.atk)
    _set_proto_field(c, self.field, _to_proto(self.new))

  def undo(self) -> None:
    c = self.c(self.atk)
    _set_proto_field(c, self.field, _to_proto(self.old))

  def try_merge(self, newest: Self, /) -> _CommandMergeType:
    if newest.field != self.field:
      return _CommandMergeType.NONE

    self.new = newest.new
    return (
      _CommandMergeType.MERGED_SHOULD_BE_DESTROYED
      if (self.old == self.new)
      else _CommandMergeType.MERGED_OKAY
    )

  ##


@dataclass(slots=True)
@t.final
class _CommandAttackImpulseAlterField(_CommandAttackImpulse):  ##
  field: str
  old: Any
  new: Any

  def do(self) -> None:
    i = self.i(self.atk)
    _set_proto_field(i, self.field, _to_proto(self.new))

  def undo(self) -> None:
    i = self.i(self.atk)
    _set_proto_field(i, self.field, _to_proto(self.old))

  def try_merge(self, newest: Self, /) -> _CommandMergeType:
    if newest.field != self.field:
      return _CommandMergeType.NONE

    self.new = newest.new
    return (
      _CommandMergeType.MERGED_SHOULD_BE_DESTROYED
      if (self.old == self.new)
      else _CommandMergeType.MERGED_OKAY
    )

  ##


@dataclass(slots=True)
@t.final
class _TransientColliderAnimated:
  ref: GColliderAnimated

  # def get_keyframe_type(self, field_name: str) -> _KeyframeType:  ##
  #   return g.keyframe_field_types_per_collider_type[self.ref.type][field_name]
  #   ##

  @staticmethod
  def make(id_: int, type_: _ColliderType) -> "_TransientColliderAnimated":  ##
    result = _TransientColliderAnimated(ref=GColliderAnimated(id=id_, type=type_))
    for f in g.keyframe_field_types_per_collider_type[type_]:
      _make_default_keyframe_at(*result.get_keyframes(f), 0)
    return result
    ##

  def get_keyframes(
    self, field_name: str
  ) -> tuple[_GKeyframesContainer, _KeyframeType]:  ##
    ktype = g.keyframe_field_types_per_collider_type[self.ref.type][field_name]
    return getattr(self.ref, field_name), ktype
    ##


@dataclass(slots=True)
class _ListItem(Generic[T]):  ##
  deselection_scheduled: bool = False
  to_select: T | None = None
  to_hover: T | None = None
  ref_selected: T | None = None
  ref_hovered: T | None = None
  ##


@dataclass(slots=True)
class _TransientAttack:  ##
  ref: GAttack
  parent_ability: t.Optional["_TransientAbility"]
  parent_creature: t.Optional["_TransientCreature"]
  colliders: list[_TransientColliderAnimated] = field(default_factory=list)

  impulse: _ListItem[GImpulseData] = field(default_factory=lambda: _ListItem())
  collider: _ListItem[_TransientColliderAnimated] = field(
    default_factory=lambda: _ListItem()
  )
  condition: _ListItem[GCollider] = field(default_factory=lambda: _ListItem())

  timeline_at: float = 0
  timeline_started_playing_at: float = 0

  history_head: int = -1
  history: list[_CommandAttack] = field(default_factory=list)
  scheduled_commands: list[_CommandAttack] = field(default_factory=list)

  def next_impulse_id(self) -> _ImpulseID:
    result = 1
    if self.ref:
      for x in self.ref.impulses:
        result = max(result, x.id + 1)
    return result

  def next_collider_id(self) -> _ColliderID:
    result = 1
    if self.ref.melee:
      for c in self.ref.melee.colliders:
        result = max(result, c.id + 1)
    return result

  def next_condition_id(self) -> _ConditionID:
    result = 1
    for c in self.ref.conditions:
      result = max(result, c.id + 1)
    return result

  def get_visualization_collider(self) -> _TransientColliderAnimated | None:
    if self.collider.ref_hovered:
      return self.collider.ref_hovered
    return self.collider.ref_selected

  def validate(self):
    assert self.ref.duration_frames > 0
    assert 0 <= self.ref.stamina_consumption_frame < self.ref.duration_frames
    assert self.timeline_at >= 0
    assert self.timeline_at <= self.ref.duration_frames
    assert self.timeline_started_playing_at >= 0
    assert self.timeline_started_playing_at <= self.ref.duration_frames

    for impulse in self.ref.impulses:
      assert impulse.id > 0
      assert impulse.at >= 0
      assert impulse.distance >= 0
      assert impulse.dur > 0
      assert impulse.pow > 0

    if self.ref.melee:
      for c in self.colliders:
        for frames in (
          c.get_keyframes(x)[0]
          for x in g.keyframe_field_types_per_collider_type[c.ref.type]
        ):
          for fr in frames:
            assert fr.index_timeline >= 0
            assert fr.index_timeline < self.ref.duration_frames
          for i in range(len(frames) - 1):
            assert frames[i].index_timeline < frames[i + 1].index_timeline

  def get_keyframes(self, field_name: str) -> tuple[_GKeyframesContainer, _KeyframeType]:
    return getattr(self.ref, field_name), g.attack_keyframe_field_types[field_name]

  @property
  def export_path(self) -> Path:
    if self.parent_ability:
      return (
        ASSETS_ATTACKS_DIR
        / "abilities"
        / self.parent_ability.ref.debug_name
        / "{}.yaml".format(self.ref.debug_name)
      )
    elif self.parent_creature:
      return (
        ASSETS_ATTACKS_DIR
        / "creatures"
        / self.parent_creature.ref.debug_name
        / "{}.yaml".format(self.ref.debug_name)
      )
    else:
      raise AssertionError

  ##


@dataclass(slots=True)
class _TransientAbility:  ##
  ref: GAbility
  attacks: list[_TransientAttack] = field(default_factory=list)
  ##


@dataclass(slots=True)
class _TransientCreature:  ##
  ref: GCreature
  attacks: list[_TransientAttack] = field(default_factory=list)
  ##


@unique
class _GizmoMode(IntEnum):  ##
  TRANSLATE = 0
  ROTATE = 1
  SCALE = 2
  ##


class _AppSaveState(BaseModel):  ##
  font_scale_main: float = 1
  ability: str | None = None
  creature: str | None = None
  attack: str | None = None
  play_once: bool = False
  play_rate: float = 1
  visualizer__gizmo_mode: int = _GizmoMode.TRANSLATE
  ##


@dataclass(slots=True)
class _State:
  @dataclass(slots=True)
  class Visualizer:  ##
    first_frame: bool = True
    camera_view: Matrix16 = field(default_factory=Matrix16)
    camera_projection: Matrix16 = field(default_factory=Matrix16)
    fov: float = 27.0
    is_perspective: bool = True
    ortho__view_width: float = 10.0
    perspective__cam_angle_y: float = radians(105)
    perspective__cam_angle_x: float = radians(32)
    perspective__distance: float = 10
    perspective__view_dirty: bool = False
    gizmo_mode: _GizmoMode = _GizmoMode.TRANSLATE
    round_to_step: bool = False
    ##

  @dataclass(slots=True)
  class Timeline:  ##
    is_playing: bool = False
    dragging_playhead: bool = False
    dragging_keyframe: str | None = None

    selected_keyframe: _SelectedKeyframe | None = None
    keyframe_to_select: tuple[_SelectedKeyframe, bool] | None = None
    ##

  @dataclass(slots=True)
  class Explorer:  ##
    pass
    # scheduled_commands: list[Command] = field(default_factory=list)
    ##

  action_id: int = 1

  visualizer: Visualizer = field(default_factory=Visualizer)
  timeline: Timeline = field(default_factory=Timeline)
  explorer: Explorer = field(default_factory=Explorer)

  glib: Lib = None  # type: ignore

  abilities: list[_TransientAbility] = field(default_factory=list)
  creatures: list[_TransientCreature] = field(default_factory=list)

  attack_keyframe_field_types: dict[str, _KeyframeType] = field(default_factory=dict)
  keyframe_field_types_per_collider_type: dict[int, dict[str, _KeyframeType]] = field(
    default_factory=dict
  )

  attack_to_select: _TransientAttack | None = None
  ref_selected_attack_ability: _TransientAbility | None = None
  ref_selected_attack_creature: _TransientCreature | None = None
  ref_selected_attack: _TransientAttack | None = None
  play_once: bool = False
  play_rate: float = 1

  attack_undo_scheduled: bool = False
  attack_redo_scheduled: bool = False

  scheduled_dump: bool = False

  def dump(self) -> _AppSaveState:  ##
    vis = self.visualizer
    return _AppSaveState(
      font_scale_main=im.get_style().font_scale_main,
      ability=(
        self.ref_selected_attack_ability.ref.debug_name
        if self.ref_selected_attack_ability
        else None
      ),
      creature=(
        self.ref_selected_attack_creature.ref.debug_name
        if self.ref_selected_attack_creature
        else None
      ),
      attack=(
        self.ref_selected_attack.ref.debug_name if self.ref_selected_attack else None
      ),
      play_once=self.play_once,
      play_rate=self.play_rate,
      visualizer__gizmo_mode=vis.gizmo_mode,
    )
    ##

  def load(self, value: _AppSaveState) -> None:  ##
    self.play_once = value.play_once
    self.play_rate = value.play_rate
    for a in self.abilities:
      if a.ref.debug_name == value.ability:
        for atk in a.attacks:
          if atk.ref.debug_name == value.attack:
            self.ref_selected_attack_ability = a
            self.ref_selected_attack = atk
    for c in self.creatures:
      if c.ref.debug_name == value.creature:
        for atk in c.attacks:
          if atk.ref.debug_name == value.attack:
            self.ref_selected_attack_creature = c
            self.ref_selected_attack = atk
    ##

  def schedule_dump(self) -> None:  ##
    self.scheduled_dump = True
    ##

  def validate(self):  ##
    for creature in self.creatures:
      for attack in creature.attacks:
        attack.validate()
    ##


g = _State()


def _select_keyframe(
  field_name: str,
  index_inside_list: int,
  frames: _GKeyframesContainer,
  *,
  update_timeline_playhead: bool = True,
) -> None:  ##
  fr = frames[index_inside_list]
  g.timeline.keyframe_to_select = (
    _SelectedKeyframe(
      id=fr.id,
      key=_keyframe_id(field_name, fr.id),
      field=field_name,
      index_timeline=fr.index_timeline,
      index_inside_list=index_inside_list,
    ),
    update_timeline_playhead,
  )
  ##


@contextmanager
def _override_keyframe_round_to_step(v: bool):  ##
  old = g.visualizer.round_to_step
  g.visualizer.round_to_step = v
  yield
  g.visualizer.round_to_step = old
  ##


def _panel_explorer() -> None:
  ## Abilities
  im.text("ABILITIES")
  for ability in g.abilities:
    group_flags = im.TreeNodeFlags_.span_avail_width | im.TreeNodeFlags_.default_open
    if ability is g.ref_selected_attack_ability:
      group_flags |= im.TreeNodeFlags_.selected
    if im.tree_node_ex(ability.ref.debug_name, group_flags):
      for attack in ability.attacks:
        flags = im.TreeNodeFlags_.leaf | im.TreeNodeFlags_.span_avail_width
        if attack is g.ref_selected_attack:
          flags |= im.TreeNodeFlags_.selected
        if im.tree_node_ex(attack.ref.debug_name, flags):
          if im.is_item_clicked():
            g.ref_selected_attack_ability = ability
            g.ref_selected_attack_creature = None
            g.ref_selected_attack = attack
            g.schedule_dump()
          im.tree_pop()
      im.tree_pop()
  ##

  im.separator()

  ## Creatures
  im.text("CREATURES")
  for creature in g.creatures:
    # for creature in g.creatures:
    group_flags = im.TreeNodeFlags_.span_avail_width | im.TreeNodeFlags_.default_open
    if creature is g.ref_selected_attack_creature:
      group_flags |= im.TreeNodeFlags_.selected
    if im.tree_node_ex(creature.ref.debug_name, group_flags):
      for attack in creature.attacks:
        flags = im.TreeNodeFlags_.leaf | im.TreeNodeFlags_.span_avail_width
        if attack is g.ref_selected_attack:
          flags |= im.TreeNodeFlags_.selected
        if im.tree_node_ex(attack.ref.debug_name, flags):
          if im.is_item_clicked():
            g.ref_selected_attack_ability = None
            g.ref_selected_attack_creature = creature
            g.ref_selected_attack = attack
            g.schedule_dump()
          im.tree_pop()
      im.tree_pop()
  ##


def _panel_attack_inspector() -> None:
  ## Setup
  atk = g.ref_selected_attack
  if not atk:
    return

  is_player = atk.parent_ability or (
    atk.parent_creature and (atk.parent_creature.ref.debug_name == "PLAYER")
  )
  ##

  ## duration_frames
  im.text("duration_frames")
  im.same_line()
  min_attack_frames = atk.ref.stamina_consumption_frame + 1
  if atk.ref.melee:
    for c in atk.colliders:
      for frames in (
        c.get_keyframes(x)[0]
        for x in g.keyframe_field_types_per_collider_type[c.ref.type]
      ):
        for frame in frames:
          min_attack_frames = max(min_attack_frames, frame.index_timeline + 1)
  for impulse in atk.ref.impulses:
    min_attack_frames = max(min_attack_frames, impulse.at + impulse.dur)
  im.set_next_item_width(im.get_content_region_avail()[0])
  changed, frames = im.input_int(
    bf.imgui_id("", "atk__duration_frames"),
    atk.ref.duration_frames,
    ATTACKS_FPS // 10,
    ATTACKS_FPS,
  )
  new_value = min(_MAX_ATTACK_FRAMES_DURATION, max(min_attack_frames, frames))
  if changed and (new_value != atk.ref.duration_frames):
    atk.scheduled_commands.append(
      _CommandAttackAlterField(
        atk=atk,
        field="duration_frames",
        old=atk.ref.duration_frames,
        new=new_value,
      )
    )
  ##

  if is_player:
    ## stamina_consumption_frame
    im.text("stamina_consumption_frame")
    im.same_line()
    im.set_next_item_width(im.get_content_region_avail()[0])
    changed, frames = im.input_int(
      bf.imgui_id("", "atk__stamina_consumption_frame"),
      atk.ref.stamina_consumption_frame,
      ATTACKS_FPS // 10,
      ATTACKS_FPS,
    )
    max_stamina_consumption_frame = atk.ref.duration_frames - 1
    for c in atk.colliders:
      for fr in c.get_keyframes("is_active")[0]:
        if fr.value:
          max_stamina_consumption_frame = min(
            max_stamina_consumption_frame, fr.index_timeline
          )
          break
    new_value = min(max_stamina_consumption_frame, max(0, frames))
    if changed and (new_value != atk.ref.stamina_consumption_frame):
      atk.scheduled_commands.append(
        _CommandAttackAlterField(
          atk=atk,
          field="stamina_consumption_frame",
          old=atk.ref.stamina_consumption_frame,
          new=new_value,
        )
      )
    ##

  if im.begin_tab_bar("attack_tab_bar", im.TabBarFlags_.none):
    ## Colliders
    if im.begin_tab_item("Colliders")[0]:
      if atk.ref.melee:
        for i, collider_type in enumerate(_ColliderType):
          if not i:
            continue
          if i > 1:
            im.same_line()
          if im.button("+{}".format(collider_type.name.lower())):
            atk.scheduled_commands.append(
              _CommandAttackColliderCreate(
                atk=atk,
                id=atk.next_collider_id(),
                type=collider_type,
              )
            )

        for i, collider in enumerate(atk.colliders):
          flags = im.TreeNodeFlags_.leaf | im.TreeNodeFlags_.span_avail_width
          if atk.collider.ref_selected is collider:
            flags |= im.TreeNodeFlags_.selected
          if im.tree_node_ex(
            "{} {}".format(i, _ColliderType.get_name(collider.ref.type)), flags
          ):
            if im.is_item_hovered():
              atk.collider.to_hover = collider
            if im.is_item_clicked():
              if atk.collider.ref_selected is collider:
                atk.collider.deselection_scheduled = True
              else:
                atk.collider.to_select = collider
            if im.is_item_clicked(im.MouseButton_.right):
              atk.scheduled_commands.append(
                _CommandAttackColliderDelete(atk=atk, index=i, instance=collider)
              )
            im.tree_pop()
      im.end_tab_item()
    ##

    ## Impulses
    if im.begin_tab_item("Impulses")[0]:
      if im.button("+impulse"):
        atk.scheduled_commands.append(
          _CommandAttackImpulseCreate(atk=atk, id=atk.next_impulse_id())
        )
      for i, impulse in enumerate(atk.ref.impulses):
        flags = im.TreeNodeFlags_.leaf | im.TreeNodeFlags_.span_avail_width
        if impulse is atk.impulse.ref_selected:
          flags |= im.TreeNodeFlags_.selected

        im.separator()
        im.text(
          "{} {:.2f} {} {:.1f} {}".format(
            impulse.at,
            impulse.distance,
            impulse.dur,
            impulse.pow,
            impulse.rotation,
          )
        )
        # if im.tree_node_ex(
        #   bf.imgui_id(
        #     "{} {:.2f} {} {:.1f} {}".format(
        #       impulse.at,
        #       impulse.distance,
        #       impulse.dur,
        #       impulse.pow,
        #       impulse.rotation,
        #     ),
        #     f"impulse_{impulse.id}",
        #   ),
        #   flags,
        # ):
        if im.is_item_hovered():
          atk.impulse.to_hover = impulse
        if im.is_item_clicked():
          if atk.impulse.ref_selected is impulse:
            atk.impulse.deselection_scheduled = True
          else:
            atk.impulse.to_select = impulse
        if im.is_item_clicked(im.MouseButton_.right):
          atk.scheduled_commands.append(
            _CommandAttackImpulseDelete(atk=atk, index=i, instance=impulse)
          )

        if im.begin_table("impulse_table", 2):
          im.table_setup_column("", im.TableColumnFlags_.width_fixed)
          im.table_setup_column("", im.TableColumnFlags_.width_stretch)

          for field_name, min_, max_, step, step_fast, fmt in (
            ("at", 0, atk.ref.duration_frames - 1, 1, 5, "%.0f"),
            ("distance", 0, _MAX_OFFSET, _STEP_TRANSLATE, 1, "%.2f"),
            (
              "dur",
              ATTACKS_FPS // 10,
              ATTACKS_FPS * 10,
              ATTACKS_FPS // 10,
              ATTACKS_FPS,
              "%.0f",
            ),
            ("pow", 0.3, 10, 0.1, 1, "%.1f"),
            (
              "rotation",
              bf.FLOAT_INF_NEG,
              bf.FLOAT_INF_POS,
              _STEP_ROTATE,
              90,
              "%.0f",
            ),
          ):
            im.table_next_row()
            im.table_set_column_index(0)
            im.text(field_name)

            im.table_set_column_index(1)
            field_ = getattr(impulse, field_name)
            _inspector_input_float(
              bf.imgui_id("", f"impulse_{impulse.id}_{field_name}"),
              lambda: _from_proto(field_),
              lambda x: (
                atk.scheduled_commands.append(
                  _CommandAttackImpulseAlterField(
                    atk=atk,
                    impulse_id=impulse.id,
                    field=field_name,
                    old=_from_proto(field_),
                    new=x,
                  )
                )
                if _from_proto(field_) != x
                else None
              ),
              min_,
              max_,
              step,
              step_fast,
              fmt,
            )

        im.end_table()
        # im.tree_pop()

      im.end_tab_item()
    ##

    if not is_player:
      ## Conditions
      if im.begin_tab_item("Conditions")[0]:
        if not atk.ref.conditions:
          for i, collider_type in enumerate(_ColliderType):
            if not i:
              continue
            if i > 1:
              im.same_line()
            if im.button(f"+{collider_type.name.lower()}"):
              atk.scheduled_commands.append(
                _CommandAttackConditionCreate(
                  atk=atk,
                  id=atk.next_condition_id(),
                  type=collider_type,
                )
              )

        for i, condition in enumerate(atk.ref.conditions):
          im.text(_ColliderType.get_name(condition.type))
          if im.is_item_clicked(im.MouseButton_.right):
            atk.scheduled_commands.append(
              _CommandAttackConditionDelete(atk=atk, index=i, instance=condition)
            )

          if im.begin_table("condition", 2):
            im.table_setup_column("", im.TableColumnFlags_.width_fixed)
            im.table_setup_column("", im.TableColumnFlags_.width_stretch)

            for field_name, keyframe_type in g.keyframe_field_types_per_collider_type[
              condition.type
            ].items():
              if field_name == "is_active":
                continue

              im.table_next_row()
              im.table_set_column_index(0)
              im.text(field_name.split("__", 1)[-1])

              im.table_set_column_index(1)
              getter = lambda: _from_proto(getattr(condition, field_name))
              match keyframe_type:
                case _KeyframeTypeBool():
                  _inspector_checkbox(
                    bf.imgui_id("", f"condition_checkbox_{field_name}"),
                    getter,
                    lambda x: (
                      atk.scheduled_commands.append(
                        _CommandAttackConditionAlterField(
                          atk=atk,
                          condition_id=condition.id,
                          field=field_name,
                          old=getter(),
                          new=x,
                        )
                      )
                      if getter() != x
                      else None
                    ),
                  )

                case _KeyframeTypeFloat():
                  _inspector_input_float(
                    bf.imgui_id("", f"condition_slider_{field_name}"),
                    getter,
                    lambda x: (
                      atk.scheduled_commands.append(
                        _CommandAttackConditionAlterField(
                          atk=atk,
                          condition_id=condition.id,
                          field=field_name,
                          old=getter(),
                          new=x,
                        )
                      )
                      if getter() != x
                      else None
                    ),
                    keyframe_type.min,
                    keyframe_type.max,
                    keyframe_type.step,
                    keyframe_type.step_fast,
                    keyframe_type.fmt,
                  )

                case _KeyframeTypeV2():
                  _inspector_input_float(
                    bf.imgui_id("", f"condition_slider_{field_name}_x"),
                    lambda: getter().x,
                    lambda x: (
                      atk.scheduled_commands.append(
                        _CommandAttackConditionAlterField(
                          atk=atk,
                          condition_id=condition.id,
                          field=field_name,
                          old=getter(),
                          new=vec2(x, getter().y),
                        )
                      )
                      if getter().x != x
                      else None
                    ),
                    -_MAX_OFFSET,
                    _MAX_OFFSET,
                    keyframe_type.step,
                    1,
                    "%.2f",
                  )
                  _inspector_input_float(
                    bf.imgui_id("", f"condition_slider_{field_name}_y"),
                    lambda: getter().y,
                    lambda y: (
                      atk.scheduled_commands.append(
                        _CommandAttackConditionAlterField(
                          atk=atk,
                          condition_id=condition.id,
                          field=field_name,
                          old=getter(),
                          new=vec2(getter().x, y),
                        )
                      )
                      if getter().y != y
                      else None
                    ),
                    -_MAX_OFFSET,
                    _MAX_OFFSET,
                    keyframe_type.step,
                    1,
                    "%.2f",
                  )

                case _:
                  assert 0
            im.end_table()

        im.end_tab_item()
      ##

    im.end_tab_bar()


def _panel_visualizer() -> None:
  ## Setup
  atk = g.ref_selected_attack
  if atk is None:
    assert g.ref_selected_attack_creature is None
    return

  cells = 10
  draw = im.get_window_draw_list()
  size_ = im.get_content_region_avail()
  pos_ = im.get_cursor_screen_pos()
  vis = g.visualizer
  ##

  draw.push_clip_rect(pos_, pos_ + size_, True)

  ## Matrices
  if vis.perspective__view_dirty or vis.first_frame:
    vis.first_frame = False
    eye = (
      vec3(
        math.cos(vis.perspective__cam_angle_y) * math.cos(vis.perspective__cam_angle_x),
        math.sin(vis.perspective__cam_angle_x),
        math.sin(vis.perspective__cam_angle_y) * math.cos(vis.perspective__cam_angle_x),
      )
      * vis.perspective__distance
    )
    vis.camera_view = _to_Matrix16(glm.lookAt(eye, vec3_zero, vec3_up))

  if vis.is_perspective:
    vis.camera_projection = _to_Matrix16(
      glm.perspective(glm.radians(vis.fov), size_.x / size_.y, 0.1, 100.0)
    )
  else:
    view_height = vis.ortho__view_width * size_.y / size_.x
    vis.camera_projection = _to_Matrix16(
      glm.ortho(
        -vis.ortho__view_width,
        vis.ortho__view_width,
        -view_height,
        view_height,
        1000.0,
        -1000.0,
      )
    )

  view = _to_mat4(vis.camera_view)
  projection = _to_mat4(vis.camera_projection)

  vp: mat4 = projection * view

  def world_to_screen(p: vec3) -> vec2:
    clip: vec4 = vp * vec4(p, 1.0)  # type: ignore

    w = clip.w
    # if w <= 0:
    #     return None

    inv = 1.0 / w
    return vec2(
      pos_.x + (clip.x * inv + 1.0) * size_.x * 0.5,
      pos_.y + (1.0 - clip.y * inv) * size_.y * 0.5,
    )

  ##

  ## Drawing functions
  def draw_line(p1: vec3, p2: vec3, color: int = COLOR_YELLOW_U32):
    draw.add_line(_tuplify(world_to_screen(p1)), _tuplify(world_to_screen(p2)), color, 2)

  def draw_polyline(
    points: Iterable[vec3],
    color: int = COLOR_YELLOW_U32,
    flags: im.ImDrawFlags_ = im.ImDrawFlags_.none,
  ):
    draw.add_polyline([_tuplify(world_to_screen(x)) for x in points], color, flags, 2)

  _draw_points: list[vec3] = []

  def draw_circle(
    p: vec3,
    radius: float,
    color: int = COLOR_YELLOW_U32,
    segments: int = 24,
    plane: tuple[vec3, vec3] = (vec3_right, vec3_forward),
  ) -> None:
    assert not _draw_points
    assert segments >= 8
    assert radius > 0
    assert isinstance(p, vec3)
    assert glm.dot(plane[1], plane[0]) < 0.00001
    normal = glm.cross(plane[0], plane[1])
    assert abs(glm.length(normal) - 1) < 0.00001
    m = glm.rotate(2.0 * pi / segments, normal)
    cur = glm.cross(normal, vec3_forward) * radius
    for _ in range(segments):
      _draw_points.append(p + vec3(cur))
      cur = m * cur
    draw_polyline(_draw_points, color, flags=im.ImDrawFlags_.closed)
    _draw_points.clear()

  def draw_capsule(
    p: vec3,
    radius: float,
    spread: float,
    angle: float,
    color: int = COLOR_YELLOW_U32,
    segments: int = 24,
    plane: tuple[vec3, vec3] = (vec3_right, vec3_forward),
  ) -> None:
    assert not _draw_points
    assert segments >= 8
    assert spread >= 0
    assert radius > 0
    assert isinstance(p, vec3)
    assert segments % 2 == 0
    assert glm.dot(plane[0], plane[1]) < 0.00001
    normal = glm.cross(plane[1], plane[0])
    assert abs(glm.length(normal) - 1) < 0.00001
    m = glm.rotate(2.0 * pi / segments, normal)

    plane_forward = vec4(plane[0], 0)  # type: ignore
    capsule_forward = vec3(glm.rotate(angle, normal) * plane_forward)
    spread_vector = capsule_forward * spread
    p1 = p + spread_vector / 2
    p2 = p - spread_vector / 2

    cur = -glm.cross(normal, capsule_forward) * radius
    for _ in range(segments // 2 + 1):
      _draw_points.append(p1 + vec3(cur))
      cur = m * cur
    _draw_points.append(_draw_points[-1] - spread_vector)
    for _ in range(segments // 2):
      _draw_points.append(p2 + vec3(cur))
      cur = m * cur
    draw_polyline(_draw_points, color, flags=im.ImDrawFlags_.closed)
    _draw_points.clear()
    draw_line(p1 + capsule_forward / 5, p2 - capsule_forward / 5, color)

  def draw_polygon(
    p: vec3,
    dist_min: float,
    dist_max: float,
    spread_angle: float,
    angle: float,
    color: int = COLOR_YELLOW_U32,
    plane: tuple[vec3, vec3] = (vec3_right, vec3_forward),
  ) -> None:
    assert not _draw_points
    assert dist_min >= 0
    assert dist_max > 0
    assert spread_angle > 0
    normal = glm.cross(plane[1], plane[0])
    polygon_forward = glm.rotate(plane[0], angle, normal)
    assert isinstance(polygon_forward, vec3)
    d1 = glm.rotate(polygon_forward, spread_angle / 2, normal)
    d2 = glm.rotate(polygon_forward, -spread_angle / 2, normal)
    assert isinstance(d1, vec3)
    assert isinstance(d2, vec3)
    _draw_points.append(d1 * dist_max)
    _draw_points.append(polygon_forward * dist_max)
    _draw_points.append(d2 * dist_max)
    if dist_min > 0:
      _draw_points.append(d2 * dist_min)
      _draw_points.append(d1 * dist_min)
    else:
      _draw_points.append(vec3(0, 0, 0))
    draw_polyline((x + p for x in _draw_points), color, flags=im.ImDrawFlags_.closed)
    _draw_points.clear()

  def draw_arrow(
    p1: vec3,
    p2: vec3,
    color: int = COLOR_YELLOW_U32,
    plane: tuple[vec3, vec3] = (vec3_right, vec3_forward),
  ):
    if p1 == p2:
      return
    assert not _draw_points
    arrow_tip_length = 0.2
    normal = glm.cross(plane[1], plane[0])
    d = glm.normalize(p2 - p1) * arrow_tip_length
    p3 = p2 - glm.rotate(d, pi * 1 / 6, normal)
    p4 = p2 - glm.rotate(d, -pi * 1 / 6, normal)
    _draw_points.append(p1)
    _draw_points.append(p2)
    _draw_points.append(p3)
    _draw_points.append(p4)
    _draw_points.append(p2)
    draw_polyline(_draw_points, color)
    _draw_points.clear()

  gizmo.begin_frame()
  gizmo.set_drawlist()
  gizmo.set_rect(pos_.x, pos_.y, size_.x, size_.y)
  gizmo.set_orthographic(not vis.is_perspective)
  gizmo.draw_grid(vis.camera_view, vis.camera_projection, identity_matrix(), cells / 2)
  ##

  body_pos = vec2()

  ## Drawing impulses
  for impulse in atk.ref.impulses:
    tip = vec3(impulse.distance, 0, 0)
    tip: vec2 = glm.rotate(vec2(impulse.distance, 0), radians(impulse.rotation))  # ty:ignore[invalid-assignment]
    draw_arrow(vec3(0, 0, 0), vec3(tip.x, 0, tip.y), COLOR_RED_FADED_U32)

    e = atk.timeline_at - impulse.at
    if e <= 0:
      continue
    elif e < impulse.dur:
      t = e / impulse.dur
      assert 0 <= t <= 1
      A = impulse.distance / (1 - 1 / (impulse.pow + 1))
      dist = A * (t - (t ** (impulse.pow + 1)) / (impulse.pow + 1))
      body_pos += glm.rotate(vec2(dist, 0), radians(impulse.rotation))
    else:
      body_pos += glm.rotate(vec2(impulse.distance, 0), radians(impulse.rotation))
  ##

  ## Drawing body
  parent_radius = next(
    x.ref.collider_size / 2 for x in g.creatures if x.ref.debug_name == "PLAYER"
  )
  if atk.parent_creature:
    parent_radius = atk.parent_creature.ref.collider_size / 2
  draw_circle(vec3(body_pos.x, 0, body_pos.y), parent_radius, COLOR_RED_U32)
  ##

  ## Drawing condition (on the first frame)
  if atk.timeline_at < 1:
    condition_color = COLOR_GREEN_U32
    for c in atk.ref.conditions:
      center_ = _from_proto(c.tr)
      center = vec3(center_.x, 0, center_.y)
      match c.type:
        case _ColliderType.CIRCLE:
          draw_circle(center, c.circle__radius, condition_color)
        case _ColliderType.CAPSULE:
          draw_capsule(
            center,
            c.capsule__radius,
            c.capsule__spread,
            radians(c.capsule__rotation),
            condition_color,
          )
        case _ColliderType.POLYGON:
          draw_polygon(
            center,
            c.polygon__dist_min,
            c.polygon__dist_max,
            radians(c.polygon__spread_angle),
            radians(c.polygon__rotation),
            condition_color,
          )
        case _:
          assert 0
  ##

  ## Drawing colliders
  sel_col = atk.collider.ref_selected
  hov_col = atk.collider.ref_hovered
  visual_collider = atk.get_visualization_collider()

  if atk.ref.melee:

    def make_value(c: _TransientColliderAnimated, f: str) -> Any:
      return _make_keyframe_value_at(*c.get_keyframes(f), atk.timeline_at)[1]

    for c in atk.colliders:
      color_ = COLOR_YELLOW
      if c is sel_col:
        color_ = COLOR_LIGHT_BLUE
      fade_ = False
      if hov_col is None:
        fade_ = (sel_col is not None) and (sel_col is not c)
      else:
        fade_ = c is not hov_col
      if fade_:
        color_ = imgui_fade_replace(color_, 0.25)

      is_active = make_value(c, "is_active")
      if not is_active:
        if c is not visual_collider:
          continue
        color_ = imgui_fade_multiply(color_, 0.25)

      color = imgui_color_to_u32(color_)

      c_pos = make_value(c, "tr")
      m = glm.translate(vec3(c_pos.x, 0, c_pos.y))
      center = vec3(m * vec4(0, 0, 0, 1)) + vec3(body_pos.x, 0, body_pos.y)

      match c.ref.type:
        case _ColliderType.CIRCLE.value:
          draw_circle(center, make_value(c, "circle__radius"), color)

        case _ColliderType.CAPSULE.value:
          draw_capsule(
            center,
            make_value(c, "capsule__radius"),
            make_value(c, "capsule__spread"),
            radians(make_value(c, "capsule__rotation")),
            color,
          )

        case _ColliderType.POLYGON.value:
          draw_polygon(
            center,
            make_value(c, "polygon__dist_min"),
            make_value(c, "polygon__dist_max"),
            radians(make_value(c, "polygon__spread_angle")),
            radians(make_value(c, "polygon__rotation")),
            color,
          )

        case _:
          assert 0

  if im.is_key_pressed(im.Key.t) or im.is_key_pressed(im.Key._1):
    vis.gizmo_mode = _GizmoMode.TRANSLATE
  # elif im.is_key_pressed(im.Key.r) or im.is_key_pressed(im.Key._2):
  #   vis.gizmo_mode = GizmoMode.ROTATE
  # elif im.is_key_pressed(im.Key.s) or im.is_key_pressed(im.Key._3):
  #   vis.gizmo_mode = GizmoMode.SCALE

  if c := atk.collider.ref_selected:
    delta = Matrix16()
    man_kwargs: dict = {
      "view": vis.camera_view,
      "projection": vis.camera_projection,
      "operation": {
        _GizmoMode.TRANSLATE: gizmo.OPERATION.translate,
        _GizmoMode.ROTATE: gizmo.OPERATION.rotate_y,
        _GizmoMode.SCALE: gizmo.OPERATION.scale,
      }[vis.gizmo_mode],
      "mode": gizmo.MODE.world,
      "snap": {
        _GizmoMode.TRANSLATE: SNAP_TRANSLATE,
        _GizmoMode.ROTATE: SNAP_ROTATE,
        _GizmoMode.SCALE: SNAP_SCALE,
      }[vis.gizmo_mode],
      "delta_matrix": delta,
    }

    tr_closest_index, poss_ = _get_closest_keyframe(
      c.get_keyframes("tr")[0], atk.timeline_at
    )
    tr_pos = poss_.value
    assert isinstance(tr_pos, GV2)
    m = _to_Matrix16(glm.translate(vec3(tr_pos.x, 0, tr_pos.y)))
    with _gizmo_restrict(m, (False, True, False), disable_translation_y=True):
      if gizmo.manipulate(object_matrix=m, **man_kwargs):
        off3 = _to_mat4(delta) * vec4(0, 0, 0, 1)
        assert off3.y == 0
        off = bf.round_to_step(vec2(off3.x, off3.z), _STEP_TRANSLATE)
        atk.scheduled_commands.append(
          _CommandAttackColliderAlterKeyframeField(
            atk=atk,
            collider_id=c.ref.id,
            field="tr",
            index_inside_list=tr_closest_index,
            old=_from_proto(c.ref.tr[tr_closest_index].value),
            new=_from_proto(c.ref.tr[tr_closest_index].value) + off,
          )
        )

  gizmo_size = 120 * im.get_window_dpi_scale()
  gizmo.view_manipulate(
    vis.camera_view,
    vis.camera_projection,
    gizmo.OPERATION.rotate,
    gizmo.MODE.local,
    identity_matrix(),
    vis.perspective__distance,
    ImVec2(pos_.x + size_.x - gizmo_size, pos_.y),
    ImVec2(gizmo_size, gizmo_size),
    0x20FFFFFF,
  )
  ##

  draw.pop_clip_rect()


def _keyframe_id(field_name: str, id_: int) -> str:  ##
  return f"keyframe_{field_name}_{id_}"
  ##


@dataclass(slots=True)
class ImguiTimelineLineOut:  ##
  pos_top_left: ImVec2
  pos_bottom_right: ImVec2
  width: float = 0
  width_per_index: float = 0
  height: float = 0
  clicked: bool = False
  double_clicked: bool = False
  hovered: bool = False
  hovered_t: float = -1
  hovered_index: int = -1
  hovered_indexf: float = -1
  hovered_index_half_cell_offset: int = -1
  ##


imgui_timeline_line_out = ImguiTimelineLineOut(ImVec2(), ImVec2())


def imgui_timeline_line(indices_width: int, rows: int, color: int) -> None:  ##
  assert indices_width >= 1
  assert rows >= 1

  out = imgui_timeline_line_out
  out.pos_top_left = im.get_cursor_screen_pos()
  out.width = max(1, im.get_content_region_avail().x)
  out.width_per_index = out.width / indices_width
  out.height = im.get_frame_height() * rows
  out.pos_bottom_right = out.pos_top_left + ImVec2(out.width, out.height)

  mouse = im.get_mouse_pos()
  if (out.pos_top_left.x <= mouse.x <= out.pos_bottom_right.x) and (
    out.pos_top_left.y <= mouse.y <= out.pos_bottom_right.y
  ):
    out.hovered = True
    out.clicked = im.is_mouse_clicked(0)
    out.double_clicked = im.is_mouse_double_clicked(0)
  else:
    out.hovered = False
    out.clicked = False
    out.double_clicked = False

  draw = im.get_window_draw_list()
  draw.add_rect_filled(
    out.pos_top_left,
    out.pos_bottom_right,
    im.get_color_u32(im.Col_.frame_bg_hovered) if out.hovered else color,
  )

  out.hovered_t = bf.clamp((mouse.x - out.pos_top_left.x) / out.width, 0, 1)
  out.hovered_index = min(indices_width - 1, int(out.hovered_t * indices_width))
  out.hovered_indexf = out.hovered_t * indices_width
  out.hovered_index_half_cell_offset = bf.clamp(
    int((im.get_mouse_pos().x - out.pos_top_left.x) / out.width * indices_width + 0.5),
    0,
    indices_width - 1,
  )
  im.dummy((out.width, out.height))
  ##


@unique
class TimelineVisitType(IntEnum):
  ATTACK = 1
  COLLIDER_ANIMATED = 2


def _timeline_visit_frames() -> Generator[
  tuple[str, _GKeyframesContainer, _KeyframeType, TimelineVisitType], None, None
]:  ##
  atk = g.ref_selected_attack
  assert atk

  for f in g.attack_keyframe_field_types:
    yield f, *atk.get_keyframes(f), TimelineVisitType.ATTACK

  c = atk.get_visualization_collider()
  if c:
    for f in g.keyframe_field_types_per_collider_type[c.ref.type]:
      yield f, *c.get_keyframes(f), TimelineVisitType.COLLIDER_ANIMATED
  ##


def _panel_timeline() -> None:
  ## Setup
  tim = g.timeline
  atk = g.ref_selected_attack
  if not atk:
    imgui_draw_cross()
    return
  assert atk.ref.duration_frames > 0

  io = im.get_io()

  if tim.is_playing:
    atk.timeline_at += im.get_io().delta_time * ATTACKS_FPS * g.play_rate
    if atk.timeline_at > atk.ref.duration_frames:
      atk.timeline_at -= atk.ref.duration_frames
      if g.play_once:
        atk.timeline_at = 0
        tim.is_playing = False
  else:
    atk.timeline_at = min(atk.timeline_at, atk.ref.duration_frames)

  bf.imgui_set_idling(not tim.is_playing)

  draw = im.get_window_draw_list()

  keyframe_colors = (
    im.get_color_u32(im.Col_.text),
    im.get_color_u32(im.Col_.plot_lines),
    im.get_color_u32(im.Col_.button_active),
    im.get_color_u32(im.Col_.text),
  )

  def imgui_keyframe(
    key: str, pos: ImVec2, selected: bool = False, closest: bool = False
  ) -> bool:
    remembered_pos = im.get_cursor_screen_pos()

    scale = im.get_window_dpi_scale() * im.get_frame_height() / 24

    half = _keyframe_off * scale
    im.set_cursor_screen_pos(pos - half)
    im.invisible_button(key, half * 2)

    if selected or im.is_item_hovered():
      draw.add_quad_filled(
        *(pos + x * scale * 1.5 for x in _keyframe_quad_points),
        col=keyframe_colors[3] if selected else keyframe_colors[1],
      )
    draw.add_quad_filled(
      *(pos + x * scale for x in _keyframe_quad_points),
      col=keyframe_colors[2 if closest else 0],
    )

    im.set_cursor_screen_pos(remembered_pos)
    return im.is_item_clicked()

  were_dragging_keyframe_this_frame = False
  created_keyframe_this_frame = False
  hovered_frame_index = -1
  ##

  keyframes_to_handle: list[tuple[str, _GKeyframesContainer]] = []

  def draw_and_handle_keyframes(
    field_name: str,
    frames: _GKeyframesContainer,
    _ktype: _KeyframeType,
    on_keyframe_dragged: Callable[[int, int], None],
    on_keyframe_created: Callable[[int], None],
    on_keyframe_deleted: Callable[[int], None],
  ):  ##
    nonlocal were_dragging_keyframe_this_frame
    nonlocal created_keyframe_this_frame
    nonlocal hovered_frame_index

    keyframes_to_handle.append((field_name, frames))

    # Keyframes
    closest_index = _get_closest_keyframe(frames, atk.timeline_at)[0]
    for fr_index, fr in enumerate(frames):
      key = _keyframe_id(field_name, fr.id)
      is_selected = bool(tim.selected_keyframe) and (tim.selected_keyframe.key == key)
      imgui_keyframe(
        key,
        imgui_timeline_line_out.pos_top_left
        + ImVec2(
          fr.index_timeline * imgui_timeline_line_out.width_per_index,
          imgui_timeline_line_out.height / 2,
        ),
        selected=is_selected,
        closest=closest_index == fr_index,
      )
      if im.is_item_hovered():
        if im.is_mouse_clicked(0):
          _select_keyframe(field_name, fr_index, frames)
          tim.dragging_keyframe = key
        if (
          (not tim.dragging_keyframe)
          and (im.is_mouse_clicked(1) or im.is_key_pressed(im.Key.delete))
          and (len(frames) > 1)
        ):
          hov = imgui_timeline_line_out.hovered_index_half_cell_offset
          for i, k in enumerate(frames):
            if k.index_timeline == hov:
              on_keyframe_deleted(i)
              break

      if im.is_mouse_down(0) and (tim.dragging_keyframe == key):
        were_dragging_keyframe_this_frame = True
        min_left = 0
        max_right = atk.ref.duration_frames - 1
        if fr_index > 0:
          min_left = frames[fr_index - 1].index_timeline + 1
        if fr_index < len(frames) - 1:
          max_right = frames[fr_index + 1].index_timeline - 1

        on_keyframe_dragged(
          fr.index_timeline,
          bf.clamp(
            imgui_timeline_line_out.hovered_index_half_cell_offset,
            min_left,
            max_right,
          ),
        )

      if not (were_dragging_keyframe_this_frame or created_keyframe_this_frame):
        if imgui_timeline_line_out.double_clicked:
          idx = imgui_timeline_line_out.hovered_index_half_cell_offset
          if not any(x.index_timeline == idx for x in frames):
            created_keyframe_this_frame = True
            on_keyframe_created(idx)

      if imgui_timeline_line_out.hovered:
        hovered_frame_index = imgui_timeline_line_out.hovered_index_half_cell_offset

    im.dummy((0, 0))

  ##

  if im.begin_table(  ##
    "timeline_table", 4, flags=im.TableFlags_.scroll_y | im.TableFlags_.resizable
  ):  ##
    ## Table setup
    im.table_setup_scroll_freeze(0, 2)  # Freezing 2 first rows
    im.table_setup_column(
      "", im.TableColumnFlags_.width_fixed | im.TableColumnFlags_.no_direct_resize_
    )
    im.table_setup_column(
      "", im.TableColumnFlags_.width_fixed | im.TableColumnFlags_.no_direct_resize_
    )
    im.table_setup_column("", im.TableColumnFlags_.width_fixed)
    im.table_setup_column(
      "", im.TableColumnFlags_.width_stretch | im.TableColumnFlags_.no_resize
    )
    ##

    ## Drawing top row (go to start/end, play button, play rate)
    im.table_next_row()
    im.table_set_column_index(3)
    if (
      im.button("<<")
      or im.is_key_pressed(im.Key._0)
      or (im.is_key_pressed(im.Key._6) and io.key_shift)
    ):
      atk.timeline_at = 0
      atk.timeline_started_playing_at = 0
    im.set_item_tooltip("Key: 0 / ^")

    im.same_line()
    if (
      im.button("⏸" if tim.is_playing else "▶")
      or im.is_key_pressed(im.Key.space)
      or im.is_key_pressed(im.Key.enter)
    ):
      tim.is_playing = not tim.is_playing
      if tim.is_playing:
        atk.timeline_started_playing_at = atk.timeline_at
      elif im.is_key_pressed(im.Key.space):
        atk.timeline_at = atk.timeline_started_playing_at
    im.set_item_tooltip("Key: space (resets to start) / enter (continues)")

    im.same_line()
    if im.button(">>") or (im.is_key_pressed(im.Key._4) and io.key_shift):
      atk.timeline_at = atk.ref.duration_frames
      atk.timeline_started_playing_at = atk.ref.duration_frames
    im.set_item_tooltip("Key: $")

    im.same_line()
    changed, value = im.checkbox("Play once", g.play_once)
    if changed:
      g.play_once = value
      g.schedule_dump()

    im.same_line()
    changed, value = im.slider_float(
      "Play rate",
      g.play_rate,
      0.25,
      4,
      "%.2f",
      im.SliderFlags_.logarithmic | im.SliderFlags_.always_clamp,
    )
    if changed:
      g.play_rate = value
      g.schedule_dump()

    im.dummy((0, 0))
    ##

    ## Drawing line with playhead
    im.table_next_row()
    im.table_set_column_index(3)
    imgui_timeline_line(atk.ref.duration_frames, 1, im.get_color_u32(im.Col_.frame_bg))
    lines_top_left = imgui_timeline_line_out.pos_top_left
    lines_bottom_right = imgui_timeline_line_out.pos_bottom_right
    if im.is_mouse_down(0) and (
      imgui_timeline_line_out.hovered or g.timeline.dragging_playhead
    ):
      atk.timeline_at = imgui_timeline_line_out.hovered_indexf
      g.timeline.dragging_playhead = True
    elif not im.is_mouse_down(0):
      g.timeline.dragging_playhead = False
    im.dummy((0, 0))
    ##

    ## Drawing impulses
    for impulse in atk.ref.impulses:
      im.table_next_row()
      im.table_set_column_index(3)
      line_color = im.get_color_u32(im.Col_.frame_bg)
      if impulse == atk.impulse.ref_selected:
        line_color = im.get_color_u32(im.Col_.frame_bg_hovered)
      imgui_timeline_line(atk.ref.duration_frames, 1, line_color)
      lines_bottom_right = imgui_timeline_line_out.pos_bottom_right
      out = imgui_timeline_line_out
      w_per_frame = (
        out.pos_bottom_right.x - out.pos_top_left.x
      ) / atk.ref.duration_frames
      draw = im.get_window_draw_list()
      draw.add_rect_filled(
        ImVec2(
          impulse.at * w_per_frame + out.pos_top_left.x,
          out.pos_top_left.y,
        ),
        ImVec2(
          (impulse.at + impulse.dur) * w_per_frame + out.pos_top_left.x,
          out.pos_bottom_right.y,
        ),
        COLOR_RED_FADED_U32,
      )
      im.dummy((0, 0))
    ##

    c = atk.get_visualization_collider()

    for f, frames, ktype, visit_type in _timeline_visit_frames():
      im.table_next_row()

      ## Column 0. Label
      im.table_set_column_index(0)
      im.text(f.split("__", 1)[-1])
      ##

      ## Column 1. `<` and `>` buttons
      im.table_set_column_index(1)

      index_f = _get_closest_keyframe(frames, atk.timeline_at)[0]
      field_is_the_same_as_of_selected_keyframe = tim.selected_keyframe and (
        tim.selected_keyframe.field == f
      )

      if not len(frames):
        bf.imgui_begin_disabled()
      if index_f <= 0:
        bf.imgui_begin_disabled()
      if im.button(bf.imgui_id("<", f)) or (
        (not bf.imgui_is_disabled())
        and im.is_key_pressed(im.Key.a)
        and field_is_the_same_as_of_selected_keyframe
      ):
        _select_keyframe(f, index_f - 1, frames)
      if field_is_the_same_as_of_selected_keyframe:
        im.set_item_tooltip("Key: A")
      if index_f == 0:
        bf.imgui_end_disabled()
      im.same_line()
      if index_f >= len(frames) - 1:
        bf.imgui_begin_disabled()
      if im.button(bf.imgui_id(">", f)) or (
        (not bf.imgui_is_disabled())
        and im.is_key_pressed(im.Key.d)
        and tim.selected_keyframe
        and field_is_the_same_as_of_selected_keyframe
      ):
        _select_keyframe(f, index_f + 1, frames)
      if field_is_the_same_as_of_selected_keyframe:
        im.set_item_tooltip("Key: D")
      if index_f >= len(frames) - 1:
        bf.imgui_end_disabled()
      if not len(frames):
        bf.imgui_end_disabled()
      ##

      ## Column 2. Field input
      im.table_set_column_index(2)

      match visit_type:
        case TimelineVisitType.ATTACK:
          match ktype:
            case _KeyframeTypeBool():
              _inspector_checkbox(
                bf.imgui_id("", f"timeline_field_{f}"),
                lambda: frames[index_f].value,
                lambda x: (
                  atk.scheduled_commands.append(
                    _CommandAttackAlterKeyframeField(
                      atk=atk,
                      field=f,
                      index_inside_list=index_f,
                      old=frames[index_f].value,
                      new=x,
                    )
                  )
                  if frames[index_f].value != x
                  else None
                ),
              )

            case _KeyframeTypeFloat():
              _inspector_input_float(
                bf.imgui_id("", f"timeline_field_{f}"),
                lambda: frames[index_f].value,
                lambda x: (
                  atk.scheduled_commands.append(
                    _CommandAttackAlterKeyframeField(
                      atk=atk,
                      field=f,
                      index_inside_list=index_f,
                      old=frames[index_f].value,
                      new=x,
                    )
                  )
                  if frames[index_f].value != x
                  else None
                ),
                ktype.min,
                ktype.max,
                ktype.step,
                ktype.step_fast,
                ktype.fmt,
              )

            case _KeyframeTypeV2():
              _inspector_input_float(
                bf.imgui_id("", f"timeline_field_{f}_x"),
                lambda: frames[index_f].value.x,  # ty:ignore[unresolved-attribute]
                lambda x: (
                  atk.scheduled_commands.append(
                    _CommandAttackAlterKeyframeField(
                      atk=atk,
                      field=f,
                      index_inside_list=index_f,
                      old=frames[index_f].value,
                      new=vec2(x, frames[index_f].value.y),  # ty:ignore[unresolved-attribute]
                    )
                  )
                  if frames[index_f].value.x != x  # ty:ignore[unresolved-attribute]
                  else None
                ),
                -_MAX_OFFSET,
                _MAX_OFFSET,
                ktype.step,
                1,
                "%.2f",
              )
              _inspector_input_float(
                bf.imgui_id("", f"timeline_field_{f}_y"),
                lambda: frames[index_f].value.y,  # ty:ignore[unresolved-attribute]
                lambda x: (
                  atk.scheduled_commands.append(
                    _CommandAttackAlterKeyframeField(
                      atk=atk,
                      field=f,
                      index_inside_list=index_f,
                      old=frames[index_f].value,
                      new=vec2(frames[index_f].value.x, x),  # ty:ignore[unresolved-attribute]
                    )
                  )
                  if frames[index_f].value.y != x  # ty:ignore[unresolved-attribute]
                  else None
                ),
                -_MAX_OFFSET,
                _MAX_OFFSET,
                ktype.step,
                1,
                "%.2f",
              )

            case _:
              assert 0

        case TimelineVisitType.COLLIDER_ANIMATED:
          assert c
          match ktype:
            case _KeyframeTypeBool():
              _inspector_checkbox(
                bf.imgui_id("", f"timeline_field_{f}"),
                lambda: frames[index_f].value,
                lambda x: (
                  atk.scheduled_commands.append(
                    _CommandAttackColliderAlterKeyframeField(
                      atk=atk,
                      collider_id=c.ref.id,
                      field=f,
                      index_inside_list=index_f,
                      old=frames[index_f].value,
                      new=x,
                    )
                  )
                  if frames[index_f].value != x
                  else None
                ),
              )

            case _KeyframeTypeFloat():
              _inspector_input_float(
                bf.imgui_id("", f"timeline_field_{f}"),
                lambda: frames[index_f].value,
                lambda x: (
                  atk.scheduled_commands.append(
                    _CommandAttackColliderAlterKeyframeField(
                      atk=atk,
                      collider_id=c.ref.id,
                      field=f,
                      index_inside_list=index_f,
                      old=frames[index_f].value,
                      new=x,
                    )
                  )
                  if frames[index_f].value != x
                  else None
                ),
                ktype.min,
                ktype.max,
                ktype.step,
                ktype.step_fast,
                ktype.fmt,
              )

            case _KeyframeTypeV2():
              _inspector_input_float(
                bf.imgui_id("", f"timeline_field_{f}_x"),
                lambda: frames[index_f].value.x,  # ty:ignore[unresolved-attribute]
                lambda x: (
                  atk.scheduled_commands.append(
                    _CommandAttackColliderAlterKeyframeField(
                      atk=atk,
                      collider_id=c.ref.id,
                      field=f,
                      index_inside_list=index_f,
                      old=frames[index_f].value,
                      new=vec2(x, frames[index_f].value.y),  # ty:ignore[unresolved-attribute]
                    )
                  )
                  if frames[index_f].value.x != x  # ty:ignore[unresolved-attribute]
                  else None
                ),
                -_MAX_OFFSET,
                _MAX_OFFSET,
                ktype.step,
                1,
                "%.2f",
              )
              _inspector_input_float(
                bf.imgui_id("", f"timeline_field_{f}_y"),
                lambda: frames[index_f].value.y,  # ty:ignore[unresolved-attribute]
                lambda x: (
                  atk.scheduled_commands.append(
                    _CommandAttackColliderAlterKeyframeField(
                      atk=atk,
                      collider_id=c.ref.id,
                      field=f,
                      index_inside_list=index_f,
                      old=frames[index_f].value,
                      new=vec2(frames[index_f].value.x, x),  # ty:ignore[unresolved-attribute]
                    )
                  )
                  if frames[index_f].value.y != x  # ty:ignore[unresolved-attribute]
                  else None
                ),
                -_MAX_OFFSET,
                _MAX_OFFSET,
                ktype.step,
                1,
                "%.2f",
              )

            case _:
              assert 0

        case _:
          raise AssertionError
      ##

      ## Column 3. Timeline line
      im.table_set_column_index(3)

      if tim.selected_keyframe and (f == tim.selected_keyframe.field):
        line_color = im.get_color_u32(im.Col_.frame_bg_hovered)
      else:
        line_color = im.get_color_u32(im.Col_.frame_bg)
      imgui_timeline_line(atk.ref.duration_frames, ktype.line_spanning_rows, line_color)

      lines_bottom_right = imgui_timeline_line_out.pos_bottom_right
      ##

      match visit_type:
        case TimelineVisitType.ATTACK:  ##
          fmove = lambda old_tim_index, new_tim_index: atk.scheduled_commands.append(
            _CommandAttackKeyframeMove(
              atk=atk,
              field=f,
              index_timeline_from=old_tim_index,
              index_timeline_to=new_tim_index,
            )
          )
          fadd = lambda new_tim_index: atk.scheduled_commands.append(
            _CommandAttackKeyframeAdd(
              atk=atk,
              field=f,
              index_timeline=new_tim_index,
            )
          )
          fremove = lambda in_list_index: atk.scheduled_commands.append(
            _CommandAttackKeyframeRemove(
              atk=atk,
              field=f,
              index_timeline=frames[in_list_index].index_timeline,
              value=frames[in_list_index].value,
            )
          )
          ##

        case TimelineVisitType.COLLIDER_ANIMATED:  ##
          assert c
          fmove = lambda old_tim_index, new_tim_index: atk.scheduled_commands.append(
            _CommandAttackColliderKeyframeMove(
              atk=atk,
              collider_id=c.ref.id,
              field=f,
              index_timeline_from=old_tim_index,
              index_timeline_to=new_tim_index,
            )
          )
          fadd = lambda new_tim_index: atk.scheduled_commands.append(
            _CommandAttackColliderKeyframeAdd(
              atk=atk,
              collider_id=c.ref.id,
              field=f,
              index_timeline=new_tim_index,
            )
          )
          fremove = lambda in_list_index: atk.scheduled_commands.append(
            _CommandAttackColliderKeyframeRemove(
              atk=atk,
              collider_id=c.ref.id,
              field=f,
              index_timeline=frames[in_list_index].index_timeline,
              value=frames[in_list_index].value,
            )
          )
          ##

        case _:
          raise AssertionError

      draw_and_handle_keyframes(f, frames, ktype, fmove, fadd, fremove)

    im.end_table()

    ## WASD keyframes movement
    voff_field = None
    voff_field_index = -1
    if tim.selected_keyframe:
      voff_field = tim.selected_keyframe.field
      voff_field_index = next(
        (i for i, pair in enumerate(keyframes_to_handle) if pair[0] == voff_field),
        -1,
      )

    vertical_off = 0
    for disabled, key, voff in (
      ((voff_field_index <= 0), im.Key.w, -1),
      ((voff_field_index >= len(keyframes_to_handle) - 1), im.Key.s, 1),
    ):
      if (not disabled) and im.is_key_pressed(key):
        vertical_off = voff

    if vertical_off and (tim.selected_keyframe is not None):
      new_field_to_select, new_frames = keyframes_to_handle[
        voff_field_index + vertical_off
      ]
      _select_keyframe(
        new_field_to_select,
        _get_closest_keyframe(new_frames, tim.selected_keyframe.index_timeline)[0],
        new_frames,
      )
    ##

    ## Drawing cell lines
    assert lines_top_left
    draw = im.get_window_draw_list()

    for i in range(atk.ref.duration_frames):
      posx = (
        lines_top_left.x + i * imgui_timeline_line_out.width / atk.ref.duration_frames
      )
      draw.add_line(
        ImVec2(posx, lines_top_left.y),
        ImVec2(posx, lines_bottom_right.y),
        im.get_color_u32(im.Col_.text if hovered_frame_index == i else im.Col_.border),
      )
    ##

    ## Drawing playhead
    playhead_top = lines_top_left + ImVec2(
      atk.timeline_at / atk.ref.duration_frames * imgui_timeline_line_out.width, 0
    )
    playhead_bottom = ImVec2(playhead_top.x, lines_bottom_right.y)
    line_height = imgui_timeline_line_out.height
    draw.add_triangle_filled(
      playhead_top + ImVec2(0, line_height / 2),
      playhead_top + ImVec2(line_height / 4, 0),
      playhead_top + ImVec2(-line_height / 4, 0),
      im.get_color_u32(im.Col_.button_active),
    )
    draw.add_line(
      playhead_top,
      playhead_bottom,
      im.get_color_u32(im.Col_.button_active),
      2 * im.get_window_dpi_scale(),
    )
    ##

  ## Teardown
  if not were_dragging_keyframe_this_frame:
    tim.dragging_keyframe = None
  im.dummy((0, 0))
  ##


def _inspector_checkbox(
  label: str, getter: Callable[[], bool], setter: Callable[[bool], None]
) -> None:  ##
  changed, value = im.checkbox(label, getter())
  if changed:
    setter(value)
  ##


def _inspector_input_float(
  label: str,
  getter: Callable[[], float],
  setter: Callable[[float], None],
  vmin: float,
  vmax: float,
  step: float,
  step_fast: float,
  fmt: str,
) -> None:  ##
  im.set_next_item_width(im.get_content_region_avail()[0])
  changed, value = im.input_float(label, getter(), step, step_fast, format=fmt)
  if changed:
    setter(bf.clamp(round(value / step) * step, vmin, vmax))
  ##


def _get_closest_keyframe(
  keyframes: _GKeyframesContainer, to: float = 0
) -> tuple[int, _GKeyframe]:  ##
  return min(enumerate(keyframes), key=lambda x: abs(x[1].index_timeline - to))
  ##


def _show_status() -> None:  ##
  atk = g.ref_selected_attack
  if atk:
    im.same_line()
    im.text("|")

    im.same_line()
    im.text(f"history: {atk.history_head}")
  ##


def _post_new_frame() -> None:  ##
  if g.scheduled_dump:
    g.scheduled_dump = False
    _dump_app_state()

  tim = g.timeline
  io = im.get_io()

  if any((im.is_mouse_clicked(x) or im.is_mouse_released(x)) for x in range(3)):
    g.action_id += 1

  if g.attack_to_select:
    g.ref_selected_attack = g.attack_to_select
    g.attack_to_select = None

  atk = g.ref_selected_attack
  if atk:
    if atk.collider.deselection_scheduled:
      atk.collider.ref_selected = None
      atk.collider.deselection_scheduled = False

    atk.collider.ref_hovered = None
    if atk.collider.to_hover:
      atk.collider.ref_hovered = atk.collider.to_hover
      atk.collider.to_hover = None

    # Executing commands.
    if atk.scheduled_commands:
      while atk.history_head + 1 < len(atk.history):
        atk.history.pop()

    atk_should_be_saved = bool(atk.scheduled_commands)

    for command in atk.scheduled_commands:
      command.do()
      atk.history_head += 1
      atk.history.append(command)
      if (
        (len(atk.history) >= 2)
        and (type(h_latest := atk.history[-1]) is type(h_prev := atk.history[-2]))
        and (h_latest.merge_id == h_prev.merge_id)
      ):
        match h_prev.try_merge(h_latest):
          case _CommandMergeType.MERGED_OKAY:
            atk.history_head -= 1
            atk.history.pop()
          case _CommandMergeType.MERGED_SHOULD_BE_DESTROYED:
            atk.history_head -= 1
            atk.history.pop()
            if h_latest.merge_id != g.action_id:
              atk.history_head -= 1
              atk.history.pop()
    atk.scheduled_commands.clear()
    if atk.collider.to_select:
      atk.collider.ref_selected = atk.collider.to_select
      atk.collider.to_select = None

    # Handling undo.
    g.attack_undo_scheduled = io.key_ctrl and im.is_key_pressed(im.Key.z)
    if g.attack_undo_scheduled:
      g.attack_undo_scheduled = False
      if atk.history_head >= 0:
        atk.history[atk.history_head].undo()
        atk.history_head -= 1
        atk_should_be_saved = True

    # Handling redo.
    g.attack_redo_scheduled = io.key_ctrl and im.is_key_pressed(im.Key.r)
    if g.attack_redo_scheduled:
      g.attack_redo_scheduled = False
      if atk.history_head < len(atk.history) - 1:
        atk.history_head += 1
        atk.history[atk.history_head].do()
        atk_should_be_saved = True

    if atk_should_be_saved:
      export_path = atk.export_path
      bf.recursive_mkdir(export_path.parent)
      dict_to_dump = _ExportAttack(
        **MessageToDict(
          atk.ref,
          preserving_proto_field_name=True,
          always_print_fields_with_no_presence=True,
        )
      ).model_dump()
      with bf.sane_writable_file(export_path) as out_file:
        yaml.dump(dict_to_dump, out_file, indent=2, line_break="\n")

    if tim.keyframe_to_select:
      keyframe, update_timeline = tim.keyframe_to_select
      if update_timeline:
        atk.timeline_at = keyframe.index_timeline
      tim.selected_keyframe = keyframe
      tim.keyframe_to_select = None

    if tim.selected_keyframe:
      found = False
      for f, frames, _1, _2 in _timeline_visit_frames():
        if tim.selected_keyframe.field == f:
          found = True
          _select_keyframe(
            tim.selected_keyframe.field,
            _get_closest_keyframe(frames, atk.timeline_at)[0],
            frames,
            update_timeline_playhead=False,
          )
      if not found:
        tim.selected_keyframe = None

  ##


def _next_keyframe_id(frames: _GContainer) -> _KeyframeID:  ##
  result = 1
  for fr in frames:
    result = max(result, fr.id + 1)
  return result
  ##


def _make_keyframe_value_at(
  frames: _GContainer, keyframe_type: _KeyframeType, index_timeline: float
) -> tuple[int, t.Any]:  ##
  for i, fr in enumerate(frames):
    if abs(fr.index_timeline - index_timeline) < 0.001:
      return (i, keyframe_type.make_copy(fr.value))

  for _, left, right_list_index, right in bf.iter_neighbors(frames):
    if left and right:
      if left.index_timeline < index_timeline < right.index_timeline:
        t = (index_timeline - left.index_timeline) / (
          right.index_timeline - left.index_timeline
        )
        return (
          right_list_index,
          keyframe_type.make_lerp(left.value, right.value, t),
        )

    elif left:
      if left.index_timeline < index_timeline:
        return (right_list_index, keyframe_type.make_copy(left.value))

    elif right:
      if index_timeline < right.index_timeline:
        return (right_list_index, keyframe_type.make_copy(right.value))

  return (0, keyframe_type.make_default())
  ##


def _make_default_keyframe_at(
  frames: _GContainer, keyframe_type: _KeyframeType, index_timeline: int
) -> tuple[int, _GKeyframe]:  ##
  assert index_timeline >= 0
  for fr in frames:
    assert fr.index_timeline != index_timeline
  with _override_keyframe_round_to_step(True):
    insert_index, value = _make_keyframe_value_at(frames, keyframe_type, index_timeline)
  k: _GKeyframe = keyframe_type.proto_class()(
    id=_next_keyframe_id(frames),
    index_timeline=index_timeline,
    value=value,
  )
  frames.insert(insert_index, k)
  assert frames == sorted(frames, key=lambda x: x.index_timeline)
  return (insert_index, k)
  ##


def _test_make_default_keyframe_at():  ##
  c = _TransientColliderAnimated.make(1, _ColliderType.CIRCLE)
  c.ref.circle__radius[0].index_timeline = 10
  for v in (5, 15, 9, 11):
    _make_default_keyframe_at(*c.get_keyframes("circle__radius"), v)
    assert list(c.ref.circle__radius) == sorted(
      c.ref.circle__radius, key=lambda x: x.index_timeline
    )

  ##


def _test_first_keyframe_yields_correct_values():  ##
  c = _TransientColliderAnimated.make(1, _ColliderType.CAPSULE)
  c.ref.tr[0].value = GV2(random.uniform(-100, 100), random.uniform(-100, 100))
  c.ref.capsule__radius[0].value = random.uniform(0.25, 2)

  _, v = _make_keyframe_value_at(*c.get_keyframes("tr"), 0)
  assert isinstance(v, vec2)
  assert v == c.ref.tr[0].value

  _, r = _make_keyframe_value_at(*c.get_keyframes("capsule__radius"), 0)
  assert r == c.ref.capsule__radius[0].value
  ##
