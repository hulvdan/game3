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


# def _frame() -> None:  ##
#   im.begin("Visualization")
#   im.end()

#   im.begin("Explorer")
#   im.end()

#   im.begin("Timeline")

#   hovered_line = -1

#   draw_list = im.get_window_draw_list()

#   pos = im.get_cursor_screen_pos()
#   size = v2sub(im.get_window_size(), v2sub(pos, im.get_window_pos()))

#   draw_list.add_line(pos, v2add(pos, size), im.color_convert_float4_to_u32((1, 0, 0, 1)))

#   for field_index, field in enumerate(("scale", "offset", "rotation")):
#     color = (1, 1, 0, 1) if (field_index == g.timeline_hovered_line) else (1, 1, 1, 1)
#     im.text_colored(color, field)
#     if im.is_item_hovered():
#       hovered_line = field_index

#   # # Draw keyframes as small circles
#   # for kf in g.timeline:
#   #   x = pos[0] + (kf.index / 5.0) * timeline_width
#   #   y = pos[1] + timeline_height / 2
#   #   draw_list.add_circle_filled((x, y), 5, im.color_convert_float4_to_u32((1, 0, 0, 1)))

#   im.end()

#   g.timeline_hovered_line = hovered_line
#   ##


@command
def tool_attacks_markuper() -> None:  ##
  # print(
  #   f"For information, demos sources are available in {demo_utils.api_demos.demos_python_folder()}"
  # )

  # Part 1: Define the runner params

  # Hello ImGui params (they hold the settings as well as the Gui callbacks)
  runner_params = hello_imgui.RunnerParams()
  # Window size and title
  runner_params.app_window_params.window_title = "Dear ImGui Bundle Explorer"
  runner_params.app_window_params.window_geometry.size = (1400, 950)

  # Menu bar
  runner_params.imgui_window_params.show_menu_bar = True
  runner_params.imgui_window_params.show_status_bar = True

  runner_params.ini_clear_previous_settings = True

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
    DemoDetails("Intro", demo_imgui_bundle_intro),
    DemoDetails("Dear ImGui", demo_imgui_show_demo_window),
    DemoDetails("Demo Apps", demo_immapp_launcher),
  ]

  for demo in standalone_demos:
    window = hello_imgui.DockableWindow()
    window.label = demo.label
    window.dock_space_name = "MainDockSpace"
    demo_module_name = demo.demo_module.__name__.split(".")[-1]

    def make_win_fn(mod_name: str, mod: ModuleType, sc: bool) -> Callable[[], None]:
      def win_fn() -> None:
        show_module_demo(mod_name, mod.demo_gui, sc)

      return win_fn

    window.gui_function = make_win_fn(demo_module_name, demo.demo_module, demo.show_code)
    dockable_windows.append(window)

  # --- Grouped tabs (sub-demos shown as collapsing headers) ---
  groups = [
    DemoGroup(
      "Visualization",
      [
        DemoDetails("Plots with ImPlot and ImPlot3D", demo_implot),
        DemoDetails("ImmVision - Image analyzer", demo_immvision_launcher),
        DemoDetails("ImGuizmo - Immediate Mode 3D Gizmo", demo_imguizmo_launcher),
        DemoDetails("NanoVG - 2D Vector Drawing", demo_nanovg_launcher),
      ],
    ),
    DemoGroup(
      "Widgets",
      [
        DemoDetails("Markdown - Rich Text Rendering", demo_imgui_md, show_code=True),
        DemoDetails("Text Editor - Code Editing Widget", demo_text_edit, show_code=True),
        DemoDetails("Misc Widgets - Knobs, Toggles, ...", demo_widgets, show_code=True),
        DemoDetails("Logger - Log Window Widget", demo_logger, show_code=True),
        DemoDetails("Tex Inspect - Texture Inspector", demo_tex_inspect_launcher),
      ],
    ),
    DemoGroup(
      "Tools",
      [
        DemoDetails("Node Editor - Visual Node Graphs", demo_node_editor_launcher),
        DemoDetails("Themes - Style & Color Customization", demo_themes, show_code=True),
        DemoDetails("ImAnim - Animation Library", demo_im_anim),
      ],
    ),
  ]

  for group in groups:
    window = hello_imgui.DockableWindow()
    window.label = group.label
    window.dock_space_name = "MainDockSpace"

    def make_group_fn(g: DemoGroup) -> Callable[[], None]:
      def win_fn() -> None:
        _show_group_gui(g)

      return win_fn

    window.gui_function = make_group_fn(group)
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

  if "test_engine" in dir(
    imgui
  ):  # only enable test engine if available (i.e. if imgui bundle was compiled with it)
    runner_params.use_imgui_test_engine = True

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


# def show_imgui(
#   frame: t.Callable[[], None], key_callback, should_exit: t.Callable[[], bool]
# ):  ##
#   glfw.init()
#   glfw.window_hint(glfw.CONTEXT_VERSION_MAJOR, 3)
#   glfw.window_hint(glfw.CONTEXT_VERSION_MINOR, 3)
#   glfw.window_hint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)
#   glfw.window_hint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
#   glfw.window_hint(glfw.VISIBLE, True)
#   window = glfw.create_window(
#     width=1600, height=900, title="Attacks Markuper", monitor=None, share=None
#   )
#   glfw.maximize_window(window)
#   glfw.make_context_current(window)
#   im.create_context()
#   io = im.get_io()
#   io.config_flags |= ConfigFlags.NAV_ENABLE_KEYBOARD
#   io.config_flags |= ConfigFlags.DOCKING_ENABLE
#   io.config_flags |= ConfigFlags.VIEWPORTS_ENABLE

#   with open(bf.PROJECT_DIR / "cli" / "ComicCode-Semibold.ttf", "rb") as f:
#     font_data = f.read()
#   font = io.fonts.add_font_from_memory_ttf(font_data, 32)
#   renderer = GlfwRenderer(window, prev_key_callback=key_callback)

#   while not (glfw.window_should_close(window) or should_exit()):
#     glfw.poll_events()
#     gl.glClear(int(gl.GL_COLOR_BUFFER_BIT) | int(gl.GL_DEPTH_BUFFER_BIT))
#     renderer.new_frame()
#     im.new_frame()
#     im.push_font(font, 0)

#     viewport = im.get_main_viewport()
#     im.set_next_window_pos(viewport.pos)
#     im.set_next_window_size(viewport.size)
#     im.begin(
#       "Root",
#       flags=(
#         im.WindowFlags.NO_TITLE_BAR
#         | im.WindowFlags.NO_RESIZE
#         | im.WindowFlags.NO_MOVE
#         | im.WindowFlags.NO_COLLAPSE
#         | im.WindowFlags.NO_BRING_TO_FRONT_ON_FOCUS
#         | im.WindowFlags.NO_NAV_FOCUS
#       ),
#     )
#     im.end()

#     frame()

#     im.pop_font()
#     im.render()
#     renderer.render(im.get_draw_data())
#     glfw.swap_buffers(window)

#   renderer.shutdown()
#   im.destroy_context(None)
#   ##


_show_code_states: dict[str, bool] = {}


def show_module_demo(
  demo_filename: str, demo_function: Callable[[], None], show_code: bool = False
) -> None:
  if imgui.get_frame_count() < 2:  # cf https://github.com/pthom/imgui_bundle/issues/293
    return
  if show_code:
    current = _show_code_states.get(demo_filename, False)
    _, current = imgui.checkbox("Show code##" + demo_filename, current)
    _show_code_states[demo_filename] = current
    if current:
      demo_utils.show_python_vs_cpp_file(demo_filename, 40)
  demo_function()


@dataclass
class DemoDetails:
  label: str
  demo_module: ModuleType
  show_code: bool = False


@dataclass
class DemoGroup:
  """A group of demos shown as collapsing headers inside a single tab."""

  label: str
  demos: List[DemoDetails] = field(default_factory=list)


def _show_group_gui(group: DemoGroup) -> None:
  """Gui function for a grouped tab: each sub-demo is a collapsing header."""
  if imgui.get_frame_count() < 2:
    return
  for demo in group.demos:
    demo_module_name = demo.demo_module.__name__.split(".")[-1]
    if imgui.collapsing_header(demo.label):
      imgui.indent()
      show_module_demo(demo_module_name, demo.demo_module.demo_gui, demo.show_code)
      imgui.unindent()
