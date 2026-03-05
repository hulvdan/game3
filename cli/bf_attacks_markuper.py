import asyncio
import shutil
import tempfile
import typing as t
from dataclasses import dataclass, field
from functools import partial
from pathlib import Path

import bf_lib as bf
import toml
from bf_typer import command
from imgui_bundle import ImVec2_Pydantic, hello_imgui
from imgui_bundle import imgui as im
from pydantic import BaseModel

# def v2add(v1: tuple[t.Any, t.Any], v2: tuple[t.Any, t.Any]) -> tuple[t.Any, t.Any]:
#   return (v1[0] + v2[0], v1[1] + v2[1])
#
#
# def v2sub(v1: tuple[t.Any, t.Any], v2: tuple[t.Any, t.Any]) -> tuple[t.Any, t.Any]:
#   return (v1[0] - v2[0], v1[1] - v2[1])

_LAST_RUN_STATE_FILE_PATH = bf.PROJECT_DIR / "tool_attack_markuper_last_run.toml"


LOGD = partial(hello_imgui.log, hello_imgui.LogLevel.debug)
LOGI = partial(hello_imgui.log, hello_imgui.LogLevel.info)
LOGW = partial(hello_imgui.log, hello_imgui.LogLevel.warning)
LOGE = partial(hello_imgui.log, hello_imgui.LogLevel.error)

# @dataclass
# class Keyframe:
#   index: int
#   scale: float
#   offset: V2


@dataclass
class DataAttack:
  name: str
  selected: bool = False


@dataclass
class DataCreature:
  name: str
  attacks: list[DataAttack]


class StateDump(BaseModel):  ##
  creature: str | None = None
  attack: str | None = None
  ##


@dataclass
class State:
  # timeline: list[Keyframe] = field(default_factory=list)
  creatures: list[DataCreature] = field(default_factory=list)

  exiting: bool = False
  count: int = 0

  timeline_hovered_line: int = -1
  frame: int = 0

  ref_selected_attack_creature: DataCreature | None = None
  ref_selected_attack: DataAttack | None = None

  scheduled_dump: asyncio.Semaphore = field(default_factory=lambda: asyncio.Semaphore(0))

  def dump(self) -> StateDump:  ##
    return StateDump(
      creature=(
        self.ref_selected_attack_creature.name
        if self.ref_selected_attack_creature
        else None
      ),
      attack=self.ref_selected_attack.name if self.ref_selected_attack else None,
    )
    ##

  def load(self, value: StateDump) -> None:  ##
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
    creature_flags = im.TreeNodeFlags_.span_avail_width
    if creature == g.ref_selected_attack_creature:
      creature_flags |= im.TreeNodeFlags_.selected
    if im.tree_node_ex(creature.name, creature_flags):
      for attack in creature.attacks:
        flags = im.TreeNodeFlags_.leaf | im.TreeNodeFlags_.span_avail_width
        if attack == g.ref_selected_attack:
          flags |= im.TreeNodeFlags_.selected
        if im.tree_node_ex(attack.name, flags):
          if im.is_item_clicked():
            g.ref_selected_attack_creature = creature
            g.ref_selected_attack = attack
            g.schedule_dump()
          im.tree_pop()
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


async def _dump_run_data():  ##
  while True:
    await g.scheduled_dump.acquire()
    LOGD("Saving...")
    with tempfile.NamedTemporaryFile(
      "w", encoding="utf-8", delete=False, suffix=".toml"
    ) as out:
      out_path = Path(out.name)
      toml.dump(g.dump().model_dump(), out)
    shutil.move(out_path, _LAST_RUN_STATE_FILE_PATH)
    LOGD("Saving... Success!")
  ##


@command
def tool_attacks_markuper() -> None:  ##
  g.creatures = [
    DataCreature(
      name="MOB_SPEAR",
      attacks=[
        DataAttack(name="DASH"),
        DataAttack(name="SWING"),
      ],
    ),
    DataCreature(
      name="BOSS_JAGRAS",
      attacks=[
        DataAttack(name="ROLL_FRONT"),
        DataAttack(name="ROLL_SIDE"),
        DataAttack(name="JUMP_BACK"),
      ],
    ),
  ]

  if _LAST_RUN_STATE_FILE_PATH.exists():
    with open(_LAST_RUN_STATE_FILE_PATH, encoding="utf-8") as in_file:
      state_data = toml.load(in_file)
    g.load(StateDump(**state_data))

  async def wrapper() -> None:
    _dump_task = asyncio.create_task(_dump_run_data())
    await bf.show_imgui(
      [
        bf.ImGuiPanel("Explorer", _panel_explorer),
        bf.ImGuiPanel("Visualizer", _panel_visualizer),
        bf.ImGuiPanel("Timeline", _panel_timeline),
        bf.ImGuiPanel("Logs", hello_imgui.log_gui),
      ]
    )
    _dump_task.cancel()

  asyncio.run(wrapper())
  ##
