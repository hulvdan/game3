## Imports
import asyncio
import math
import shutil
import sys
import tempfile
import threading
import traceback
import typing as t
from contextlib import contextmanager
from dataclasses import dataclass, field, fields, is_dataclass
from datetime import datetime
from enum import IntEnum, unique
from functools import partial, wraps
from math import pi
from pathlib import Path
from typing import Callable, Generic, Self, TypeAlias, TypeVar

import bf_lib as bf
import toml
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
MIN_RADIUS: float = 0.125
MAX_RADIUS: float = 5.0
MAX_OFFSET: float = 10.0
##


## Setup
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
  draw.add_line(pos, pos + size, COLOR_GRAY_U32, 2)
  draw.add_line(pos + ImVec2(0, size.y), pos + ImVec2(size.x, 0), COLOR_GRAY_U32, 2)


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
#   ('RED',        0 / 7, 1, 1),
#   ('YELLOW',     1 / 7, 1, 1),
#   ('GREEN',      2 / 7, 1, 1),
#   ('CYAN',       3 / 7, 1, 1),
#   ('LIGHT_BLUE', 4 / 7, 1, 1),
#   ('BLUE',       5 / 7, 1, 1),
#   ('PURPLE',     6 / 7, 1, 1),
#   ('WHITE',      0,     0, 1),
#   ('GRAY',       0,     0, 0.5),
#   ('BLACK',      0,     0, 0),
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
  g.creatures = [
    Creature(
      name="MOB_SPEAR",
      attacks=[
        Attack(name="DASH", duration_frames=10),
        Attack(name="SWING"),
      ],
    ),
    Creature(
      name="BOSS_JAGRAS",
      attacks=[
        Attack(
          name="ROLL_FRONT",
          duration_frames=24,
          colliders=[
            ColliderCapsule.make(),
          ],
        ),
        Attack(name="ROLL_SIDE", duration_frames=10),
        Attack(name="JUMP_BACK"),
      ],
    ),
  ]
  c = ColliderCapsule.make()
  c.radius.append(Keyframe(4, 5, c._next_keyframe_id()))
  c.radius.append(Keyframe(7, 4, c._next_keyframe_id()))
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
      atk.ref_selected_collider = atk.colliders[0]

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
        bf.ImGuiPanel("Keyframe", enable_debug(_panel_keyframe_inspector)),
        bf.ImGuiPanel("Logs", hello_imgui.log_gui),
      ],
      setup_imgui_style=setup_imgui_style,
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
  bf.imgui_assert(not _gizmo_restricted)

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
  return Matrix16(m[0].to_list() + m[1].to_list() + m[2].to_list() + m[3].to_list())


def _to_mat4(m: Matrix16) -> mat4:
  return mat4(*m.values.reshape((4, 4)).flatten())


##


@dataclass(slots=True)
class Keyframe(Generic[T]):  ##
  timeline_index: int
  value: T
  id: int = 0

  def validate(self):
    bf.imgui_assert(self.id > 0)
    bf.imgui_assert(self.timeline_index >= 0)

  ##


@dataclass(slots=True, frozen=True)
class SelectedKeyframe:  ##
  id: int
  key: str  # e.g. "keyframe_radius_0"
  field: str  # e.g. "radius" / "spread"
  timeline_cell_index: int
  index_inside_list: int

  def validate(self):
    bf.imgui_assert(self.id > 0)
    bf.imgui_assert(self.timeline_cell_index >= 0)

  ##


@unique
class ColliderType(IntEnum):  ##
  INVALID = 0
  CIRCLE = 1
  CAPSULE = 2
  ##


@t.runtime_checkable
class KeyframeType(t.Protocol[T]):  ##
  def make_default(self) -> T: ...

  def make_copy(self, v: T) -> T: ...

  def make_lerp(self, v1: T, v2: T, t: float) -> T: ...

  ##


class KeyframeTypeFloat(KeyframeType[float]):  ##
  def __init__(self, default: float):
    self._default = default

  def make_default(self) -> float:
    return self._default

  def make_copy(self, v: float) -> float:
    return v

  def make_lerp(self, v1: float, v2: float, t: float) -> float:
    return bf.lerp(v1, v2, t)

  ##


class KeyframeTypeTr(KeyframeType[Matrix16]):  ##
  def __init__(self, default: Matrix16 | None = None):
    self._default = default if default else identity_matrix()

  def make_default(self) -> Matrix16:
    result = Matrix16()
    result.values[:] = self._default.values[:]
    return result

  def make_copy(self, v: Matrix16) -> Matrix16:
    result = Matrix16()
    result.values[:] = v.values[:]
    return result

  def make_lerp(self, v1: Matrix16, v2: Matrix16, t: float) -> Matrix16:
    c1 = gizmo.decompose_matrix_to_components(v1)
    c2 = gizmo.decompose_matrix_to_components(v2)
    c = gizmo.MatrixComponents()
    c.translation[:].values = c1.translation.values * t + c2.translation.values * (1 - t)
    c.rotation[:].values = c1.rotation.values
    c.scale[:].values = c1.scale.values
    return gizmo.recompose_matrix_from_components(c)

  ##


class ColliderBaseMeta(type):  ##
  def __init__(cls, name, bases, namespace):
    super().__init__(name, bases, namespace)
    is_base = name == "ColliderBase"
    bf.imgui_assert(is_base or (ColliderBase in bases))
    if is_base:
      return

    cls.list_frame_fields = []
    for field_name, field_type in cls.__annotations__.items():
      origin = t.get_origin(field_type)
      args = t.get_args(field_type)

      if (origin in (list, t.List)) and args:  # noqa: UP006
        if t.get_origin(args[0]) is Keyframe:
          cls.list_frame_fields.append(field_name)

    cls._keyframe_values = {}
    prefix = "_keyframe_"
    for field_name, field_value in namespace.items():
      if field_name == "_keyframe_values":
        continue
      if field_name.startswith(prefix):
        bf.imgui_assert(isinstance(field_value, KeyframeType))
        cls._keyframe_values[field_name.removeprefix(prefix)] = field_value

  ##


class ColliderBase(metaclass=ColliderBaseMeta):  ##
  type: t.ClassVar[ColliderType] = ColliderType.INVALID
  list_frame_fields: t.ClassVar[list[str]]
  _keyframe_values: t.ClassVar[dict[str, KeyframeType]]

  selected_keyframe: SelectedKeyframe | None = None
  __next_keyframe_id: int = 1

  def __new__(cls, *_args, **_kwargs):
    bf.imgui_assert(cls is not ColliderBase)
    return super().__new__(cls)

  def _next_keyframe_id(self) -> int:
    result = self.__next_keyframe_id
    self.__next_keyframe_id += 1
    return result

  def make_default_keyframe_at(self, field: str, timeline_index: int) -> None:
    bf.imgui_assert(field in self.list_frame_fields)
    bf.imgui_assert(field in self._keyframe_values)

    frames = t.cast("list[Keyframe]", getattr(self, field))
    factory = self._keyframe_values[field]

    value: t.Any
    insert_index = 0
    if not frames:
      value = factory.make_default()
    else:
      left_list_index = 0
      right_list_index = 0
      for i, fr in enumerate(frames):
        fr = t.cast("Keyframe", fr)
        if fr.timeline_index < timeline_index:
          left_list_index = i
        if fr.timeline_index > timeline_index:
          right_list_index = i
          break
      left = frames[left_list_index]
      insert_index = left_list_index + 1
      if right_list_index:
        bf.imgui_assert(right_list_index > left_list_index)
        right = frames[right_list_index]
        value = factory.make_lerp(
          left.value,
          right.value,
          (timeline_index - left.timeline_index)
          / (right.timeline_index - left.timeline_index),
        )
      else:
        value = factory.make_copy(left.value)
    frames.insert(insert_index, Keyframe(timeline_index, value, self._next_keyframe_id()))

  def validate(self):
    for f in self.list_frame_fields:
      frames = t.cast("list[Keyframe]", getattr(self, f))
      for i in range(len(frames) - 1):
        bf.imgui_assert(
          frames[i].timeline_index < frames[i + 1].timeline_index,
          ("Keyframes must be sorted by `index`"),
        )

  @classmethod
  def make(cls) -> Self:
    bf.imgui_assert(cls is not ColliderBase)
    result = cls(*[[] for _ in range(len(cls.list_frame_fields))])
    for f in cls.list_frame_fields:
      result.make_default_keyframe_at(f, 0)
    return result

  ##


@dataclass(slots=True)
class ColliderCircle(ColliderBase):  ##
  type: t.ClassVar[ColliderType] = ColliderType.CIRCLE

  radius: list[Keyframe[float]]
  tr: list[Keyframe[Matrix16]]

  _keyframe_radius: t.ClassVar[KeyframeType] = KeyframeTypeFloat(0.5)
  _keyframe_tr: t.ClassVar[KeyframeType] = KeyframeTypeTr()

  ##


@dataclass(slots=True)
class ColliderCapsule(ColliderBase):  ##
  MAX_SPREAD: t.ClassVar[float] = 10.0
  type: t.ClassVar[ColliderType] = ColliderType.CAPSULE

  tr: list[Keyframe[Matrix16]]
  radius: list[Keyframe[float]]
  spread: list[Keyframe[float]]

  _keyframe_radius: t.ClassVar[KeyframeType] = KeyframeTypeFloat(0.5)
  _keyframe_spread: t.ClassVar[KeyframeType] = KeyframeTypeFloat(1)
  _keyframe_tr: t.ClassVar[KeyframeType] = KeyframeTypeTr()
  ##


@dataclass(slots=True)
class Attack:  ##
  name: str

  duration_frames: int = 1
  colliders: list[ColliderBase] = field(default_factory=list)

  ref_selected_collider: ColliderBase | None = None
  ref_hovered_collider: ColliderBase | None = None

  timeline_at: float = 0
  timeline_started_playing_at: float = 0

  def validate(self):
    bf.imgui_assert(self.name)
    bf.imgui_assert(self.duration_frames > 0)
    bf.imgui_assert(self.timeline_at >= 0)
    bf.imgui_assert(self.timeline_at <= self.duration_frames)
    bf.imgui_assert(self.timeline_started_playing_at >= 0)
    bf.imgui_assert(self.timeline_started_playing_at <= self.duration_frames)

    for c in self.colliders:
      for f in c.list_frame_fields:
        frames = t.cast("list[Keyframe]", getattr(c, f))
        for fr in frames:
          bf.imgui_assert(fr.timeline_index >= 0)
          bf.imgui_assert(fr.timeline_index < self.duration_frames)

  ##


@dataclass(slots=True)
class Creature:  ##
  name: str
  attacks: list[Attack]

  def validate(self):
    bf.imgui_assert(self.name)
    bf.imgui_assert(bf.are_unique(x.name for x in self.attacks))

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

  ref_selected_attack_creature: Creature | None = None
  ref_selected_attack: Attack | None = None

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
    for f in c.list_frame_fields:
      for frame in getattr(c, f):
        frame = t.cast("Keyframe[t.Any]", frame)
        min_attack_frames = max(min_attack_frames, frame.timeline_index + 1)
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

  with bf.imgui_colorify_inputs(HUE_GREEN):
    if im.button("+circle"):
      atk.colliders.append(ColliderCircle.make())
      atk.ref_selected_collider = atk.colliders[-1]
    im.same_line()
    if im.button("+capsule"):
      atk.colliders.append(ColliderCapsule.make())
      atk.ref_selected_collider = atk.colliders[-1]

  atk.ref_hovered_collider = None
  i = -1
  for collider in atk.colliders:
    i += 1
    flags = im.TreeNodeFlags_.leaf | im.TreeNodeFlags_.span_avail_width
    if atk.ref_selected_collider is collider:
      flags |= im.TreeNodeFlags_.selected
    if im.tree_node_ex(f"{i} {collider.type.name}", flags):
      if im.is_item_hovered():
        atk.ref_hovered_collider = collider
      if im.is_item_clicked():
        if atk.ref_selected_collider is collider:
          atk.ref_selected_collider = None
        else:
          atk.ref_selected_collider = collider
      im.tree_pop()
  ##


def _panel_visualizer() -> None:
  atk = g.ref_selected_attack
  if atk is None:
    bf.imgui_assert(g.ref_selected_attack_creature is None)
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
    bf.imgui_assert(segments >= 8)
    bf.imgui_assert(radius > 0)
    bf.imgui_assert(isinstance(p, vec3))
    bf.imgui_assert(glm.dot(plane[1], plane[0]) < 0.00001)
    normal = glm.cross(plane[0], plane[1])
    bf.imgui_assert(abs(glm.length(normal) - 1) < 0.00001)
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
    bf.imgui_assert(segments >= 8)
    bf.imgui_assert(spread >= 0)
    bf.imgui_assert(radius > 0)
    bf.imgui_assert(isinstance(p, vec3))
    bf.imgui_assert(segments % 2 == 0)
    bf.imgui_assert(glm.dot(plane[0], plane[1]) < 0.00001)
    normal = glm.cross(plane[1], plane[0])
    bf.imgui_assert(abs(glm.length(normal) - 1) < 0.00001)
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
    color = imgui_color_to_u32(color_)

    match c.type:
      case ColliderType.CIRCLE:
        if not isinstance(c, ColliderCircle):
          raise bf.imgui_assert(0)
        m = _to_mat4(c.tr[0].value)
        center = vec3(m * vec4(0, 0, 0, 1))
        scale = glm.length(m * vec4(1, 0, 0, 0))

        l = c.radius[0]
        r = c.radius[-1]
        for i in range(len(c.radius)):
          v = c.radius[i]
          if v.timeline_index <= atk.timeline_at:
            l = v
          if v.timeline_index >= atk.timeline_at:
            r = v
            break
        t = 0
        bf.imgui_assert(r.timeline_index >= l.timeline_index)
        if r.timeline_index != l.timeline_index:
          t = (atk.timeline_at - l.timeline_index) / (r.timeline_index - l.timeline_index)
        radius = bf.lerp(l.value, r.value, t)

        draw_circle(center, radius * scale, color)

      case ColliderType.CAPSULE:
        if not isinstance(c, ColliderCapsule):
          raise bf.imgui_assert(0)
        m = _to_mat4(c.tr[0].value)
        center = vec3(m * vec4(0, 0, 0, 1))
        r_vec = vec3(m * vec4(0.5, 0, 0, 0))
        angle = -math.atan2(r_vec.z, r_vec.x)

        r = glm.length(r_vec)

        l = c.radius[0]
        r = c.radius[-1]
        for i in range(len(c.radius)):
          v = c.radius[i]
          if v.timeline_index <= atk.timeline_at:
            l = v
          if v.timeline_index >= atk.timeline_at:
            r = v
            break
        t = 0
        bf.imgui_assert(r.timeline_index >= l.timeline_index)
        if r.timeline_index != l.timeline_index:
          t = (atk.timeline_at - l.timeline_index) / (r.timeline_index - l.timeline_index)
        radius = bf.lerp(l.value, r.value, t)

        draw_capsule(center, radius, c.spread[0].value, angle, color)

      case _:
        bf.imgui_assert(0)

  if im.is_key_pressed(im.Key.t) or im.is_key_pressed(im.Key._1):
    vis.gizmo_mode = GizmoMode.TRANSLATE
  elif im.is_key_pressed(im.Key.r) or im.is_key_pressed(im.Key._2):
    vis.gizmo_mode = GizmoMode.ROTATE
  # elif im.is_key_pressed(im.Key.s) or im.is_key_pressed(im.Key._3):
  #   vis.gizmo_mode = GizmoMode.SCALE

  if c := atk.ref_selected_collider:
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
    }
    match c.type:
      case ColliderType.CIRCLE:
        if not isinstance(c, ColliderCircle):
          raise bf.imgui_assert(0)
        center = c.tr[0].value
        match vis.gizmo_mode:
          case GizmoMode.TRANSLATE:
            with gizmo_restrict(center, (False, True, False), disable_translation_y=True):
              gizmo.manipulate(object_matrix=center, **man_kwargs)
          case GizmoMode.ROTATE:
            imgui_error_top_bar("Can't use ROTATE on CIRCLE collider")
          case GizmoMode.SCALE:
            with gizmo_restrict(center, (False, True, True), disable_translation_y=True):
              gizmo.manipulate(object_matrix=center, **man_kwargs)

      case ColliderType.CAPSULE:
        if not isinstance(c, ColliderCapsule):
          raise bf.imgui_assert(0)
        center = c.tr[0].value
        match vis.gizmo_mode:
          case GizmoMode.TRANSLATE:
            with gizmo_restrict(center, (False, True, False), disable_translation_y=True):
              gizmo.manipulate(object_matrix=center, **man_kwargs)
          case GizmoMode.ROTATE:
            with gizmo_restrict(center, (False, True, False), disable_translation_y=True):
              gizmo.manipulate(object_matrix=center, **man_kwargs)
          case GizmoMode.SCALE:
            with gizmo_restrict(center, (False, True, True), disable_translation_y=True):
              gizmo.manipulate(object_matrix=center, **man_kwargs)

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
class ImguiTimelineLineOut:
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


imgui_timeline_line_out = ImguiTimelineLineOut(ImVec2(), ImVec2())


def imgui_timeline_line(indices_width: int) -> None:  ##
  out = imgui_timeline_line_out
  out.pos_top_left = im.get_cursor_screen_pos()
  out.width = im.get_content_region_avail().x
  out.width_per_index = out.width / indices_width
  out.height = im.get_frame_height()
  out.pos_bottom_right = out.pos_top_left + ImVec2(out.width, out.height)

  draw = im.get_window_draw_list()
  draw.add_rect_filled(
    out.pos_top_left,
    out.pos_bottom_right,
    imgui_color_to_u32(imgui_fade_replace(COLOR_WHITE, 0.1)),
  )

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

  out.hovered_t = bf.clamp((mouse.x - out.pos_top_left.x) / out.width, 0, 1)
  out.hovered_index = min(indices_width - 1, int(out.hovered_t * indices_width))
  out.hovered_indexf = out.hovered_t * indices_width
  out.hovered_index_half_cell_offset = bf.clamp(
    int((im.get_mouse_pos().x - out.pos_top_left.x) / out.width * indices_width + 0.5),
    0,
    indices_width - 1,
  )
  ##


def _panel_timeline() -> None:  ##
  tim = g.timeline
  atk = g.ref_selected_attack
  if not atk:
    imgui_draw_cross()
    return
  bf.imgui_assert(atk.duration_frames > 0)
  c = atk.ref_selected_collider
  if atk.ref_hovered_collider:
    c = atk.ref_hovered_collider
  if not c:
    imgui_draw_cross()
    return

  if tim.is_playing:
    atk.timeline_at += im.get_io().delta_time * FPS
    if atk.timeline_at > atk.duration_frames:
      atk.timeline_at -= atk.duration_frames
  elif atk.timeline_at > atk.duration_frames:
    atk.timeline_at = atk.duration_frames

  draw = im.get_window_draw_list()

  keyframe_colors = (
    im.get_color_u32(im.Col_.button),
    im.get_color_u32(im.Col_.button_hovered),
    im.get_color_u32(im.Col_.button_active),
  )

  def imgui_keyframe(key: str, pos: ImVec2, selected: bool = False) -> bool:
    remembered_pos = im.get_cursor_screen_pos()

    scale = im.get_window_dpi_scale() * im.get_frame_height() / 24

    half = _keyframe_off * scale
    im.set_cursor_screen_pos(pos - half)
    im.invisible_button(key, half * 2)

    color_index = 0
    if im.is_item_hovered():
      color_index = 1
    if selected:
      color_index = 2

    draw.add_quad_filled(
      *(pos + x * scale for x in _keyframe_quad_points),
      col=keyframe_colors[color_index],
    )

    im.set_cursor_screen_pos(remembered_pos)
    return im.is_item_clicked()

  if im.begin_table("table", 2, im.TableFlags_.sizing_stretch_same):
    im.table_setup_column("label", im.TableColumnFlags_.width_fixed)
    im.table_setup_column("value", im.TableColumnFlags_.width_stretch)

    lines_top_left: ImVec2 | None = None
    lines_bottom_right = ImVec2()

    were_dragging_keyframe_this_frame = False
    created_keyframe_this_frame = False

    for field, keyframes in (
      ("", None),
      *((x, getattr(c, x)) for x in c.list_frame_fields),
    ):
      keyframes = t.cast("list[Keyframe]", keyframes)
      im.table_next_row()

      im.table_set_column_index(0)

      if field:
        im.text(field)
      else:
        io = im.get_io()
        if (
          im.button("<<")
          or im.is_key_pressed(im.Key._0)
          or (im.is_key_pressed(im.Key._6) and io.key_shift)
        ):
          atk.timeline_at = 0
          atk.timeline_started_playing_at = 0
        im.set_item_tooltip("Key: 0 / ^")

        with bf.imgui_colorify_inputs(HUE_RED if tim.is_playing else HUE_GREEN):
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

      im.table_set_column_index(1)

      imgui_timeline_line(atk.duration_frames)

      if not lines_top_left:
        lines_top_left = imgui_timeline_line_out.pos_top_left
      lines_bottom_right = imgui_timeline_line_out.pos_bottom_right

      if keyframes is None:
        if im.is_mouse_down(0) and (
          imgui_timeline_line_out.hovered or g.timeline.dragging_playhead
        ):
          atk.timeline_at = imgui_timeline_line_out.hovered_indexf
          g.timeline.dragging_playhead = True
        elif not im.is_mouse_down(0):
          g.timeline.dragging_playhead = False

      else:
        # Keyframe lines
        fr_index = -1
        for fr in keyframes:
          fr_index += 1
          key = _keyframe_id(field, fr.id)
          is_selected = bool(c.selected_keyframe) and (c.selected_keyframe.key == key)
          imgui_keyframe(
            key,
            imgui_timeline_line_out.pos_top_left
            + ImVec2(
              fr.timeline_index * imgui_timeline_line_out.width_per_index,
              imgui_timeline_line_out.height / 2,
            ),
            selected=is_selected,
          )
          if im.is_item_hovered() and im.is_mouse_clicked(0):
            _select_keyframe(field, fr_index)
            tim.dragging_keyframe = key

          if im.is_mouse_down(0) and (tim.dragging_keyframe == key):
            were_dragging_keyframe_this_frame = True
            min_left = 0
            max_right = atk.duration_frames - 1
            if fr_index > 0:
              min_left = keyframes[fr_index - 1].timeline_index + 1
            if fr_index < len(keyframes) - 1:
              max_right = keyframes[fr_index + 1].timeline_index - 1

            fr.timeline_index = bf.clamp(
              imgui_timeline_line_out.hovered_index_half_cell_offset, min_left, max_right
            )
            atk.timeline_at = fr.timeline_index

          if not (were_dragging_keyframe_this_frame or created_keyframe_this_frame):
            if imgui_timeline_line_out.double_clicked:
              create_index = imgui_timeline_line_out.hovered_index_half_cell_offset
              can_create_keyframe = True
              for frrr in keyframes:
                if frrr.timeline_index == create_index:
                  can_create_keyframe = False
                  break

              if can_create_keyframe:
                created_keyframe_this_frame = True
                c.make_default_keyframe_at(field, create_index)

    if not lines_top_left:
      raise bf.imgui_assert(0)
    for i in range(atk.duration_frames):
      posx = lines_top_left.x + i * imgui_timeline_line_out.width / atk.duration_frames
      draw.add_line(
        ImVec2(posx, lines_top_left.y),
        ImVec2(posx, lines_bottom_right.y),
        COLOR_GRAY_FADED_U32,
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
      COLOR_RED_U32,
    )
    draw.add_line(
      playhead_top, playhead_bottom, COLOR_RED_U32, 2 * im.get_window_dpi_scale()
    )

    if not were_dragging_keyframe_this_frame:
      tim.dragging_keyframe = None

    im.end_table()

    recursive_validate(g)

  ##


def _inspector_components(m: Matrix16) -> Matrix16:  ##
  comps = gizmo.decompose_matrix_to_components(m)

  def tr_setter(index, value):
    nonlocal m
    comps.translation.values[index] = value
    m = gizmo.recompose_matrix_from_components(comps)

  def rot_setter(index, value):
    nonlocal m
    comps.rotation.values[index] = value
    m = gizmo.recompose_matrix_from_components(comps)

  _inspector_value(
    "TrX",
    lambda: comps.translation.values[0],
    partial(tr_setter, 0),
    -MAX_OFFSET,
    MAX_OFFSET,
    STEP_TRANSLATE,
  )
  _inspector_value(
    "TrZ",
    lambda: comps.translation.values[2],
    partial(tr_setter, 2),
    -MAX_OFFSET,
    MAX_OFFSET,
    STEP_TRANSLATE,
  )

  # if rotation:
  #   _inspector_value(
  #     "RotY",
  #     lambda: comps.rotation.values[1],
  #     partial(rot_setter, 1),
  #     -180,
  #     180,
  #     STEP_ROTATE,
  #   )

  return m
  ##


def _inspector_value(
  label: str,
  getter: Callable[[], float],
  setter: Callable[[float], None],
  vmin: float,
  vmax: float,
  step: float,
) -> None:  ##
  changed, spread = im.slider_float(label, getter(), vmin, vmax)
  if changed:
    setter(bf.clamp(round(spread / step) * step, vmin, vmax))
  ##


def _select_keyframe(field_name: str, index_inside_list: int) -> None:  ##
  bf.imgui_assert(g.ref_selected_attack)
  atk = t.cast("Attack", g.ref_selected_attack)
  c = atk.ref_selected_collider
  if not c:
    bf.imgui_assert(0)
  c = t.cast("ColliderBase", c)

  frames = t.cast("list[Keyframe]", getattr(c, field_name))
  fr = frames[index_inside_list]

  c.selected_keyframe = SelectedKeyframe(
    id=fr.id,
    key=_keyframe_id("radius", fr.id),
    field="radius",
    timeline_cell_index=fr.timeline_index,
    index_inside_list=index_inside_list,
  )
  atk.timeline_at = fr.timeline_index
  ##


def _panel_collider_inspector() -> None:  ##
  atk = g.ref_selected_attack
  if not atk:
    imgui_draw_cross()
    return
  c = atk.ref_hovered_collider
  if not c:
    c = atk.ref_selected_collider
  if not c:
    imgui_draw_cross()
    return

  current_frame = min(int(atk.timeline_at), atk.duration_frames - 1)
  bf.imgui_assert(current_frame >= 0)

  def field_keyframe_index(field_name: str) -> int:
    keyframe = c.selected_keyframe
    if not keyframe or (keyframe.field != field_name):
      return 0
    return keyframe.index_inside_list

  match c.type:
    case ColliderType.CIRCLE:
      if not isinstance(c, ColliderCircle):
        raise bf.imgui_assert(0)

      index_radius = field_keyframe_index("radius")
      if len(c.radius) > 1:
        im.begin_disabled()
        im.begin_disabled()
        if im.button("<"):
          pass
        im.same_line()
        im.button(">")
        im.end_disabled()
        im.end_disabled()
        im.same_line()

      with bf.imgui_colorify_inputs(HUE_GREEN):
        _inspector_value(
          "radius",
          lambda: c.radius[index_radius].value,
          lambda x: setattr(c.radius[index_radius], "value", x),
          MIN_RADIUS,
          MAX_RADIUS,
          STEP_TRANSLATE,
        )

      c.tr[0].value = _inspector_components(c.tr[0].value)

    case ColliderType.CAPSULE:
      if not isinstance(c, ColliderCapsule):
        raise bf.imgui_assert(0)

      index_radius = field_keyframe_index("radius")
      if not len(c.radius):
        im.begin_disabled()
      if index_radius == 0:
        im.begin_disabled()
      if im.button("<"):
        _select_keyframe("radius", index_radius - 1)
      if index_radius == 0:
        im.end_disabled()
      im.same_line()
      if index_radius >= len(c.radius) - 1:
        im.begin_disabled()
      if im.button(">"):
        _select_keyframe("radius", index_radius + 1)
      if index_radius == len(c.radius) - 1:
        im.end_disabled()
      if not len(c.radius):
        im.end_disabled()
      im.same_line()

      with bf.imgui_colorify_inputs(HUE_GREEN):
        _inspector_value(
          "radius",
          lambda: c.radius[index_radius].value,
          lambda x: setattr(c.radius[index_radius], "value", x),
          MIN_RADIUS,
          MAX_RADIUS,
          STEP_TRANSLATE,
        )

        index_spread = field_keyframe_index("spread")
        _inspector_value(
          "spread",
          lambda: c.spread[index_spread].value,
          lambda x: setattr(c.spread[index_spread], "value", x),
          0,
          c.MAX_SPREAD,
          STEP_TRANSLATE,
        )

      c.tr[0].value = _inspector_components(c.tr[0].value)

    case _:
      bf.imgui_assert(0)
  ##


def _panel_keyframe_inspector() -> None:  ##
  pass
  ##
