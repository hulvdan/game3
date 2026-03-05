import typing as t
from dataclasses import dataclass

import bf_lib as bf
import glfw
from bf_typer import command
from slimgui import imgui as im


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
class State:
  timeline: list[Keyframe]
  exiting: bool = False
  count: int = 0

  timeline_hovered_line: int = -1


g = State(
  timeline=[
    Keyframe(0, 1, V2(0, 0)),
    Keyframe(2, 2, V2(0, 5)),
    Keyframe(3, 4, V2(10, 2)),
  ],
)


def v2add(v1: tuple[t.Any, t.Any], v2: tuple[t.Any, t.Any]) -> tuple[t.Any, t.Any]:
  return (v1[0] + v2[0], v1[1] + v2[1])


def v2sub(v1: tuple[t.Any, t.Any], v2: tuple[t.Any, t.Any]) -> tuple[t.Any, t.Any]:
  return (v1[0] - v2[0], v1[1] - v2[1])


def _frame() -> None:  ##
  im.begin("Timeline")

  hovered_line = -1

  # # Draw timeline background
  # im.invisible_button("timeline_area", (timeline_width, timeline_height))
  draw_list = im.get_window_draw_list()

  pos = im.get_cursor_screen_pos()
  size = v2sub(im.get_window_size(), v2sub(pos, im.get_window_pos()))

  draw_list.add_line(pos, v2add(pos, size), im.color_convert_float4_to_u32((1, 0, 0, 1)))

  for field_index, field in enumerate(("scale", "offset", "rotation")):
    if field_index == g.timeline_hovered_line:
      color = (1, 1, 0, 1)
    else:
      color = (1, 1, 1, 1)
    im.text_colored(color, field)
    if im.is_item_hovered():
      hovered_line = field_index

  # Change the color of the text after hover
  # Alternative: you can draw a rectangle behind instead
  # im.text_colored((1,1,0,1), "scale")

  # im.same_line()
  # draw_list.add_line(
  #   im.get_cursor_screen_pos(),
  #   v2add(pos, size),
  #   im.color_convert_float4_to_u32((1, 0, 0, 1)),
  # )

  # pos = im.get_item_rect_min()

  # # Draw keyframes as small circles
  # for kf in g.timeline:
  #   x = pos[0] + (kf.index / 5.0) * timeline_width
  #   y = pos[1] + timeline_height / 2
  #   draw_list.add_circle_filled((x, y), 5, im.color_convert_float4_to_u32((1, 0, 0, 1)))

  im.end()

  g.timeline_hovered_line = hovered_line
  ##


def _key_callback(_window, key, _scan, action, _mods) -> None:  ##
  if action == glfw.PRESS and key == glfw.KEY_ESCAPE:
    g.exiting = True
  ##


@command
def tool_attacks_markuper() -> None:  ##
  bf.show_imgui(_frame, _key_callback, lambda: g.exiting)
  ##
