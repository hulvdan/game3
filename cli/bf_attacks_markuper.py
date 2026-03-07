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
from dataclasses import dataclass, field
from datetime import datetime
from enum import IntEnum, unique
from functools import partial, wraps
from math import pi
from pathlib import Path
from typing import Generic, Self, TypeAlias, TypeVar

import bf_lib as bf
import toml
from bf_typer import command
from imgui_bundle import ImVec2, ImVec2_Pydantic, hello_imgui, imguizmo
from imgui_bundle import imgui as im
from pydantic import BaseModel
from pyglm import glm
from pyglm.glm import degrees, mat3, mat4, radians, vec2, vec3, vec4

##


## Setup
HUE_GREEN = 2 / 7
YELLOW = im.color_convert_float4_to_u32((1, 1, 0, 1))
YELLOW_DIMMED = im.color_convert_float4_to_u32((1, 1, 0, 0.25))
COLOR_GRID = im.color_convert_float4_to_u32((1, 1, 1, 0.15))

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
##

# @dataclass
# class Keyframe:
#   index: int
#   scale: float
#   offset: V2


@unique
class ColliderType(IntEnum):  ##
  INVALID = 0
  CIRCLE = 1
  CAPSULE = 2
  ##


@dataclass(slots=True)
class Frame(Generic[T]):  ##
  index: int
  value: T
  ##


class ColliderBase:  ##
  type: t.ClassVar[ColliderType] = ColliderType.INVALID

  def __new__(cls, *_args, **_kwargs):
    assert cls is not ColliderBase
    return super().__new__(cls)

  ##


@dataclass(slots=True)
class ColliderCircle(ColliderBase):  ##
  type: t.ClassVar[ColliderType] = ColliderType.CIRCLE

  radius: list[Frame[float]]
  center: list[Frame[Matrix16]]

  @classmethod
  def make(cls) -> Self:
    return cls(
      radius=[Frame(0, 0.5)],
      center=[Frame(0, identity_matrix())],
    )

  ##


@dataclass(slots=True)
class ColliderCapsule(ColliderBase):  ##
  type: t.ClassVar[ColliderType] = ColliderType.CAPSULE

  radius: list[Frame[float]]
  center_and_rotation: list[Frame[Matrix16]]
  circles_spread: list[Frame[float]]

  @classmethod
  def make(cls) -> Self:
    return cls(
      radius=[Frame(0, 0.5)],
      center_and_rotation=[Frame(0, identity_matrix())],
      circles_spread=[Frame(0, 1)],
    )

  ##


@dataclass(slots=True)
class Attack:  ##
  name: str
  colliders: list[ColliderBase] = field(default_factory=list)

  ref_selected_collider: ColliderBase | None = None
  ##


@dataclass(slots=True)
class Creature:  ##
  name: str
  attacks: list[Attack]
  ##


class AppSaveState(BaseModel):  ##
  font_scale_main: float = 1
  creature: str | None = None
  attack: str | None = None
  collider_index: int | None = None
  ##


@dataclass(slots=True)
class State:
  @dataclass
  class Visualizer:  ##
    first_frame: bool = True
    camera_view: Matrix16 = field(default_factory=Matrix16)
    camera_projection: Matrix16 = field(default_factory=Matrix16)
    fov: float = 27.0
    is_perspective: bool = True
    ortho__view_width: float = 10.0
    perspective__cam_angle_y: float = radians(165)
    perspective__cam_angle_x: float = radians(32)
    perspective__distance: float = 10
    perspective__view_dirty: bool = False
    ##

  visualizer: Visualizer = field(default_factory=Visualizer)

  # timeline: list[Keyframe] = field(default_factory=list)
  creatures: list[Creature] = field(default_factory=list)

  exiting: bool = False
  count: int = 0

  timeline_hovered_line: int = -1
  frame: int = 0

  ref_selected_attack_creature: Creature | None = None
  ref_selected_attack: Attack | None = None

  scheduled_dump: asyncio.Semaphore = field(default_factory=lambda: asyncio.Semaphore(0))

  def dump(self) -> AppSaveState:  ##
    return AppSaveState(
      font_scale_main=im.get_style().font_scale_main,
      creature=(
        self.ref_selected_attack_creature.name
        if self.ref_selected_attack_creature
        else None
      ),
      attack=self.ref_selected_attack.name if self.ref_selected_attack else None,
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


def input_matrix3(label: str, matrix3: Matrix3) -> tuple[bool, Matrix3]:  ##
  mat_values = matrix3.values.tolist()
  changed, new_values = im.input_float3(label, mat_values)
  if changed:
    matrix3 = Matrix3(new_values)
  return changed, matrix3
  ##


def input_only_first_value_matrix3(
  label: str, matrix3: Matrix3
) -> tuple[bool, Matrix3]:  ##
  value = float(matrix3.values[0])
  changed, new_value = im.input_float(label, value)
  if changed:
    matrix3.values[0] = new_value
  return changed, matrix3
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
  if not g.ref_selected_attack:
    return

  with bf.imgui_colorify_button(HUE_GREEN):
    if im.button("+circle"):
      g.ref_selected_attack.colliders.append(ColliderCircle.make())
    im.same_line()
    if im.button("+capsule"):
      g.ref_selected_attack.colliders.append(ColliderCapsule.make())

  for i, collider in enumerate(g.ref_selected_attack.colliders):
    flags = im.TreeNodeFlags_.leaf | im.TreeNodeFlags_.span_avail_width
    if g.ref_selected_attack.ref_selected_collider is collider:
      flags |= im.TreeNodeFlags_.selected
    if im.tree_node_ex(f"{i} {collider.type.name}", flags):
      if im.is_item_clicked():
        if g.ref_selected_attack.ref_selected_collider is collider:
          g.ref_selected_attack.ref_selected_collider = None
        else:
          g.ref_selected_attack.ref_selected_collider = collider
      im.tree_pop()
  ##


@t.overload
def _tuplify(v: vec2) -> tuple[float, float]: ...  # pyright: ignore[reportOverlappingOverload]


@t.overload
def _tuplify(v: vec3) -> tuple[float, float, float]: ...  # pyright: ignore[reportOverlappingOverload]


def _tuplify(v):
  if isinstance(v, vec2):
    return (v.x, v.y)
  else:
    return (v.x, v.y, v.z)


def _panel_visualizer() -> None:
  if g.ref_selected_attack is None:
    assert g.ref_selected_attack_creature is None
    return

  ## Setup
  cells = 10
  draw = im.get_foreground_draw_list()
  size_ = im.get_content_region_avail()
  pos_ = im.get_cursor_screen_pos()
  viewport = vec4(pos_.x, pos_.y, size_.x, size_.y)
  size = _to_vec2(size_)
  pos = _to_vec2(pos_)
  vis = g.visualizer
  ##

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

  vp: mat4 = projection * view  # type:ignore

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

  ## Draw functions
  def draw_line(p1: vec3, p2: vec3, color: int = YELLOW):
    draw.add_line(_tuplify(world_to_screen(p1)), _tuplify(world_to_screen(p2)), color)

  def draw_polyline(
    points: list[vec3], color: int = YELLOW, flags: im.ImDrawFlags_ = im.ImDrawFlags_.none
  ):
    draw.add_polyline([_tuplify(world_to_screen(x)) for x in points], color, flags, 1)

  _draw_circle_points: list[vec3] = []

  def draw_circle(
    p: vec3,
    radius: float,
    color: int = YELLOW,
    segments: int = 24,
    normal: vec3 = vec3_up,
  ) -> None:
    m = glm.rotate(2.0 * pi / segments, normal)
    cur = glm.cross(normal, vec3_forward)
    for _ in range(segments):
      _draw_circle_points.append(p + vec3(cur))
      cur = m * cur
    draw_polyline(_draw_circle_points, color, flags=im.ImDrawFlags_.closed)
    _draw_circle_points.clear()

  def draw_capsule(
    p1: vec3,
    p2: vec3,
    radius: float,
    color: int = YELLOW,
    circle_segments: int = 24,
    normal: vec3 = vec3_up,
  ) -> None:
    # m = glm.rotate(2.0 * pi / segments, normal)
    # cur = glm.cross(normal, vec3_forward)
    # for _ in range(segments):
    #   _draw_circle_points.append(p + vec3(cur))
    #   cur = m * cur
    # draw_polyline(_draw_circle_points, color, flags=im.ImDrawFlags_.closed)
    # _draw_circle_points.clear()
    draw_circle(p1, radius, color, segments=circle_segments, normal=normal)
    draw_circle(p2, radius, color, segments=circle_segments, normal=normal)

  gizmo.begin_frame()
  gizmo.set_drawlist()
  gizmo.set_rect(pos_.x, pos_.y, size_.x, size_.y)
  gizmo.set_orthographic(not vis.is_perspective)
  gizmo.draw_grid(vis.camera_view, vis.camera_projection, identity_matrix(), cells / 2)
  ##

  ##
  sel_col = g.ref_selected_attack.ref_selected_collider
  for c in g.ref_selected_attack.colliders:
    color = YELLOW
    if (sel_col is not None) and (sel_col is not c):
      color = YELLOW_DIMMED

    match c.type:
      case ColliderType.CIRCLE:
        assert isinstance(c, ColliderCircle)
        m = _to_mat4(c.center[0].value)
        center = vec3(m * vec4(0, 0, 0, 1))
        r = (m * vec4(0.5, 0, 0, 0)).x
        draw_circle(center, r, color)

      case ColliderType.CAPSULE:
        assert isinstance(c, ColliderCapsule)
        m = _to_mat4(c.center_and_rotation[0].value)
        center = vec3(m * vec4(0, 0, 0, 1))
        dirr = vec3(m * vec4(c.circles_spread[0].value / 2, 0, 0, 0))
        r = (m * vec4(0.5, 0, 0, 0)).x
        draw_capsule(center + dirr, center - dirr, r, color)

      case _:
        assert 0

  if c := g.ref_selected_attack.ref_selected_collider:
    match c.type:
      case ColliderType.CIRCLE:
        assert isinstance(c, ColliderCircle)
        center = c.center[0].value
        with _gizmo_axis_mask_no_y():
          gizmo.manipulate(
            vis.camera_view,
            vis.camera_projection,
            gizmo.OPERATION.translate,
            gizmo.MODE.local,
            center,
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


def _panel_timeline() -> None:  ##
  hovered_line = -1
  for field_index, field in enumerate(("scale", "offset", "rotation")):
    color = (1, 1, 0, 1) if (field_index == g.timeline_hovered_line) else (1, 1, 1, 1)
    im.text_colored(color, field)
    if im.is_item_hovered():
      hovered_line = field_index

  g.timeline_hovered_line = hovered_line
  ##


def _to_vec2(v: ImVec2_Pydantic) -> vec2:
  return vec2(v.x, v.y)


def _to_Matrix16(m: mat4) -> Matrix16:
  return Matrix16(m[0].to_list() + m[1].to_list() + m[2].to_list() + m[3].to_list())


def _to_mat4(m: Matrix16) -> mat4:
  return mat4(*m.values.reshape((4, 4)).flatten())


## Setup
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
  # gizmo.set_axis_mask(False, False, True)

  g.creatures = [
    Creature(
      name="MOB_SPEAR",
      attacks=[
        Attack(name="DASH"),
        Attack(name="SWING"),
      ],
    ),
    Creature(
      name="BOSS_JAGRAS",
      attacks=[
        Attack(name="ROLL_FRONT"),
        Attack(name="ROLL_SIDE"),
        Attack(name="JUMP_BACK"),
      ],
    ),
  ]

  loaded_state: AppSaveState | None = None
  if _APP_STATE_FILE_PATH.exists():
    with open(_APP_STATE_FILE_PATH, encoding="utf-8") as in_file:
      state_data = toml.load(in_file)
    loaded_state = AppSaveState(**state_data)
    g.load(loaded_state)

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
        bf.ImGuiPanel("Timeline", enable_debug(_panel_timeline)),
        bf.ImGuiPanel("Attack Inspector", enable_debug(_panel_attack_inspector)),
        bf.ImGuiPanel("Logs", hello_imgui.log_gui),
      ],
      setup_imgui_style=setup_imgui_style,
      before_exit=_dump_app_state,
    )
    _dump_task.cancel()

  asyncio.run(wrapper(), debug=True)


@contextmanager
def _gizmo_axis_mask_no_y():
  gizmo.set_axis_mask(False, True, False)
  yield
  gizmo.set_axis_mask(True, True, True)


##
