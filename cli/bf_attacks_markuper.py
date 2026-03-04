import dataclasses

import bf_lib as bf
import glfw
from bf_typer import command
from slimgui import imgui as im


@dataclasses.dataclass
class State:
  exiting: bool = False
  count: int = 0


g = State()


def _frame():  ##
  im.set_next_window_size((400, 400), im.Cond.FIRST_USE_EVER)
  im.begin("Application Window")
  if im.button("Click me!"):
    g.count += 1
  im.same_line()
  im.text(f"Clicked {g.count} times")
  im.end()
  ##


def _key_callback(_window, key, _scan, action, _mods) -> None:  ##
  if action == glfw.PRESS and key == glfw.KEY_ESCAPE:
    g.exiting = True
  ##


@command
def tool_attacks_markuper():  ##
  bf.show_imgui(_frame, _key_callback, lambda: g.exiting)
  ##
