## Imports
import asyncio
import math
import random
import shutil
import sys
import tempfile
import threading
import traceback
import typing as t
from abc import ABC, abstractmethod
from contextlib import contextmanager
from dataclasses import dataclass, field, fields, is_dataclass
from datetime import datetime
from enum import IntEnum, unique
from functools import partial, wraps
from math import pi
from pathlib import Path
from typing import Callable, Generic, Self, TypeAlias, TypeVar

import bf_lib as bf
import numpy as np
import toml
from bf_lib import imgui_assert as ass
from bf_typer import command
from imgui_bundle import ImVec2, ImVec2_Pydantic, hello_imgui, imguizmo
from imgui_bundle import imgui as im
from pydantic import BaseModel
from pyglm import glm
from pyglm.glm import mat4, radians, vec2, vec3, vec4

##

## Consts
FPS = 30
MAX_ATTACK_FRAMES_DURATION = 10 * FPS
STEP_TRANSLATE = 0.25
STEP_ROTATE = 15
STEP_SCALE = 0.25
MAX_OFFSET: float = 10.0
MIN_RADIUS: float = 0.125
MAX_RADIUS: float = 5.0
MAX_SPREAD: float = 10.0
##


## Setup
ColliderID: TypeAlias = int
KeyframeID: TypeAlias = int


def recursive_validate(obj: t.Any) -> None:
  if x := getattr(obj, "validate", None):
    x()

  if is_dataclass(obj):
    for f in fields(obj):
      recursive_validate(getattr(obj, f.name))

  elif isinstance(obj, (list, tuple, set)):
    for item in obj:
      recursive_validate(item)

  elif isinstance(obj, dict):
    for item in obj.values():
      recursive_validate(item)


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
SNAP_TRANSLATE.values[:] = STEP_TRANSLATE
SNAP_ROTATE.values[:] = STEP_ROTATE
SNAP_SCALE.values[:] = STEP_SCALE


# fmt: off
def identity_matrix() ->  Matrix16:
  return gizmo.Matrix16([
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.0, 0.0, 0.0, 1.0])
# fmt: on


def lerp_Matrix16(
  v1: Matrix16, v2: Matrix16, t: float, step_translate: float | None = None
) -> Matrix16:
  c1 = gizmo.decompose_matrix_to_components(v1)
  c2 = gizmo.decompose_matrix_to_components(v2)
  c = gizmo.MatrixComponents()
  c.translation.values[:] = c1.translation.values * (1 - t) + c2.translation.values * t
  if step_translate is not None:
    ass(step_translate > 0)
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

_dump_app_state_lock = threading.Lock()


def _dump_app_state():
  with _dump_app_state_lock:
    LOGD("Saving...")
    with tempfile.NamedTemporaryFile(
      "w", encoding="utf-8", delete=False, suffix=".toml"
    ) as out:
      out_path = Path(out.name)
      toml.dump(g.dump().model_dump(), out)
    shutil.move(out_path, _APP_STATE_FILE_PATH)


async def _background_dump_run_data():
  while True:
    await g.scheduled_dump.acquire()
    _dump_app_state()


@command
def tool_attacks_markuper() -> None:
  atk1 = Attack(
    name="ROLL_FRONT",
    duration_frames=60,
    colliders=[],
  )
  atk1.colliders.append(ColliderCapsule.make(atk1.next_collider_id()))
  g.creatures = [
    Creature(
      name="MOB_SPEAR",
      attacks=[
        Attack(name="DASH", duration_frames=90),
        Attack(name="SWING"),
      ],
    ),
    Creature(
      name="BOSS_JAGRAS",
      attacks=[
        atk1,
        Attack(name="ROLL_SIDE", duration_frames=50),
        Attack(name="JUMP_BACK"),
      ],
    ),
  ]
  c = ColliderCapsule.make(g.creatures[0].attacks[0].next_collider_id())
  c.radius.append(Keyframe(40, 5, c._next_keyframe_id()))
  c.radius.append(Keyframe(70, 4, c._next_keyframe_id()))
  g.creatures[0].attacks[0].colliders.append(c)
  g.creatures[0].attacks[0].timeline_at = 2

  recursive_validate(g)

  loaded_state: AppSaveState | None = None
  if _APP_STATE_FILE_PATH.exists():
    with open(_APP_STATE_FILE_PATH, encoding="utf-8") as in_file:
      state_data = toml.load(in_file)
    loaded_state = AppSaveState(**state_data)
    g.load(loaded_state)

  recursive_validate(g)

  # removeme
  if atk := g.ref_selected_attack:
    if atk.colliders:
      atk.collider_to_select = atk.colliders[0]

  def setup_imgui_style():
    if loaded_state:
      im.get_style().font_scale_main = loaded_state.font_scale_main

  def enable_debug(func):
    @wraps(func)
    def exception_wrapper():
      try:
        func()
      except Exception as e:
        traceback.print_exception(*sys.exc_info())
        _trace = traceback.format_exception(e)
        breakpoint()
        raise

    return exception_wrapper

  async def wrapper() -> None:
    _dump_task = asyncio.create_task(_background_dump_run_data())
    await bf.show_imgui(
      "Attacks Markuper",
      [
        bf.ImGuiPanel("Visualizer", enable_debug(_panel_visualizer)),
        bf.ImGuiPanel("Explorer", enable_debug(_panel_explorer)),
        bf.ImGuiPanel("Attack", enable_debug(_panel_attack_inspector)),
        bf.ImGuiPanel("Collider", enable_debug(_panel_collider_inspector)),
        bf.ImGuiPanel("Timeline", enable_debug(_panel_timeline)),
        bf.ImGuiPanel("Logs", hello_imgui.log_gui),
      ],
      setup_imgui_style=setup_imgui_style,
      post_new_frame=_post_new_frame,
      before_exit=_dump_app_state,
    )
    _dump_task.cancel()

  asyncio.run(wrapper(), debug=True)


_gizmo_restricted: bool = False


@contextmanager
def gizmo_restrict(
  m: Matrix16,
  mask: tuple[bool, bool, bool],
  disable_translation_x: bool = False,
  disable_translation_y: bool = False,
  disable_translation_z: bool = False,
):
  global _gizmo_restricted
  ass(not _gizmo_restricted)

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


@dataclass(slots=True)
class Keyframe(Generic[T]):  ##
  index_timeline: int
  value: T
  id: int = 0

  def validate(self):
    ass(self.id > 0)
    ass(self.index_timeline >= 0)

  ##


@dataclass(slots=True, frozen=True)
class SelectedKeyframe:  ##
  id: int
  key: str  # e.g. "keyframe_radius_0"
  field: str  # e.g. "radius" / "spread"
  index_timeline: int
  index_inside_list: int

  def validate(self):
    ass(self.id > 0)
    ass(self.index_timeline >= 0)

  ##


@unique
class ColliderType(IntEnum):  ##
  INVALID = 0
  CIRCLE = 1
  CAPSULE = 2
  ##


@unique
class KeyframeTypeEnum(IntEnum):  ##
  INVALID = 0
  BOOL = 1
  FLOAT = 2
  VEC2 = 3
  ##


@t.runtime_checkable
class KeyframeType(t.Protocol[T]):  ##
  type: t.ClassVar[KeyframeTypeEnum]
  line_spanning_rows: t.ClassVar[int] = 1

  def make_default(self) -> T: ...

  def make_copy(self, v: T) -> T: ...

  def make_lerp(self, v1: T, v2: T, t: float) -> T: ...

  ##


@dataclass
@t.final
class KeyframeTypeBool(KeyframeType[bool]):  ##
  type: t.ClassVar[KeyframeTypeEnum] = KeyframeTypeEnum.BOOL

  default: bool

  def make_default(self) -> bool:
    return self.default

  def make_copy(self, v: bool) -> bool:
    return v

  def make_lerp(self, v1: bool, v2: bool, t: float) -> bool:  # noqa: ARG002
    ass(0 <= t <= 1)
    return v1

  ##


@dataclass
class KeyframeTypeFloat(KeyframeType[float]):  ##
  type: t.ClassVar[KeyframeTypeEnum] = KeyframeTypeEnum.FLOAT

  default: float
  step: float
  step_fast: float
  min: float = bf.FLOAT_INF_NEG
  max: float = bf.FLOAT_INF_POS
  fmt: str = "%.3f"

  def make_default(self) -> float:
    bf.imgui_assert(self.min <= self.default <= self.max)
    return self.default

  def make_copy(self, v: float) -> float:
    bf.imgui_assert(self.min <= v <= self.max)
    return v

  def make_lerp(self, v1: float, v2: float, t: float) -> float:
    ass(0 <= t <= 1)
    result = bf.lerp(v1, v2, t)
    bf.imgui_assert(self.min <= v1 <= self.max)
    bf.imgui_assert(self.min <= v2 <= self.max)
    bf.imgui_assert(self.min <= result <= self.max)
    if g.visualizer.round_to_step:
      result = bf.round_to_step(result, self.step)
    return result

  ##


def _lerp_vec2(v1: vec2, v2: vec2, t: float, step: float | None = None):  ##
  result = bf.lerp(v1, v2, t)
  if step is not None:
    result = bf.round_to_step(result, step)
  return result
  ##


@dataclass
class KeyframeTypeTr(KeyframeType[vec2]):  ##
  type: t.ClassVar[KeyframeTypeEnum] = KeyframeTypeEnum.VEC2

  line_spanning_rows: t.ClassVar[int] = 2

  default: vec2 = field(default_factory=vec2)
  step: float = STEP_TRANSLATE

  def make_default(self) -> vec2:
    return vec2(self.default)

  def make_copy(self, v: vec2) -> vec2:
    return vec2(v)

  def make_lerp(self, v1: vec2, v2: vec2, t: float) -> vec2:
    ass(0 <= t <= 1)
    result = bf.lerp(v1, v2, t)
    if g.visualizer.round_to_step:
      result = bf.round_to_step(result, self.step)
    return result

  ##


class ColliderBaseMeta(type):  ##
  def __init__(cls, name, bases, namespace):
    super().__init__(name, bases, namespace)
    is_base = name == "ColliderBase"
    ass(is_base or (ColliderBase in bases))
    if is_base:
      return

    cls.keyframe_fields = []

    for field_name, field_type in cls.__annotations__.items():
      origin = t.get_origin(field_type)
      args = t.get_args(field_type)

      if (origin in (list, t.List)) and args:  # noqa: UP006
        if t.get_origin(args[0]) is Keyframe:
          cls.keyframe_fields.append(field_name)

    prefix = "_keyframe_"
    for field_name, field_type in namespace.items():
      if field_name == "_keyframe_values":
        continue
      if field_name.startswith(prefix):
        field_name_wo_prefix = field_name.removeprefix(prefix)
        ass(isinstance(field_type, KeyframeType))
        ass(field_name_wo_prefix in cls.keyframe_fields)

    for f in cls.keyframe_fields:
      ass(f"{prefix}{f}" in namespace)

  ##


class ColliderBase(metaclass=ColliderBaseMeta):  ##
  id: int = 0
  type: t.ClassVar[ColliderType] = ColliderType.INVALID
  keyframe_fields: t.ClassVar[list[str]]

  selected_keyframe: SelectedKeyframe | None = None
  keyframe_to_select: tuple[SelectedKeyframe, bool] | None = None
  keyframe_to_remove: tuple[str, int] | None = None

  __next_keyframe_id: KeyframeID = 1

  def __new__(cls, *_args, **_kwargs):
    ass(cls is not ColliderBase)
    return super().__new__(cls)

  def _next_keyframe_id(self) -> KeyframeID:
    result = self.__next_keyframe_id
    self.__next_keyframe_id += 1
    return result

  def get_keyframes(self, field_name: str) -> list[Keyframe]:
    ass(field_name in self.keyframe_fields)
    return getattr(self, field_name)

  def get_keyframe_type(self, field_name: str) -> KeyframeType:
    return getattr(self, f"_keyframe_{field_name}")

  def make_keyframe_value_at(
    self, field: str, index_timeline: float
  ) -> tuple[int, t.Any]:
    frames = self.get_keyframes(field)
    keyframe_type = self.get_keyframe_type(field)

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

  def make_default_keyframe_at(self, field: str, index_timeline: int) -> None:
    frames = self.get_keyframes(field)
    for fr in frames:
      ass(fr.index_timeline != index_timeline)
    with _override_keyframe_round_to_step(True):
      insert_index, value = self.make_keyframe_value_at(field, index_timeline)
    frames.insert(insert_index, Keyframe(index_timeline, value, self._next_keyframe_id()))
    ass(frames == sorted(frames, key=lambda x: x.index_timeline))

  def select_keyframe(
    self,
    field_name: str,
    index_inside_list: int,
    *,
    update_timeline_playhead: bool = True,
  ) -> None:
    frames = self.get_keyframes(field_name)
    fr = frames[index_inside_list]
    self.keyframe_to_select = (
      SelectedKeyframe(
        id=fr.id,
        key=_keyframe_id(field_name, fr.id),
        field=field_name,
        index_timeline=fr.index_timeline,
        index_inside_list=index_inside_list,
      ),
      update_timeline_playhead,
    )

  def validate(self):
    ass(self.id > 0)
    for frames in (self.get_keyframes(x) for x in self.keyframe_fields):
      for i in range(len(frames) - 1):
        ass(
          frames[i].index_timeline < frames[i + 1].index_timeline,
          ("Keyframes must be sorted by `index`"),
        )

  @classmethod
  def make(cls, id_: int) -> Self:
    ass(cls is not ColliderBase)
    result = cls(*[[] for _ in range(len(cls.keyframe_fields))])
    result.id = id_
    for f in cls.keyframe_fields:
      result.make_default_keyframe_at(f, 0)
    return result

  ##


@dataclass(slots=True)
class ColliderCircle(ColliderBase):  ##
  type: t.ClassVar[ColliderType] = ColliderType.CIRCLE

  is_active: list[Keyframe[bool]]
  tr: list[Keyframe[vec2]]
  radius: list[Keyframe[float]]

  _keyframe_is_active: t.ClassVar[KeyframeType] = KeyframeTypeBool(True)
  _keyframe_tr: t.ClassVar[KeyframeType] = KeyframeTypeTr()
  _keyframe_radius: t.ClassVar[KeyframeType] = KeyframeTypeFloat(
    0.5, step=STEP_TRANSLATE, step_fast=1, min=MIN_RADIUS, max=MAX_RADIUS, fmt="%.2f"
  )

  ##


@dataclass(slots=True)
class ColliderCapsule(ColliderBase):  ##
  type: t.ClassVar[ColliderType] = ColliderType.CAPSULE

  is_active: list[Keyframe[bool]]
  tr: list[Keyframe[vec2]]
  radius: list[Keyframe[float]]
  spread: list[Keyframe[float]]
  rotation: list[Keyframe[float]]

  _keyframe_is_active: t.ClassVar[KeyframeType] = KeyframeTypeBool(True)
  _keyframe_tr: t.ClassVar[KeyframeType] = KeyframeTypeTr()
  _keyframe_radius: t.ClassVar[KeyframeType] = KeyframeTypeFloat(
    0.5, step=STEP_TRANSLATE, step_fast=1, min=MIN_RADIUS, max=MAX_RADIUS, fmt="%.2f"
  )
  _keyframe_spread: t.ClassVar[KeyframeType] = KeyframeTypeFloat(
    1, step=STEP_TRANSLATE, step_fast=1, min=0, max=MAX_SPREAD, fmt="%.2f"
  )
  _keyframe_rotation: t.ClassVar[KeyframeType] = KeyframeTypeFloat(
    0, step=STEP_ROTATE, step_fast=90, fmt="%.0f"
  )
  ##


## Attack Commands
@dataclass(slots=True)
class AttackCommand(ABC):
  @abstractmethod
  def do(self, atk: "Attack") -> None: ...

  @abstractmethod
  def undo(self, atk: "Attack") -> None: ...


# @dataclass(slots=True)
# @t.final
# class AttackCommandAlterName(Command):
#   pass
#
#
# @dataclass(slots=True)
# @t.final
# class AttackCommandAlterFrames(Command):
#   pass


@dataclass(slots=True)
class AttackCommandCollider(AttackCommand):
  collider_id: ColliderID

  def c(self, atk: "Attack") -> "ColliderBase":
    return next(c for c in atk.colliders if c.id == self.collider_id)


@dataclass(slots=True)
@t.final
class AttackCommandColliderKeyframeAdd(AttackCommandCollider):
  keyframe_field: str
  keyframe_index_timeline: int

  def do(self, atk: "Attack") -> None:
    self.c(atk).make_default_keyframe_at(
      self.keyframe_field, self.keyframe_index_timeline
    )

  def undo(self, atk: "Attack") -> None:
    frames = self.c(atk).get_keyframes(self.keyframe_field)
    ass(len(frames) > 1)
    for i, fr in enumerate(frames):
      if fr.index_timeline == self.keyframe_index_timeline:
        del frames[i]
        return
    raise ValueError


@dataclass(slots=True)
@t.final
class AttackCommandColliderKeyframeMove(AttackCommandCollider):
  keyframe_field: str
  keyframe_index_timeline_from: int
  keyframe_index_timeline_to: int

  def do(self, atk: "Attack") -> None: ...

  def undo(self, atk: "Attack") -> None: ...


@dataclass(slots=True)
@t.final
class AttackCommandColliderKeyframeRemove(AttackCommandCollider):
  keyframe_field: str
  keyframe_index_timeline: int

  def do(self, atk: "Attack") -> None: ...

  def undo(self, atk: "Attack") -> None: ...


@dataclass(slots=True)
@t.final
class AttackCommandColliderAlterTr(AttackCommandCollider):
  keyframe_index_inside_list: int
  value_old: vec2
  value_new: vec2

  def do(self, atk: "Attack") -> None: ...

  def undo(self, atk: "Attack") -> None: ...


@dataclass(slots=True)
@t.final
class AttackCommandColliderAlterActive(AttackCommandCollider):
  keyframe_index_inside_list: int
  value_old: bool
  value_new: bool

  def do(self, atk: "Attack") -> None: ...

  def undo(self, atk: "Attack") -> None: ...


@dataclass(slots=True)
@t.final
class AttackCommandColliderAlterRotation(AttackCommandCollider):
  keyframe_index_inside_list: int
  value_old: float
  value_new: float

  def do(self, atk: "Attack") -> None: ...

  def undo(self, atk: "Attack") -> None: ...


@dataclass(slots=True)
@t.final
class AttackCommandColliderAlterRadius(AttackCommandCollider):
  keyframe_index_inside_list: int
  value_old: float
  value_new: float

  def do(self, atk: "Attack") -> None: ...

  def undo(self, atk: "Attack") -> None: ...


@dataclass(slots=True)
@t.final
class AttackCommandColliderAlterSpread(AttackCommandCollider):
  keyframe_index_inside_list: int
  value_old: float
  value_new: float

  def do(self, atk: "Attack") -> None: ...

  def undo(self, atk: "Attack") -> None: ...


##


@dataclass(slots=True)
class Attack:  ##
  name: str

  duration_frames: int = 90
  colliders: list[ColliderBase] = field(default_factory=list)

  collider_deselection_scheduled: bool = False
  collider_to_select: ColliderBase | None = None
  collider_to_hover: ColliderBase | None = None
  ref_selected_collider: ColliderBase | None = None
  ref_hovered_collider: ColliderBase | None = None

  timeline_at: float = 0
  timeline_started_playing_at: float = 0

  history: list[AttackCommand] = field(default_factory=list)
  scheduled_commands: list[AttackCommand] = field(default_factory=list)

  _next_collider_id: ColliderID = 1

  def next_collider_id(self) -> ColliderID:
    result = self._next_collider_id
    self._next_collider_id += 1
    return result

  def get_visualization_collider(self) -> ColliderBase | None:
    if self.ref_hovered_collider:
      return self.ref_hovered_collider
    return self.ref_selected_collider

  def validate(self):
    ass(self.name)
    ass(self.duration_frames > 0)
    ass(self.timeline_at >= 0)
    ass(self.timeline_at <= self.duration_frames)
    ass(self.timeline_started_playing_at >= 0)
    ass(self.timeline_started_playing_at <= self.duration_frames)

    for c in self.colliders:
      for frames in (c.get_keyframes(x) for x in c.keyframe_fields):
        for fr in frames:
          ass(fr.index_timeline >= 0)
          ass(fr.index_timeline < self.duration_frames)

  ##


@dataclass(slots=True)
class Creature:  ##
  name: str
  attacks: list[Attack]

  def validate(self):
    ass(self.name)
    ass(bf.are_unique(x.name for x in self.attacks))

  ##


@unique
class GizmoMode(IntEnum):  ##
  TRANSLATE = 0
  ROTATE = 1
  SCALE = 2
  ##


class AppSaveState(BaseModel):  ##
  font_scale_main: float = 1
  creature: str | None = None
  attack: str | None = None
  visualizer__gizmo_mode: int = GizmoMode.TRANSLATE
  ##


@dataclass(slots=True)
class State:
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
    gizmo_mode: GizmoMode = GizmoMode.TRANSLATE
    round_to_step: bool = False
    ##

  @dataclass(slots=True)
  class Timeline:  ##
    is_playing: bool = False
    dragging_playhead: bool = False
    dragging_keyframe: str | None = None
    ##

  visualizer: Visualizer = field(default_factory=Visualizer)
  timeline: Timeline = field(default_factory=Timeline)

  creatures: list[Creature] = field(default_factory=list)

  exiting: bool = False
  count: int = 0

  frame: int = 0

  attack_to_select: Attack | None = None
  ref_selected_attack_creature: Creature | None = None
  ref_selected_attack: Attack | None = None

  attack_undo_scheduled: bool = False

  scheduled_dump: asyncio.Semaphore = field(default_factory=lambda: asyncio.Semaphore(0))

  def dump(self) -> AppSaveState:  ##
    vis = self.visualizer
    return AppSaveState(
      font_scale_main=im.get_style().font_scale_main,
      creature=(
        self.ref_selected_attack_creature.name
        if self.ref_selected_attack_creature
        else None
      ),
      attack=self.ref_selected_attack.name if self.ref_selected_attack else None,
      visualizer__gizmo_mode=vis.gizmo_mode,
    )
    ##

  def load(self, value: AppSaveState) -> None:  ##
    for c in self.creatures:
      if c.name == value.creature:
        for atk in c.attacks:
          if atk.name == value.attack:
            self.ref_selected_attack_creature = c
            self.ref_selected_attack = atk
    ##

  def schedule_dump(self) -> None:  ##
    self.scheduled_dump.release()
    ##


g = State()


@contextmanager
def _override_keyframe_round_to_step(v: bool):  ##
  old = g.visualizer.round_to_step
  g.visualizer.round_to_step = v
  yield
  g.visualizer.round_to_step = old
  ##


def _panel_explorer() -> None:  ##
  for creature in g.creatures:
    creature_flags = im.TreeNodeFlags_.span_avail_width | im.TreeNodeFlags_.default_open
    if creature is g.ref_selected_attack_creature:
      creature_flags |= im.TreeNodeFlags_.selected
    if im.tree_node_ex(creature.name, creature_flags):
      for attack in creature.attacks:
        flags = (
          im.TreeNodeFlags_.leaf
          | im.TreeNodeFlags_.span_avail_width
          | im.TreeNodeFlags_.default_open
        )
        if attack is g.ref_selected_attack:
          flags |= im.TreeNodeFlags_.selected
        if im.tree_node_ex(attack.name, flags):
          if im.is_item_clicked():
            g.ref_selected_attack_creature = creature
            g.ref_selected_attack = attack
            g.schedule_dump()
          im.tree_pop()
      im.tree_pop()
  ##


def _panel_attack_inspector() -> None:  ##
  atk = g.ref_selected_attack
  if not atk:
    return

  im.text("Frames")
  im.same_line()
  min_attack_frames = 1
  for c in atk.colliders:
    for frames in (c.get_keyframes(x) for x in c.keyframe_fields):
      for frame in frames:
        min_attack_frames = max(min_attack_frames, frame.index_timeline + 1)
  im.set_next_item_width(im.get_content_region_avail()[0])
  changed, frames = im.slider_int(
    bf.imgui_id("", "attack_duration_frames"),
    atk.duration_frames,
    min_attack_frames,
    MAX_ATTACK_FRAMES_DURATION,
  )
  if changed:
    atk.duration_frames = frames
    atk.timeline_at = min(atk.timeline_at, frames)
    atk.timeline_started_playing_at = min(atk.timeline_started_playing_at, frames)

  if im.button("+circle"):
    atk.colliders.append(ColliderCircle.make(atk.next_collider_id()))
    atk.collider_to_select = atk.colliders[-1]
  im.same_line()
  if im.button("+capsule"):
    atk.colliders.append(ColliderCapsule.make(atk.next_collider_id()))
    atk.collider_to_select = atk.colliders[-1]

  for i, collider in enumerate(atk.colliders):
    flags = im.TreeNodeFlags_.leaf | im.TreeNodeFlags_.span_avail_width
    if atk.ref_selected_collider is collider:
      flags |= im.TreeNodeFlags_.selected
    if im.tree_node_ex(f"{i} {collider.type.name}", flags):
      if im.is_item_hovered():
        atk.collider_to_hover = collider
      if im.is_item_clicked():
        if atk.ref_selected_collider is collider:
          atk.collider_deselection_scheduled = True
        else:
          atk.collider_to_select = collider
      im.tree_pop()

  ##


def _panel_visualizer() -> None:
  atk = g.ref_selected_attack
  if atk is None:
    ass(g.ref_selected_attack_creature is None)
    return

  ## Setup
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
    points: list[vec3],
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
    ass(segments >= 8)
    ass(radius > 0)
    ass(isinstance(p, vec3))
    ass(glm.dot(plane[1], plane[0]) < 0.00001)
    normal = glm.cross(plane[0], plane[1])
    ass(abs(glm.length(normal) - 1) < 0.00001)
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
    ass(segments >= 8)
    ass(spread >= 0)
    ass(radius > 0)
    ass(isinstance(p, vec3))
    ass(segments % 2 == 0)
    ass(glm.dot(plane[0], plane[1]) < 0.00001)
    normal = glm.cross(plane[1], plane[0])
    ass(abs(glm.length(normal) - 1) < 0.00001)
    m = glm.rotate(2.0 * pi / segments, normal)

    plane_axis = vec4(plane[0], 0)  # type: ignore
    capsule_dir = vec3(glm.rotate(angle, normal) * plane_axis)
    spread_vector = capsule_dir * spread
    p1 = p + spread_vector / 2
    p2 = p - spread_vector / 2

    cur = -glm.cross(normal, capsule_dir) * radius
    for _ in range(segments // 2 + 1):
      _draw_points.append(p1 + vec3(cur))
      cur = m * cur
    _draw_points.append(_draw_points[-1] - spread_vector)
    for _ in range(segments // 2):
      _draw_points.append(p2 + vec3(cur))
      cur = m * cur
    draw_polyline(_draw_points, color, flags=im.ImDrawFlags_.closed)
    _draw_points.clear()
    draw_line(p1 + capsule_dir / 5, p2 - capsule_dir / 5, color)

  gizmo.begin_frame()
  gizmo.set_drawlist()
  gizmo.set_rect(pos_.x, pos_.y, size_.x, size_.y)
  gizmo.set_orthographic(not vis.is_perspective)
  gizmo.draw_grid(vis.camera_view, vis.camera_projection, identity_matrix(), cells / 2)
  ##

  ## Actual logic
  sel_col = atk.ref_selected_collider
  hov_col = atk.ref_hovered_collider
  visual_collider = atk.get_visualization_collider()
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

    is_active = c.make_keyframe_value_at("is_active", atk.timeline_at)[1]
    if not is_active:
      if c is not visual_collider:
        continue
      color_ = imgui_fade_multiply(color_, 0.25)

    color = imgui_color_to_u32(color_)

    c_pos = c.make_keyframe_value_at("tr", atk.timeline_at)[1]
    m = glm.translate(vec3(c_pos.x, 0, c_pos.y))
    center = vec3(m * vec4(0, 0, 0, 1))

    match c.type:
      case ColliderType.CIRCLE:
        if not isinstance(c, ColliderCircle):
          ass(0)

        radius = c.make_keyframe_value_at("radius", atk.timeline_at)[1]
        draw_circle(center, radius, color)

      case ColliderType.CAPSULE:
        if not isinstance(c, ColliderCapsule):
          raise ass(0)

        radius = c.make_keyframe_value_at("radius", atk.timeline_at)[1]
        spread = c.make_keyframe_value_at("spread", atk.timeline_at)[1]
        rotation = c.make_keyframe_value_at("rotation", atk.timeline_at)[1]
        draw_capsule(center, radius, spread, math.radians(rotation), color)

      case _:
        ass(0)

  if im.is_key_pressed(im.Key.t) or im.is_key_pressed(im.Key._1):
    vis.gizmo_mode = GizmoMode.TRANSLATE
  elif im.is_key_pressed(im.Key.r) or im.is_key_pressed(im.Key._2):
    vis.gizmo_mode = GizmoMode.ROTATE
  # elif im.is_key_pressed(im.Key.s) or im.is_key_pressed(im.Key._3):
  #   vis.gizmo_mode = GizmoMode.SCALE

  if c := atk.ref_selected_collider:
    delta = Matrix16()
    man_kwargs: dict = {
      "view": vis.camera_view,
      "projection": vis.camera_projection,
      "operation": {
        GizmoMode.TRANSLATE: gizmo.OPERATION.translate,
        GizmoMode.ROTATE: gizmo.OPERATION.rotate_y,
        GizmoMode.SCALE: gizmo.OPERATION.scale,
      }[vis.gizmo_mode],
      "mode": gizmo.MODE.world,
      "snap": {
        GizmoMode.TRANSLATE: SNAP_TRANSLATE,
        GizmoMode.ROTATE: SNAP_ROTATE,
        GizmoMode.SCALE: SNAP_SCALE,
      }[vis.gizmo_mode],
      "delta_matrix": delta,
    }

    frames_tr = c.get_keyframes("tr")
    tr_closest_index, poss_ = _get_closest_keyframe(frames_tr, atk.timeline_at)
    tr_pos = poss_.value
    m = _to_Matrix16(glm.translate(vec3(tr_pos.x, 0, tr_pos.y)))
    if not isinstance(c, (ColliderCircle, ColliderCapsule)):
      raise ass(0)
    with gizmo_restrict(m, (False, True, False), disable_translation_y=True):
      if gizmo.manipulate(object_matrix=m, **man_kwargs):
        off3 = _to_mat4(delta) * vec4(0, 0, 0, 1)
        ass(off3.y == 0)
        c.tr[tr_closest_index].value += bf.round_to_step(
          vec2(off3.x, off3.z), STEP_TRANSLATE
        )

    # match c.type:
    #   case ColliderType.CIRCLE:
    #     if not isinstance(c, ColliderCircle):
    #       raise ass(0)
    #     match vis.gizmo_mode:
    #       case GizmoMode.TRANSLATE:
    #         with gizmo_restrict(m, (False, True, False), disable_translation_y=True):
    #           if gizmo.manipulate(object_matrix=m, **man_kwargs):
    #             off3 = _to_mat4(delta) * vec4(0, 0, 0, 1)
    #             c.tr[tr_closest_index].value += bf.round_to_step(
    #               vec2(off3.x, off3.z), STEP_TRANSLATE
    #             )
    #       # case GizmoMode.ROTATE:
    #       #   imgui_error_top_bar("Can't use ROTATE on CIRCLE collider")
    #       # case GizmoMode.SCALE:
    #       #   with gizmo_restrict(m, (False, True, True), disable_translation_y=True):
    #       #     gizmo.manipulate(object_matrix=m, **man_kwargs)
    #
    #   case ColliderType.CAPSULE:
    #     if not isinstance(c, ColliderCapsule):
    #       raise ass(0)
    #     match vis.gizmo_mode:
    #       case GizmoMode.TRANSLATE:
    #         with gizmo_restrict(m, (False, True, False), disable_translation_y=True):
    #           if gizmo.manipulate(object_matrix=m, **man_kwargs):
    #             off3 = _to_mat4(delta) * vec4(0, 0, 0, 1)
    #             c.tr[tr_closest_index].value += bf.round_to_step(
    #               vec2(off3.x, off3.z), STEP_TRANSLATE
    #             )
    #       # case GizmoMode.ROTATE:
    #       #   with gizmo_restrict(m, (False, True, False), disable_translation_y=True):
    #       #     gizmo.manipulate(object_matrix=m, **man_kwargs)
    #       # case GizmoMode.SCALE:
    #       #   with gizmo_restrict(m, (False, True, True), disable_translation_y=True):
    #       #     if gizmo.manipulate(object_matrix=m, **man_kwargs):
    #       #       mm = _to_mat4(delta)
    #       #       off = bf.round_to_step(vec2(mm * vec4(0, 0, 0, 1)))
    #       #       c.tr[tr_closest_index].value += off

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
  ass(indices_width >= 1)
  ass(rows >= 1)

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


def _panel_timeline() -> None:  ##
  tim = g.timeline
  atk = g.ref_selected_attack
  if not atk:
    imgui_draw_cross()
    return
  ass(atk.duration_frames > 0)
  c = atk.get_visualization_collider()

  io = im.get_io()

  if tim.is_playing:
    atk.timeline_at += im.get_io().delta_time * FPS
    if atk.timeline_at > atk.duration_frames:
      atk.timeline_at -= atk.duration_frames
  else:
    atk.timeline_at = min(atk.timeline_at, atk.duration_frames)

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
    atk.timeline_at = atk.duration_frames
    atk.timeline_started_playing_at = atk.duration_frames
  im.set_item_tooltip("Key: $")

  lines_top_left: ImVec2 | None = None
  lines_bottom_right = ImVec2()

  were_dragging_keyframe_this_frame = False
  created_keyframe_this_frame = False

  hovered_frame_index = -1

  for field_name, frames in (
    ("", None),
    *(((x, c.get_keyframes(x)) for x in c.keyframe_fields) if c else ()),
  ):
    line_spanning_rows = 1
    if c and field_name:
      line_spanning_rows = c.get_keyframe_type(field_name).line_spanning_rows

    line_color = im.get_color_u32(im.Col_.frame_bg)
    if c and field_name:
      if c.selected_keyframe and (field_name == c.selected_keyframe.field):
        line_color = im.get_color_u32(im.Col_.frame_bg_hovered)
    else:
      line_color = im.get_color_u32(im.Col_.frame_bg_hovered)

    imgui_timeline_line(atk.duration_frames, line_spanning_rows, line_color)

    if not lines_top_left:
      lines_top_left = imgui_timeline_line_out.pos_top_left
    lines_bottom_right = imgui_timeline_line_out.pos_bottom_right

    if frames is None:
      if im.is_mouse_down(0) and (
        imgui_timeline_line_out.hovered or g.timeline.dragging_playhead
      ):
        atk.timeline_at = imgui_timeline_line_out.hovered_indexf
        g.timeline.dragging_playhead = True
      elif not im.is_mouse_down(0):
        g.timeline.dragging_playhead = False

    elif c:
      # Keyframe lines
      closest_index = _get_closest_keyframe(frames, atk.timeline_at)[0]
      for fr_index, fr in enumerate(frames):
        key = _keyframe_id(field_name, fr.id)
        is_selected = bool(c.selected_keyframe) and (c.selected_keyframe.key == key)
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
            c.select_keyframe(field_name, fr_index)
            tim.dragging_keyframe = key
          if (
            (not tim.dragging_keyframe)
            and (im.is_mouse_clicked(1) or im.is_key_pressed(im.Key.delete))
            and (len(c.get_keyframes(field_name)) > 1)
          ):
            c.keyframe_to_remove = (field_name, fr_index)

        if im.is_mouse_down(0) and (tim.dragging_keyframe == key):
          were_dragging_keyframe_this_frame = True
          min_left = 0
          max_right = atk.duration_frames - 1
          if fr_index > 0:
            min_left = frames[fr_index - 1].index_timeline + 1
          if fr_index < len(frames) - 1:
            max_right = frames[fr_index + 1].index_timeline - 1

          fr.index_timeline = bf.clamp(
            imgui_timeline_line_out.hovered_index_half_cell_offset, min_left, max_right
          )
          atk.timeline_at = fr.index_timeline

        if not (were_dragging_keyframe_this_frame or created_keyframe_this_frame):
          if imgui_timeline_line_out.double_clicked:
            idx = imgui_timeline_line_out.hovered_index_half_cell_offset
            if not any(x.index_timeline == idx for x in frames):
              created_keyframe_this_frame = True
              atk.scheduled_commands.append(
                AttackCommandColliderKeyframeAdd(
                  collider_id=c.id,
                  keyframe_field=field_name,
                  keyframe_index_timeline=idx,
                )
              )

        if imgui_timeline_line_out.hovered:
          hovered_frame_index = imgui_timeline_line_out.hovered_index_half_cell_offset

  if not lines_top_left:
    raise ass(0)

  for i in range(atk.duration_frames):
    posx = lines_top_left.x + i * imgui_timeline_line_out.width / atk.duration_frames
    draw.add_line(
      ImVec2(posx, lines_top_left.y),
      ImVec2(posx, lines_bottom_right.y),
      im.get_color_u32(im.Col_.text if hovered_frame_index == i else im.Col_.border),
    )

  playhead_top = lines_top_left + ImVec2(
    atk.timeline_at / atk.duration_frames * imgui_timeline_line_out.width, 0
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

  if not were_dragging_keyframe_this_frame:
    tim.dragging_keyframe = None

  recursive_validate(g)
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
  keyframes: list[Keyframe[T]], to: float = 0
) -> tuple[int, Keyframe[T]]:  ##
  return min(enumerate(keyframes), key=lambda x: abs(x[1].index_timeline - to))
  ##


def _panel_collider_inspector() -> None:  ##
  atk = g.ref_selected_attack
  if not atk:
    imgui_draw_cross()
    return
  c = atk.get_visualization_collider()
  if not c:
    imgui_draw_cross()
    return

  current_frame = min(int(atk.timeline_at + 0.5), atk.duration_frames - 1)
  ass(current_frame >= 0)

  def field_keyframe_index(field_name: str) -> int:
    return _get_closest_keyframe(getattr(c, field_name), atk.timeline_at)[0]

  # im.dummy((1, im.get_frame_height()))
  im.dummy((1, im.get_text_line_height()))
  im.dummy((1, im.get_text_line_height_with_spacing()))

  if g.timeline.is_playing:
    im.begin_disabled()

  if im.begin_table("collider_table", 3):
    im.table_setup_column("", im.TableColumnFlags_.width_fixed)
    im.table_setup_column("", im.TableColumnFlags_.width_fixed)
    im.table_setup_column("", im.TableColumnFlags_.width_stretch)

    vertical_off_field = None
    if c.selected_keyframe:
      vertical_off_field = c.selected_keyframe.field

    for field_index, f in enumerate(c.keyframe_fields):
      vertical_off = 0
      if f == vertical_off_field:
        for disabled, key, voff in (
          ((field_index <= 0), im.Key.w, -1),
          ((field_index >= len(c.keyframe_fields) - 1), im.Key.s, 1),
        ):
          if (not disabled) and im.is_key_pressed(key):
            vertical_off = voff

      frames = c.get_keyframes(f)
      keyframe_type = c.get_keyframe_type(f)

      im.table_next_row()
      im.table_set_column_index(0)

      im.text(f)

      im.table_set_column_index(1)

      index_f = field_keyframe_index(f)
      field_is_the_same_as_of_selected_keyframe = c.selected_keyframe and (
        c.selected_keyframe.field == f
      )

      if vertical_off and (c.selected_keyframe is not None):
        new_field_to_select = c.keyframe_fields[field_index + vertical_off]
        c.select_keyframe(
          new_field_to_select,
          _get_closest_keyframe(
            getattr(c, new_field_to_select), c.selected_keyframe.index_timeline
          )[0],
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
        c.select_keyframe(f, index_f - 1)
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
        and c.selected_keyframe
        and field_is_the_same_as_of_selected_keyframe
      ):
        c.select_keyframe(f, index_f + 1)
      if field_is_the_same_as_of_selected_keyframe:
        im.set_item_tooltip("Key: D")
      if index_f >= len(frames) - 1:
        bf.imgui_end_disabled()
      if not len(frames):
        bf.imgui_end_disabled()

      im.table_set_column_index(2)

      match keyframe_type:
        case KeyframeTypeBool():
          _inspector_checkbox(
            bf.imgui_id("", f"checkbox_{f}"),
            lambda: frames[index_f].value,
            lambda x: setattr(frames[index_f], "value", x),
          )

        case KeyframeTypeFloat():
          _inspector_input_float(
            bf.imgui_id("", f"slider_{f}"),
            lambda: frames[index_f].value,
            lambda x: setattr(frames[index_f], "value", x),
            keyframe_type.min,
            keyframe_type.max,
            keyframe_type.step,
            keyframe_type.step_fast,
            keyframe_type.fmt,
          )

        case KeyframeTypeTr():
          _inspector_input_float(
            bf.imgui_id("", f"slider_{f}_x"),
            lambda: frames[index_f].value.x,
            lambda x: setattr(frames[index_f].value, "x", x),
            -MAX_OFFSET,
            MAX_OFFSET,
            keyframe_type.step,
            1,
            "%.2f",
          )
          _inspector_input_float(
            bf.imgui_id("", f"slider_{f}_y"),
            lambda: frames[index_f].value.y,
            lambda x: setattr(frames[index_f].value, "y", x),
            -MAX_OFFSET,
            MAX_OFFSET,
            keyframe_type.step,
            1,
            "%.2f",
          )

        case _:
          raise ass(0)

    im.end_table()

  if g.timeline.is_playing:
    im.end_disabled()

  ##


def _post_new_frame() -> None:  ##
  io = im.get_io()

  if g.attack_to_select:
    g.ref_selected_attack = g.attack_to_select
    g.attack_to_select = None

  atk = g.ref_selected_attack
  if atk:
    if atk.collider_to_select:
      atk.ref_selected_collider = atk.collider_to_select
      atk.collider_to_select = None
    if atk.collider_deselection_scheduled:
      atk.ref_selected_collider = None
      atk.collider_deselection_scheduled = False

    atk.ref_hovered_collider = None
    if atk.collider_to_hover:
      atk.ref_hovered_collider = atk.collider_to_hover
      atk.collider_to_hover = None

    for command in atk.scheduled_commands:
      command.do(atk)
      atk.history.append(command)
    atk.scheduled_commands.clear()
    if io.key_ctrl and im.is_key_pressed(im.Key.z):
      g.attack_undo_scheduled = True
    if g.attack_undo_scheduled:
      g.attack_undo_scheduled = False
      if atk.history:
        last = atk.history.pop()
        last.undo(atk)

    if c := atk.get_visualization_collider():
      if c.keyframe_to_remove:
        field_name, index_inside_list = c.keyframe_to_remove
        keyframes = c.get_keyframes(field_name)
        ass(len(keyframes) > 1)
        ass(0 <= index_inside_list < len(keyframes))
        del keyframes[index_inside_list]
        c.keyframe_to_remove = None

      if c.keyframe_to_select:
        keyframe, update_timeline = c.keyframe_to_select
        if update_timeline:
          atk.timeline_at = keyframe.index_timeline
        c.selected_keyframe = keyframe
        c.keyframe_to_select = None

      if sel_key := c.selected_keyframe:
        c.select_keyframe(
          sel_key.field,
          _get_closest_keyframe(getattr(c, sel_key.field), atk.timeline_at)[0],
          update_timeline_playhead=False,
        )

  ##


def _test_make_default_keyframe_at():  ##
  c = ColliderCapsule.make(1)
  c.radius[0].index_timeline = 10
  for v in (5, 15, 9, 11):
    c.make_default_keyframe_at("radius", v)
    ass(c.radius == sorted(c.radius, key=lambda x: x.index_timeline))
  recursive_validate(c)
  ##


def _test_first_keyframe_yields_correct_values():  ##
  c = ColliderCapsule.make(1)
  c.tr[0].value = vec2(random.uniform(-100, 100), random.uniform(-100, 100))
  c.radius[0].value = random.uniform(0.25, 20)

  _, v = c.make_keyframe_value_at("tr", 0)
  ass(isinstance(v, vec2))
  ass(v == c.tr[0].value)

  _, r = c.make_keyframe_value_at("radius", 0)
  ass(r == c.radius[0].value)
  recursive_validate(c)
  ##
