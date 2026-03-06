## Imports
import asyncio
import shutil
import sys
import tempfile
import threading
import traceback
import typing as t
from dataclasses import dataclass, field
from datetime import datetime
from enum import IntEnum, unique
from functools import partial, wraps
from pathlib import Path
from typing import Generic, Self, TypeVar

import bf_lib as bf
import toml
from bf_typer import command
from imgui_bundle import ImVec2, ImVec2_Pydantic, hello_imgui
from imgui_bundle import imgui as im
from pydantic import BaseModel
from pyglm import glm
from pyglm.glm import make_mat3, make_mat4, mat3, mat4, vec2, vec3, vec4

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
  center: list[Frame[ImVec2_Pydantic]]

  @classmethod
  def make(cls) -> Self:
    return cls(
      radius=[Frame(0, 0.5)],
      center=[Frame(0, ImVec2(0.0, 0.0))],
    )

  ##


@dataclass(slots=True)
class ColliderCapsule(ColliderBase):  ##
  type: t.ClassVar[ColliderType] = ColliderType.CAPSULE

  radius: list[Frame[float]] = field(default_factory=list)
  center: list[Frame[ImVec2_Pydantic]] = field(default_factory=list)
  rot: list[Frame[float]] = field(default_factory=list)
  circles_spread: list[Frame[float]] = field(default_factory=list)

  @classmethod
  def make(cls) -> Self:
    return cls(
      radius=[Frame(0, 0.5)],
      center=[Frame(0, ImVec2(0.0, 0.0))],
      rot=[Frame(0, 0)],
      circles_spread=[Frame(0, 0.5)],
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


def _panel_visualizer() -> None:  ##
  if g.ref_selected_attack is None:
    assert g.ref_selected_attack_creature is None
    return

  draw = im.get_foreground_draw_list()
  size_ = im.get_content_region_avail()
  pos_ = im.get_cursor_screen_pos()
  draw.push_clip_rect(pos_, pos_ + size_)

  def draw_line(p1: vec2, p2: vec2, color: int = YELLOW):
    draw.add_line(_tuplify(bf.m_pos(model, p1)), _tuplify(bf.m_pos(model, p2)), color)

  def draw_circle(p: vec2, radius: float, color: int = YELLOW):
    draw.add_circle(_tuplify(bf.m_pos(model, p)), bf.m_size(model, radius), color)

  cells = 10

  size = _to_vec2(size_)
  pos = _to_vec2(pos_)
  model = mat3()
  model = bf.mat_translate(model, pos + size / 2.0)
  model = bf.mat_scale(model, bf.scale_to_fit(vec2(1, 1), size) * 0.98)
  model = bf.mat_scale(model, vec2(1, 1) / cells)
  assert isinstance(model, mat3)

  def _tuplify(v: vec2) -> tuple[float, float]:
    return (v.x, v.y)

  # Drawing grid.
  model_ = model
  model = bf.mat_translate(model, -vec2(1, 1) * cells / 2)
  for x in range(cells + 1):
    draw_line(vec2(x, 0), vec2(x, cells), COLOR_GRID)
  for y in range(cells + 1):
    draw_line(vec2(0, y), vec2(cells, y), COLOR_GRID)
  model = model_

  sel_col = g.ref_selected_attack.ref_selected_collider
  for c in g.ref_selected_attack.colliders:
    color = YELLOW
    if (sel_col is not None) and (sel_col is not c):
      color = YELLOW_DIMMED

    match c.type:
      case ColliderType.CIRCLE:
        assert isinstance(c, ColliderCircle)
        draw_circle(vec2(), c.radius[0].value, color)

      case ColliderType.CAPSULE:
        assert isinstance(c, ColliderCapsule)
        dirr = glm.rotate(vec2(c.circles_spread[0].value / 2, 0), c.rot[0].value)
        center = _to_vec2(c.center[0].value)
        draw_circle(center + dirr, c.radius[0].value, color)
        draw_circle(center - dirr, c.radius[0].value, color)
        # draw_line(vec2(), vec2(), YELLOW)
        # draw_line(vec2(), vec2(), YELLOW)

  draw.pop_clip_rect()
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
        bf.ImGuiPanel("Explorer", enable_debug(_panel_explorer)),
        bf.ImGuiPanel("Visualizer", enable_debug(_panel_visualizer)),
        bf.ImGuiPanel("Timeline", enable_debug(_panel_timeline)),
        bf.ImGuiPanel("Attack Inspector", enable_debug(_panel_attack_inspector)),
        bf.ImGuiPanel("Logs", hello_imgui.log_gui),
      ],
      setup_imgui_style=setup_imgui_style,
      before_exit=_dump_app_state,
    )
    _dump_task.cancel()

  asyncio.run(wrapper(), debug=True)


##
