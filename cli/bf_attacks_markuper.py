import typing as t
from dataclasses import dataclass

import bf_lib as bf
from bf_typer import command
from imgui_bundle import hello_imgui
from imgui_bundle import imgui as im


@dataclass
class V2:
  x: float
  y: float


@dataclass
class Keyframe:
  index: int
  scale: float
  offset: V2


@dataclass
class DataAttack:
  name: str
  selected: bool = False


@dataclass
class DataCreature:
  name: str
  attacks: list[DataAttack]


@dataclass
class State:
  timeline: list[Keyframe]
  creatures: list[DataCreature]

  exiting: bool = False
  count: int = 0

  timeline_hovered_line: int = -1
  frame: int = 0

  ref_selected_attack_creature: DataCreature | None = None
  ref_selected_attack: DataAttack | None = None


g = State(
  timeline=[
    Keyframe(0, 1, V2(0, 0)),
    Keyframe(2, 2, V2(0, 5)),
    Keyframe(3, 4, V2(10, 2)),
  ],
  creatures=[
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
  ],
)


def v2add(v1: tuple[t.Any, t.Any], v2: tuple[t.Any, t.Any]) -> tuple[t.Any, t.Any]:
  return (v1[0] + v2[0], v1[1] + v2[1])


def v2sub(v1: tuple[t.Any, t.Any], v2: tuple[t.Any, t.Any]) -> tuple[t.Any, t.Any]:
  return (v1[0] - v2[0], v1[1] - v2[1])


def panel_explorer() -> None:  ##
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
          im.tree_pop()
      im.tree_pop()
  ##


def panel_visualizer() -> None:  ##
  if g.ref_selected_attack is not None:
    assert g.ref_selected_attack_creature is not None
    im.text("Creature " + g.ref_selected_attack_creature.name)
    im.text("Attack " + g.ref_selected_attack.name)
  else:
    assert g.ref_selected_attack_creature is None
  ##


def panel_timeline() -> None:  ##
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


@command
def tool_attacks_markuper() -> None:  ##
  bf.show_imgui(
    [
      bf.ImGuiPanel("Explorer", panel_explorer),
      bf.ImGuiPanel("Visualizer", panel_visualizer),
      bf.ImGuiPanel("Timeline", panel_timeline),
    ]
  )
  ##
