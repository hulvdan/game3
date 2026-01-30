# GODOT PAGE «Optimizing a build for size»
# https://docs.godotengine.org/en/stable/engine_details/development/compiling/optimizing_for_size.html
#
# Popcar's page «How to Minify Godot's Build Size (93MB -> 6.4MB exe)»
# https://popcar.bearblog.dev/how-to-minify-godots-build-size/

debug_symbols = "no"
# Godot >4.5 only. Otherwise, use optimize="size"
optimize = "size_extra"
# Much slower build times, smaller export size
lto = "full"

disable_3d = "yes"
disable_advanced_gui = "yes"

# Disables deprecated features
deprecated = "no"
# Disables the Vulkan driver (used in Forward+/Mobile Renderers)
vulkan = "no"
# Disables more Vulkan stuff
use_volk = "no"
# Disables Virtual Reality/Augmented Reality stuff
openxr = "no"
# Disables ZIP archive support
minizip = "no"
# Disables SIL Graphite smart fonts support
graphite = "no"

# Disables all modules so you can only enable what you need
modules_enabled_by_default = "no"
module_gdscript_enabled = "yes"
# Fallback text server; less features but works fine for English.
module_text_server_fb_enabled = "yes"
# Needed alongside a text server for text to render correctly
module_freetype_enabled = "yes"
module_svg_enabled = "yes"
module_webp_enabled = "yes"
module_godot_physics_2d_enabled = "yes"

# These next few options were introduced in Godot 4.5!
disable_navigation_2d = "yes"
disable_navigation_3d = "yes"
disable_xr = "yes"
# Disables the new accessibility features
accesskit = "no"
