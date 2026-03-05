import asyncio
import shutil
import tempfile
import threading
import typing as t
from abc import ABC
from contextlib import contextmanager
from dataclasses import dataclass, field
from enum import IntEnum, unique
from functools import partial
from pathlib import Path
from typing import Generic, TypeVar

import bf_lib as bf
import toml
from bf_typer import command
from imgui_bundle import ImVec2_Pydantic, hello_imgui
from imgui_bundle import imgui as im
from pydantic import BaseModel

HUE_GREEN = 2 / 7

T = TypeVar("T")

# def v2add(v1: tuple[t.Any, t.Any], v2: tuple[t.Any, t.Any]) -> tuple[t.Any, t.Any]:
#   return (v1[0] + v2[0], v1[1] + v2[1])
#
#
# def v2sub(v1: tuple[t.Any, t.Any], v2: tuple[t.Any, t.Any]) -> tuple[t.Any, t.Any]:
#   return (v1[0] - v2[0], v1[1] - v2[1])

_APP_STATE_FILE_PATH = bf.PROJECT_DIR / "tool_attack_markuper_app_save_state.toml"


LOGD = partial(hello_imgui.log, hello_imgui.LogLevel.debug)
LOGI = partial(hello_imgui.log, hello_imgui.LogLevel.info)
LOGW = partial(hello_imgui.log, hello_imgui.LogLevel.warning)
LOGE = partial(hello_imgui.log, hello_imgui.LogLevel.error)

# @dataclass
# class Keyframe:
#   index: int
#   scale: float
#   offset: V2


@unique
class ColliderType(IntEnum):
  INVALID = 0
  CIRCLE = 1
  CAPSULE = 2


class ColliderBase:  ##
  type: t.ClassVar[ColliderType] = ColliderType.INVALID

  def __new__(cls):
    assert cls is not ColliderBase
    return super().__new__(cls)

  ##


@dataclass(slots=True)
class Frame(Generic[T]):
  index: int
  value: T


@dataclass(slots=True)
class ColliderCircle(ColliderBase):
  type: t.ClassVar[ColliderType] = ColliderType.CIRCLE

  radius: list[Frame[float]] = field(default_factory=list)
  pos: list[Frame[ImVec2_Pydantic]] = field(default_factory=list)


@dataclass(slots=True)
class ColliderCapsule(ColliderBase):
  type: t.ClassVar[ColliderType] = ColliderType.CAPSULE

  radius: list[Frame[float]] = field(default_factory=list)
  pos1: list[Frame[ImVec2_Pydantic]] = field(default_factory=list)
  pos2: list[Frame[ImVec2_Pydantic]] = field(default_factory=list)


@dataclass
class Attack:
  name: str
  colliders: list[ColliderBase] = field(default_factory=list)

  ref_selected_collider: ColliderBase | None = None


@dataclass
class Creature:
  name: str
  attacks: list[Attack]


class AppSaveState(BaseModel):
  font_scale_main: float = 1
  creature: str | None = None
  attack: str | None = None
  collider_index: int | None = None


@dataclass
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


@contextmanager
def colorify_button(hue: float):  ##
  im.push_style_color(im.Col_.button, im.ImColor.hsv(hue, 0.6, 0.6).value)
  im.push_style_color(im.Col_.button_hovered, im.ImColor.hsv(hue, 0.7, 0.7).value)
  im.push_style_color(im.Col_.button_active, im.ImColor.hsv(hue, 0.8, 0.8).value)
  yield
  im.pop_style_color(3)
  ##


def _panel_attack_inspector() -> None:  ##
  if not g.ref_selected_attack:
    return

  with colorify_button(HUE_GREEN):
    if im.button("+circle"):
      g.ref_selected_attack.colliders.append(ColliderCircle())
    im.same_line()
    if im.button("+capsule"):
      g.ref_selected_attack.colliders.append(ColliderCapsule())

  for i, collider in enumerate(g.ref_selected_attack.colliders):
    flags = im.TreeNodeFlags_.leaf | im.TreeNodeFlags_.span_avail_width
    if g.ref_selected_attack.ref_selected_collider is collider:
      flags |= im.TreeNodeFlags_.selected
    if im.tree_node_ex(f"{i} {collider.type.name}", flags):
      if im.is_item_clicked():
        g.ref_selected_attack.ref_selected_collider = collider
      im.tree_pop()
  ##


def _panel_visualizer() -> None:  ##
  if g.ref_selected_attack is not None:
    assert g.ref_selected_attack_creature is not None
    im.text("Creature " + g.ref_selected_attack_creature.name)
    im.text("Attack " + g.ref_selected_attack.name)
  else:
    assert g.ref_selected_attack_creature is None
  ##


def _panel_timeline() -> None:  ##
  hovered_line = -1
  for field_index, field in enumerate(("scale", "offset", "rotation")):
    color = (1, 1, 0, 1) if (field_index == g.timeline_hovered_line) else (1, 1, 1, 1)
    im.text_colored(color, field)
    if im.is_item_hovered():
      hovered_line = field_index

  # draw_list = im.get_window_draw_list()
  # pos = im.get_cursor_screen_pos()
  # size = v2sub(im.get_window_size(), v2sub(pos, im.get_window_pos()))
  # draw_list.add_line(pos, v2add(pos, size), im.color_convert_float4_to_u32((1, 0, 0, 1)))
  # # # Draw keyframes as small circles
  # # for kf in g.timeline:
  # #   x = pos[0] + (kf.index / 5.0) * timeline_width
  # #   y = pos[1] + timeline_height / 2
  # #   draw_list.add_circle_filled((x, y), 5, im.color_convert_float4_to_u32((1, 0, 0, 1)))

  g.timeline_hovered_line = hovered_line
  ##


_dump_app_state_lock = threading.Lock()


def _dump_app_state():  ##
  with _dump_app_state_lock:
    LOGD("Saving...")
    with tempfile.NamedTemporaryFile(
      "w", encoding="utf-8", delete=False, suffix=".toml"
    ) as out:
      out_path = Path(out.name)
      toml.dump(g.dump().model_dump(), out)
    shutil.move(out_path, _APP_STATE_FILE_PATH)
  ##


async def _background_dump_run_data():  ##
  while True:
    await g.scheduled_dump.acquire()
    _dump_app_state()
  ##


@command
def tool_attacks_markuper() -> None:  ##
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

  async def wrapper() -> None:
    _dump_task = asyncio.create_task(_background_dump_run_data())
    await bf.show_imgui(
      [
        bf.ImGuiPanel("Explorer", _panel_explorer),
        bf.ImGuiPanel("Visualizer", _panel_visualizer),
        bf.ImGuiPanel("Timeline", _panel_timeline),
        bf.ImGuiPanel("Attack Inspector", _panel_attack_inspector),
        bf.ImGuiPanel("Logs", hello_imgui.log_gui),
      ],
      setup_imgui_style=setup_imgui_style,
      before_exit=_dump_app_state,
    )
    _dump_task.cancel()

  asyncio.run(wrapper())
  ##
