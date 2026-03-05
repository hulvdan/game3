import typing as t
from dataclasses import dataclass, field
from types import ModuleType
from typing import Callable, List

import bf_lib as bf
from bf_typer import command
from imgui_bundle import hello_imgui, imgui, immapp
from imgui_bundle.demos_python import (
  demo_im_anim,
  demo_imgui_bundle_intro,
  demo_imgui_md,
  demo_imgui_show_demo_window,
  demo_imguizmo_launcher,
  demo_immapp_launcher,
  demo_immvision_launcher,
  demo_implot,
  demo_logger,
  demo_nanovg_launcher,
  demo_node_editor_launcher,
  demo_tex_inspect_launcher,
  demo_text_edit,
  demo_themes,
  demo_utils,
  demo_widgets,
)


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
  frame: int = 0


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


def panel_visualizer() -> None:  ##
  pass
  ##


def panel_explorer() -> None:  ##
  pass
  ##


def panel_timeline() -> None:  ##
  hovered_line = -1
  for field_index, field in enumerate(("scale", "offset", "rotation")):
    color = (1, 1, 0, 1) if (field_index == g.timeline_hovered_line) else (1, 1, 1, 1)
    imgui.text_colored(color, field)
    if imgui.is_item_hovered():
      hovered_line = field_index
  g.timeline_hovered_line = hovered_line
  ##


# def _frame() -> None:  ##
#   im.begin("Visualization")
#   im.end()
#   im.begin("Explorer")
#   im.end()
#   im.begin("Timeline")
#   draw_list = im.get_window_draw_list()
#   pos = im.get_cursor_screen_pos()
#   size = v2sub(im.get_window_size(), v2sub(pos, im.get_window_pos()))
#   draw_list.add_line(pos, v2add(pos, size), im.color_convert_float4_to_u32((1, 0, 0, 1)))
#   # # Draw keyframes as small circles
#   # for kf in g.timeline:
#   #   x = pos[0] + (kf.index / 5.0) * timeline_width
#   #   y = pos[1] + timeline_height / 2
#   #   draw_list.add_circle_filled((x, y), 5, im.color_convert_float4_to_u32((1, 0, 0, 1)))
#   im.end()
#   ##


@command
def tool_attacks_markuper() -> None:
  show_imgui(
    [
      ImGuiPanel("Explorer", panel_explorer),
      ImGuiPanel("Visualizer", panel_visualizer),
      ImGuiPanel("Timeline", panel_timeline),
    ]
  )


@dataclass
class ImGuiPanel:  ##
  label: str
  gui_function: Callable[[], None]
  ##


def show_imgui(panels: list[ImGuiPanel]) -> None:  ##
  print(
    f"For information, demos sources are available in {demo_utils.demos_assets_folder()}"
  )

  # Part 1: Define the runner params

  runner_params = hello_imgui.RunnerParams()
  runner_params.app_window_params.window_title = "Attacks Markuper"
  runner_params.app_window_params.restore_previous_geometry = True

  # Menu bar
  runner_params.imgui_window_params.show_menu_bar = True
  runner_params.imgui_window_params.show_status_bar = True

  # Part 2: Define the application layout and windows

  # First, tell HelloImGui that we want full screen dock space (this will create "MainDockSpace")
  runner_params.imgui_window_params.default_imgui_window_type = (
    hello_imgui.DefaultImGuiWindowType.provide_full_screen_dock_space
  )
  # In this demo, we also demonstrate multiple viewports.
  # you can drag windows outside out the main window in order to put their content into new native windows
  runner_params.imgui_window_params.enable_viewports = True

  #
  # Define our dockable windows : each window provide a Gui callback, and will be displayed
  # in a docking split.
  #
  dockable_windows: List[hello_imgui.DockableWindow] = []

  # --- Standalone tabs (no grouping) ---
  standalone_demos = [
    _DemoDetails("Intro", demo_imgui_bundle_intro),
    _DemoDetails("Dear ImGui", demo_imgui_show_demo_window),
    _DemoDetails("Demo Apps", demo_immapp_launcher),
  ]

  for demo in standalone_demos:
    window = hello_imgui.DockableWindow()
    window.label = demo.label
    window.dock_space_name = "MainDockSpace"
    demo_module_name = demo.demo_module.__name__.split(".")[-1]

    def make_win_fn(mod_name: str, mod: ModuleType, sc: bool) -> Callable[[], None]:
      def win_fn() -> None:
        _show_module_demo(mod_name, mod.demo_gui, sc)

      return win_fn

    window.gui_function = make_win_fn(demo_module_name, demo.demo_module, demo.show_code)
    dockable_windows.append(window)

  # --- Grouped tabs (sub-demos shown as collapsing headers) ---
  groups = [
    _DemoGroup(
      "Visualization",
      [
        _DemoDetails("Plots with ImPlot and ImPlot3D", demo_implot),
        _DemoDetails("ImmVision - Image analyzer", demo_immvision_launcher),
        _DemoDetails("ImGuizmo - Immediate Mode 3D Gizmo", demo_imguizmo_launcher),
        _DemoDetails("NanoVG - 2D Vector Drawing", demo_nanovg_launcher),
      ],
    ),
    _DemoGroup(
      "Widgets",
      [
        _DemoDetails("Markdown - Rich Text Rendering", demo_imgui_md, show_code=True),
        _DemoDetails("Text Editor - Code Editing Widget", demo_text_edit, show_code=True),
        _DemoDetails("Misc Widgets - Knobs, Toggles, ...", demo_widgets, show_code=True),
        _DemoDetails("Logger - Log Window Widget", demo_logger, show_code=True),
        _DemoDetails("Tex Inspect - Texture Inspector", demo_tex_inspect_launcher),
      ],
    ),
    _DemoGroup(
      "Tools",
      [
        _DemoDetails("Node Editor - Visual Node Graphs", demo_node_editor_launcher),
        _DemoDetails("Themes - Style & Color Customization", demo_themes, show_code=True),
        _DemoDetails("ImAnim - Animation Library", demo_im_anim),
      ],
    ),
  ]

  for group in groups:
    window = hello_imgui.DockableWindow()
    window.label = group.label
    window.dock_space_name = "MainDockSpace"

    def make_group_fn(g: _DemoGroup) -> Callable[[], None]:
      def win_fn() -> None:
        _show_group_gui(g)

      return win_fn

    window.gui_function = make_group_fn(group)
    dockable_windows.append(window)

  for panel in panels:
    window = hello_imgui.DockableWindow()
    window.label = panel.label
    window.dock_space_name = "MainDockSpace"
    window.gui_function = panel.gui_function
    dockable_windows.append(window)

  runner_params.docking_params.dockable_windows = dockable_windows

  # the main gui is only responsible to give focus to ImGui Bundle dockable window
  def show_gui():
    if g.frame == 1:
      # Focus cannot be given at frame 0, since some additional windows will
      # be created after (and will steal the focus)
      runner_params.docking_params.focus_dockable_window("Dear ImGui Bundle")
    g.frame += 1

  def show_edit_font_scale_in_status_bar():
    imgui.set_next_item_width(imgui.get_content_region_avail().x / 10)
    _, imgui.get_style().font_scale_main = imgui.slider_float(
      "Font scale", imgui.get_style().font_scale_main, 0.5, 5
    )

  runner_params.callbacks.show_status = show_edit_font_scale_in_status_bar

  runner_params.callbacks.show_gui = show_gui

  def setup_imgui_config() -> None:
    imgui.get_io().config_flags |= imgui.ConfigFlags_.nav_enable_keyboard.value

  runner_params.callbacks.setup_imgui_config = setup_imgui_config

  # Part 3: Run the app
  addons = immapp.AddOnsParams()
  addons.with_markdown = True
  addons.with_node_editor = True
  addons.with_implot = True
  addons.with_implot3d = True
  addons.with_im_anim = True
  immapp.run(runner_params=runner_params, add_ons_params=addons)
  ##


_show_code_states: dict[str, bool] = {}


def im_id(value: str, id: str) -> str:  ##
  return str(value) + "#" + "#" + str(id)
  ##


def _show_module_demo(
  demo_filename: str, demo_function: Callable[[], None], show_code: bool = False
) -> None:  ##
  if imgui.get_frame_count() < 2:  # cf https://github.com/pthom/imgui_bundle/issues/293
    return
  if show_code:
    current = _show_code_states.get(demo_filename, False)
    _, current = imgui.checkbox(im_id("Show code", demo_filename), current)
    _show_code_states[demo_filename] = current
    if current:
      demo_utils.show_python_vs_cpp_file(demo_filename, 40)
  demo_function()
  ##


@dataclass
class _DemoDetails:  ##
  label: str
  demo_module: ModuleType
  show_code: bool = False
  ##


@dataclass
class _DemoGroup:  ##
  """A group of demos shown as collapsing headers inside a single tab."""

  label: str
  demos: List[_DemoDetails] = field(default_factory=list)
  ##


def _show_group_gui(group: _DemoGroup) -> None:  ##
  """Gui function for a grouped tab: each sub-demo is a collapsing header."""
  if imgui.get_frame_count() < 2:
    return
  for demo in group.demos:
    demo_module_name = demo.demo_module.__name__.split(".")[-1]
    if imgui.collapsing_header(demo.label):
      imgui.indent()
      _show_module_demo(demo_module_name, demo.demo_module.demo_gui, demo.show_code)
      imgui.unindent()
  ##
