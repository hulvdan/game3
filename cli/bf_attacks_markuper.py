import typing as t
from dataclasses import dataclass

import bf_lib as bf
import glfw
import OpenGL.GL as gl  # noqa: N811
import slimgui
from bf_typer import command
from slimgui import imgui as im
from slimgui.integrations.glfw import GlfwRenderer
from slimgui.slimgui_ext.imgui import ConfigFlags


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
  im.begin("Visualization")
  im.end()

  im.begin("Explorer")
  im.end()

  im.begin("Timeline")

  hovered_line = -1

  draw_list = im.get_window_draw_list()

  pos = im.get_cursor_screen_pos()
  size = v2sub(im.get_window_size(), v2sub(pos, im.get_window_pos()))

  draw_list.add_line(pos, v2add(pos, size), im.color_convert_float4_to_u32((1, 0, 0, 1)))

  for field_index, field in enumerate(("scale", "offset", "rotation")):
    color = (1, 1, 0, 1) if (field_index == g.timeline_hovered_line) else (1, 1, 1, 1)
    im.text_colored(color, field)
    if im.is_item_hovered():
      hovered_line = field_index

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
  show_imgui(_frame, _key_callback, lambda: g.exiting)
  ##


def show_imgui(
  frame: t.Callable[[], None], key_callback, should_exit: t.Callable[[], bool]
):  ##
  glfw.init()
  glfw.window_hint(glfw.CONTEXT_VERSION_MAJOR, 3)
  glfw.window_hint(glfw.CONTEXT_VERSION_MINOR, 3)
  glfw.window_hint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)
  glfw.window_hint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
  glfw.window_hint(glfw.VISIBLE, True)
  window = glfw.create_window(
    width=1600, height=900, title="Attacks Markuper", monitor=None, share=None
  )
  glfw.maximize_window(window)
  glfw.make_context_current(window)
  im.create_context()
  io = im.get_io()
  io.config_flags |= ConfigFlags.NAV_ENABLE_KEYBOARD
  io.config_flags |= ConfigFlags.DOCKING_ENABLE
  io.config_flags |= ConfigFlags.VIEWPORTS_ENABLE

  with open(bf.PROJECT_DIR / "cli" / "ComicCode-Semibold.ttf", "rb") as f:
    font_data = f.read()
  font = io.fonts.add_font_from_memory_ttf(font_data, 32)
  renderer = GlfwRenderer(window, prev_key_callback=key_callback)

  while not (glfw.window_should_close(window) or should_exit()):
    glfw.poll_events()
    gl.glClear(int(gl.GL_COLOR_BUFFER_BIT) | int(gl.GL_DEPTH_BUFFER_BIT))
    renderer.new_frame()
    im.new_frame()
    im.push_font(font, 0)

    viewport = im.get_main_viewport()
    im.set_next_window_pos(viewport.pos)
    im.set_next_window_size(viewport.size)
    im.begin(
      "Root",
      flags=(
        im.WindowFlags.NO_TITLE_BAR
        | im.WindowFlags.NO_RESIZE
        | im.WindowFlags.NO_MOVE
        | im.WindowFlags.NO_COLLAPSE
        | im.WindowFlags.NO_BRING_TO_FRONT_ON_FOCUS
        | im.WindowFlags.NO_NAV_FOCUS
      ),
    )
    im.end()

    frame()

    im.pop_font()
    im.render()
    renderer.render(im.get_draw_data())
    glfw.swap_buffers(window)

  renderer.shutdown()
  im.destroy_context(None)
  ##
