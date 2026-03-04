# GODOT PAGE «Optimizing a build for size»
# https://docs.godotengine.org/en/stable/engine_details/development/compiling/optimizing_for_size.html
#
# Popcar's page «How to Minify Godot's Build Size (93MB -> 6.4MB exe)»
# https://popcar.bearblog.dev/how-to-minify-godots-build-size/
#
# optimize gdbuild
# https://docs.godotengine.org/en/stable/tutorials/editor/using_engine_compilation_configuration_editor.html#doc-engine-compilation-configuration-editor

debug_symbols = "no"
threads = "no"

_DEBUG = 0

if _DEBUG:
    optimize = "none"
    lto = "none"
else:
    optimize = "size_extra"
    lto = "full"

# disable_3d = "yes"
disable_advanced_gui = "yes"

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

module_text_server_adv_enabled = "no"
module_text_server_fb_enabled = "yes"
module_godot_physics_3d_enabled = "no"
module_jolt_physics_enabled = "yes"
disable_navigation_2d = "yes"
disable_navigation_3d = "yes"
disable_xr = "yes"
accesskit = "no"

# module_astcenc_enabled = "no"
# module_basis_universal_enabled = "no"
# module_bcdec_enabled = "no"
# module_bmp_enabled = "no"
# module_camera_enabled = "no"
# module_csg_enabled = "no"
# module_dds_enabled = "no"
# module_enet_enabled = "no"
# module_etcpak_enabled = "no"
# module_fbx_enabled = "no"
# module_gltf_enabled = "no"
# module_gridmap_enabled = "no"
# module_hdr_enabled = "no"
# module_interactive_music_enabled = "no"
# module_jsonrpc_enabled = "no"
# module_ktx_enabled = "no"
# module_mbedtls_enabled = "no"
# module_meshoptimizer_enabled = "no"
# module_mp3_enabled = "no"
# module_mobile_vr_enabled = "no"
# module_msdfgen_enabled = "no"
# module_multiplayer_enabled = "no"
# module_noise_enabled = "no"
# module_navigation_2d_enabled = "no"
# module_navigation_3d_enabled = "no"
# module_ogg_enabled = "no"
# module_openxr_enabled = "no"
# module_raycast_enabled = "no"
# module_regex_enabled = "no"
# module_svg_enabled = "no"
# module_tga_enabled = "no"
# module_theora_enabled = "no"
# module_tinyexr_enabled = "no"
# module_upnp_enabled = "no"
# module_vhacd_enabled = "no"
# module_vorbis_enabled = "no"
# module_webrtc_enabled = "no"
# module_websocket_enabled = "no"
# module_webxr_enabled = "no"
# module_zip_enabled = "no"


# platform: Target platform (web|windows)
#     default:
#     actual: windows
#     aliases: ['p']
#
# target: Compilation target (editor|template_release|template_debug)
#     default: editor
#     actual: editor
#
# arch: CPU architecture (auto|x86_32|x86_64|arm32|arm64|rv64|ppc64|wasm32|loongarch64)
#     default: auto
#     actual: x86_64
#
# dev_build: Developer build with dev-only debugging code (DEV_ENABLED) (yes|no)
#     default: False
#     actual: False
#
# optimize: Optimization level (by default inferred from 'target' and 'dev_build') (auto|none|custom|debug|speed|speed_trace|size|size_extra)
#     default: auto
#     actual: auto
#
# debug_symbols: Build with debugging symbols (yes|no)
#     default: False
#     actual: False
#
# separate_debug_symbols: Extract debugging symbols to a separate file (yes|no)
#     default: False
#     actual: False
#
# debug_paths_relative: Make file paths in debug symbols relative (if supported) (yes|no)
#     default: False
#     actual: False
#
# lto: Link-time optimization (production builds) (none|auto|thin|full)
#     default: none
#     actual: none
#
# threads: Enable threading support (yes|no)
#     default: True
#     actual: True
#
# deprecated: Enable compatibility code for deprecated and removed features (yes|no)
#     default: True
#     actual: True
#
# precision: Set the floating-point precision level (single|double)
#     default: single
#     actual: single
#
# minizip: Enable ZIP archive support using minizip (yes|no)
#     default: True
#     actual: True
#
# brotli: Enable Brotli for decompression and WOFF2 fonts support (yes|no)
#     default: True
#     actual: True
#
# xaudio2: Enable the XAudio2 audio driver on supported platforms (yes|no)
#     default: False
#     actual: False
#
# vulkan: Enable the Vulkan rendering driver (yes|no)
#     default: True
#     actual: True
#
# opengl3: Enable the OpenGL/GLES3 rendering driver (yes|no)
#     default: True
#     actual: True
#
# d3d12: Enable the Direct3D 12 rendering driver on supported platforms (yes|no)
#     default: False
#     actual: True
#
# metal: Enable the Metal rendering driver on supported platforms (Apple arm64 only) (yes|no)
#     default: False
#     actual: False
#
# use_volk: Use the volk library to load the Vulkan loader dynamically (yes|no)
#     default: True
#     actual: True
#
# accesskit: Use AccessKit C SDK (yes|no)
#     default: True
#     actual: True
#
# accesskit_sdk_path: Path to the AccessKit C SDK
#     default:
#     actual:
#
# sdl: Enable the SDL3 input driver (yes|no)
#     default: True
#     actual: True
#
# profiler: Specify the profiler to use (none|tracy|perfetto|instruments)
#     default: none
#     actual: none
#
# profiler_path: Path to the Profiler framework.
#     default:
#     actual:
#
# profiler_sample_callstack: Profile random samples application-wide using a callstack based sampler. (yes|no)
#     default: False
#     actual: False
#
# profiler_track_memory: Profile memory allocations, if the profiler supports it. (yes|no)
#     default: False
#     actual: False
#
# dev_mode: Alias for dev options: verbose=yes warnings=extra werror=yes tests=yes strict_checks=yes (yes|no)
#     default: False
#     actual: False
#
# tests: Build the unit tests (yes|no)
#     default: False
#     actual: False
#
# fast_unsafe: Enable unsafe options for faster incremental builds (yes|no)
#     default: False
#     actual: False
#
# ninja: Use the ninja backend for faster rebuilds (yes|no)
#     default: False
#     actual: False
#
# ninja_auto_run: Run ninja automatically after generating the ninja file (yes|no)
#     default: True
#     actual: True
#
# ninja_file: Path to the generated ninja file
#     default: build.ninja
#     actual: build.ninja
#
# compiledb: Generate compilation DB (`compile_commands.json`) for external tools (yes|no)
#     default: False
#     actual: False
#
# num_jobs: Use up to N jobs when compiling (equivalent to `-j N`). Defaults to max jobs - 1. Ignored if -j is used.
#     default:
#     actual:
#
# verbose: Enable verbose output for the compilation (yes|no)
#     default: False
#     actual: False
#
# progress: Show a progress indicator during compilation (yes|no)
#     default: True
#     actual: True
#
# warnings: Level of compilation warnings (extra|all|moderate|no)
#     default: all
#     actual: all
#
# werror: Treat compiler warnings as errors (yes|no)
#     default: False
#     actual: False
#
# extra_suffix: Custom extra suffix added to the base filename of all generated binary files
#     default:
#     actual:
#
# object_prefix: Custom prefix added to the base filename of all generated object files
#     default:
#     actual:
#
# vsproj: Generate a Visual Studio solution (yes|no)
#     default: False
#     actual: False
#
# vsproj_name: Name of the Visual Studio solution
#     default: godot
#     actual: godot
#
# import_env_vars: A comma-separated list of environment variables to copy from the outer environment.
#     default:
#     actual:
#
# disable_exceptions: Force disabling exception handling code (yes|no)
#     default: True
#     actual: True
#
# disable_3d: Disable 3D nodes for a smaller executable (yes|no)
#     default: False
#     actual: False
#
# disable_advanced_gui: Disable advanced GUI nodes and behaviors (yes|no)
#     default: False
#     actual: False
#
# disable_physics_2d: Disable 2D physics nodes and server (yes|no)
#     default: False
#     actual: False
#
# disable_physics_3d: Disable 3D physics nodes and server (yes|no)
#     default: False
#     actual: False
#
# disable_navigation_2d: Disable 2D navigation features (yes|no)
#     default: False
#     actual: False
#
# disable_navigation_3d: Disable 3D navigation features (yes|no)
#     default: False
#     actual: False
#
# disable_xr: Disable XR nodes and server (yes|no)
#     default: False
#     actual: False
#
# disable_overrides: Disable project settings overrides (override.cfg) (yes|no)
#     default: False
#     actual: False
#
# disable_path_overrides: Disable CLI arguments to override project path/main pack/scene and run scripts (export template only) (yes|no)
#     default: True
#     actual: True
#
# build_profile: Path to a file containing a feature build profile
#     default:
#     actual:
#
# custom_modules: A list of comma-separated directory paths containing custom modules to build.
#     default:
#     actual:
#
# custom_modules_recursive: Detect custom modules recursively for each specified path. (yes|no)
#     default: True
#     actual: True
#
# modules_enabled_by_default: If no, disable all modules except ones explicitly enabled (yes|no)
#     default: True
#     actual: True
#
# no_editor_splash: Don't use the custom splash screen for the editor (yes|no)
#     default: True
#     actual: True
#
# builtin_brotli: Use the built-in Brotli library (yes|no)
#     default: True
#     actual: True
#
# builtin_certs: Use the built-in SSL certificates bundles (yes|no)
#     default: True
#     actual: True
#
# builtin_clipper2: Use the built-in Clipper2 library (yes|no)
#     default: True
#     actual: True
#
# builtin_embree: Use the built-in Embree library (yes|no)
#     default: True
#     actual: True
#
# builtin_enet: Use the built-in ENet library (yes|no)
#     default: True
#     actual: True
#
# builtin_freetype: Use the built-in FreeType library (yes|no)
#     default: True
#     actual: True
#
# builtin_msdfgen: Use the built-in MSDFgen library (yes|no)
#     default: True
#     actual: True
#
# builtin_glslang: Use the built-in glslang library (yes|no)
#     default: True
#     actual: True
#
# builtin_graphite: Use the built-in Graphite library (yes|no)
#     default: True
#     actual: True
#
# builtin_harfbuzz: Use the built-in HarfBuzz library (yes|no)
#     default: True
#     actual: True
#
# builtin_sdl: Use the built-in SDL library (yes|no)
#     default: True
#     actual: True
#
# builtin_icu4c: Use the built-in ICU library (yes|no)
#     default: True
#     actual: True
#
# builtin_libjpeg_turbo: Use the built-in libjpeg-turbo library (yes|no)
#     default: True
#     actual: True
#
# builtin_libogg: Use the built-in libogg library (yes|no)
#     default: True
#     actual: True
#
# builtin_libpng: Use the built-in libpng library (yes|no)
#     default: True
#     actual: True
#
# builtin_libtheora: Use the built-in libtheora library (yes|no)
#     default: True
#     actual: True
#
# builtin_libvorbis: Use the built-in libvorbis library (yes|no)
#     default: True
#     actual: True
#
# builtin_libwebp: Use the built-in libwebp library (yes|no)
#     default: True
#     actual: True
#
# builtin_wslay: Use the built-in wslay library (yes|no)
#     default: True
#     actual: True
#
# builtin_mbedtls: Use the built-in mbedTLS library (yes|no)
#     default: True
#     actual: True
#
# builtin_miniupnpc: Use the built-in miniupnpc library (yes|no)
#     default: True
#     actual: True
#
# builtin_openxr: Use the built-in OpenXR library (yes|no)
#     default: True
#     actual: True
#
# builtin_pcre2: Use the built-in PCRE2 library (yes|no)
#     default: True
#     actual: True
#
# builtin_pcre2_with_jit: Use JIT compiler for the built-in PCRE2 library (yes|no)
#     default: True
#     actual: True
#
# builtin_recastnavigation: Use the built-in Recast navigation library (yes|no)
#     default: True
#     actual: True
#
# builtin_rvo2_2d: Use the built-in RVO2 2D library (yes|no)
#     default: True
#     actual: True
#
# builtin_rvo2_3d: Use the built-in RVO2 3D library (yes|no)
#     default: True
#     actual: True
#
# builtin_xatlas: Use the built-in xatlas library (yes|no)
#     default: True
#     actual: True
#
# builtin_zlib: Use the built-in zlib library (yes|no)
#     default: True
#     actual: True
#
# builtin_zstd: Use the built-in Zstd library (yes|no)
#     default: True
#     actual: True
#
# CXX: C++ compiler binary
#     default: None
#     actual: None
#
# CC: C compiler binary
#     default: None
#     actual: None
#
# LINK: Linker binary
#     default: None
#     actual: None
#
# cppdefines: Custom defines for the pre-processor
#     default: None
#     actual: None
#
# ccflags: Custom flags for both the C and C++ compilers
#     default: None
#     actual: None
#
# cxxflags: Custom flags for the C++ compiler
#     default: None
#     actual: None
#
# cflags: Custom flags for the C compiler
#     default: None
#     actual: None
#
# linkflags: Custom flags for the linker
#     default: None
#     actual: None
#
# asflags: Custom flags for the assembler
#     default: None
#     actual: None
#
# arflags: Custom flags for the archive tool
#     default: None
#     actual: None
#
# rcflags: Custom flags for Windows resource compiler
#     default: None
#     actual: None
#
# c_compiler_launcher: C compiler launcher (e.g. `ccache`)
#     default: None
#     actual: None
#
# cpp_compiler_launcher: C++ compiler launcher (e.g. `ccache`)
#     default: None
#     actual: None
#
# mingw_prefix: MinGW prefix
#     default:
#     actual:
#
# windows_subsystem: Windows subsystem (gui|console)
#     default: gui
#     actual: gui
#
# msvc_version: MSVC version to use. Handled automatically by SCons if omitted.
#     default:
#     actual:
#
# use_mingw: Use the Mingw compiler, even if MSVC is installed. (yes|no)
#     default: False
#     actual: False
#
# use_llvm: Use the LLVM compiler (yes|no)
#     default: False
#     actual: False
#
# use_static_cpp: Link MinGW/MSVC C++ runtime libraries statically (yes|no)
#     default: True
#     actual: True
#
# use_asan: Use address sanitizer (ASAN) (yes|no)
#     default: False
#     actual: False
#
# use_ubsan: Use LLVM compiler undefined behavior sanitizer (UBSAN) (yes|no)
#     default: False
#     actual: False
#
# debug_crt: Compile with MSVC's debug CRT (/MDd) (yes|no)
#     default: False
#     actual: False
#
# incremental_link: Use MSVC incremental linking. May increase or decrease build times. (yes|no)
#     default: False
#     actual: False
#
# silence_msvc: Silence MSVC's cl/link stdout bloat, redirecting any errors to stderr. (yes|no)
#     default: True
#     actual: True
#
# angle_libs: Path to the ANGLE static libraries
#     default:
#     actual:
#
# mesa_libs: Path to the MESA/NIR static libraries (required for D3D12)
#     default: C:\Users\user\AppData\Local\Godot\build_deps\mesa
#     actual: C:\Users\user\AppData\Local\Godot\build_deps\mesa
#
# agility_sdk_path: Path to the Agility SDK distribution (optional for D3D12)
#     default: C:\Users\user\AppData\Local\Godot\build_deps\agility_sdk
#     actual: C:\Users\user\AppData\Local\Godot\build_deps\agility_sdk
#
# agility_sdk_multiarch: Whether the Agility SDK DLLs will be stored in arch-specific subdirectories (yes|no)
#     default: False
#     actual: False
#
# use_pix: Use PIX (Performance tuning and debugging for DirectX 12) runtime (yes|no)
#     default: False
#     actual: False
#
# pix_path: Path to the PIX runtime distribution (optional for D3D12)
#     default: C:\Users\user\AppData\Local\Godot\build_deps\pix
#     actual: C:\Users\user\AppData\Local\Godot\build_deps\pix
#
# module_astcenc_enabled: Enable module 'astcenc' (yes|no)
#     default: True
#     actual: True
#
# module_basis_universal_enabled: Enable module 'basis_universal' (yes|no)
#     default: True
#     actual: True
#
# module_bcdec_enabled: Enable module 'bcdec' (yes|no)
#     default: True
#     actual: True
#
# module_betsy_enabled: Enable module 'betsy' (yes|no)
#     default: True
#     actual: True
#
# betsy_export_templates: Enable Betsy image compression in export template builds (increases binary size) (yes|no)
#     default: False
#     actual: False
#
# module_bmp_enabled: Enable module 'bmp' (yes|no)
#     default: True
#     actual: True
#
# module_camera_enabled: Enable module 'camera' (yes|no)
#     default: True
#     actual: True
#
# module_csg_enabled: Enable module 'csg' (yes|no)
#     default: True
#     actual: True
#
# module_cvtt_enabled: Enable module 'cvtt' (yes|no)
#     default: True
#     actual: True
#
# cvtt_export_templates: Enable CVTT image compression in export template builds (increases binary size) (yes|no)
#     default: False
#     actual: False
#
# module_dds_enabled: Enable module 'dds' (yes|no)
#     default: True
#     actual: True
#
# module_enet_enabled: Enable module 'enet' (yes|no)
#     default: True
#     actual: True
#
# module_etcpak_enabled: Enable module 'etcpak' (yes|no)
#     default: True
#     actual: True
#
# module_fbx_enabled: Enable module 'fbx' (yes|no)
#     default: True
#     actual: True
#
# module_freetype_enabled: Enable module 'freetype' (yes|no)
#     default: True
#     actual: True
#
# module_gdscript_enabled: Enable module 'gdscript' (yes|no)
#     default: True
#     actual: True
#
# module_glslang_enabled: Enable module 'glslang' (yes|no)
#     default: True
#     actual: True
#
# module_gltf_enabled: Enable module 'gltf' (yes|no)
#     default: True
#     actual: True
#
# module_godot_physics_2d_enabled: Enable module 'godot_physics_2d' (yes|no)
#     default: True
#     actual: True
#
# module_godot_physics_3d_enabled: Enable module 'godot_physics_3d' (yes|no)
#     default: True
#     actual: True
#
# module_gridmap_enabled: Enable module 'gridmap' (yes|no)
#     default: True
#     actual: True
#
# module_hdr_enabled: Enable module 'hdr' (yes|no)
#     default: True
#     actual: True
#
# module_interactive_music_enabled: Enable module 'interactive_music' (yes|no)
#     default: True
#     actual: True
#
# module_jolt_physics_enabled: Enable module 'jolt_physics' (yes|no)
#     default: True
#     actual: True
#
# module_jpg_enabled: Enable module 'jpg' (yes|no)
#     default: True
#     actual: True
#
# module_jsonrpc_enabled: Enable module 'jsonrpc' (yes|no)
#     default: True
#     actual: True
#
# module_ktx_enabled: Enable module 'ktx' (yes|no)
#     default: True
#     actual: True
#
# module_lightmapper_rd_enabled: Enable module 'lightmapper_rd' (yes|no)
#     default: True
#     actual: True
#
# module_mbedtls_enabled: Enable module 'mbedtls' (yes|no)
#     default: True
#     actual: True
#
# module_meshoptimizer_enabled: Enable module 'meshoptimizer' (yes|no)
#     default: True
#     actual: True
#
# module_mobile_vr_enabled: Enable module 'mobile_vr' (yes|no)
#     default: True
#     actual: True
#
# module_mono_enabled: Enable module 'mono' (yes|no)
#     default: False
#     actual: False
#
# module_mp3_enabled: Enable module 'mp3' (yes|no)
#     default: True
#     actual: True
#
# mp3_extra_formats: Build mp3 module with MP1/MP2 decoding support (yes|no)
#     default: False
#     actual: False
#
# module_msdfgen_enabled: Enable module 'msdfgen' (yes|no)
#     default: True
#     actual: True
#
# module_multiplayer_enabled: Enable module 'multiplayer' (yes|no)
#     default: True
#     actual: True
#
# module_navigation_2d_enabled: Enable module 'navigation_2d' (yes|no)
#     default: True
#     actual: True
#
# module_navigation_3d_enabled: Enable module 'navigation_3d' (yes|no)
#     default: True
#     actual: True
#
# module_noise_enabled: Enable module 'noise' (yes|no)
#     default: True
#     actual: True
#
# module_objectdb_profiler_enabled: Enable module 'objectdb_profiler' (yes|no)
#     default: True
#     actual: True
#
# module_ogg_enabled: Enable module 'ogg' (yes|no)
#     default: True
#     actual: True
#
# module_openxr_enabled: Enable module 'openxr' (yes|no)
#     default: True
#     actual: True
#
# module_raycast_enabled: Enable module 'raycast' (yes|no)
#     default: True
#     actual: True
#
# module_regex_enabled: Enable module 'regex' (yes|no)
#     default: True
#     actual: True
#
# module_svg_enabled: Enable module 'svg' (yes|no)
#     default: True
#     actual: True
#
# module_text_server_adv_enabled: Enable module 'text_server_adv' (yes|no)
#     default: True
#     actual: True
#
# graphite: Enable SIL Graphite smart fonts support (yes|no)
#     default: True
#     actual: True
#
# module_text_server_fb_enabled: Enable module 'text_server_fb' (yes|no)
#     default: False
#     actual: False
#
# module_tga_enabled: Enable module 'tga' (yes|no)
#     default: True
#     actual: True
#
# module_theora_enabled: Enable module 'theora' (yes|no)
#     default: True
#     actual: True
#
# module_tinyexr_enabled: Enable module 'tinyexr' (yes|no)
#     default: True
#     actual: True
#
# module_upnp_enabled: Enable module 'upnp' (yes|no)
#     default: True
#     actual: True
#
# module_vhacd_enabled: Enable module 'vhacd' (yes|no)
#     default: True
#     actual: True
#
# module_vorbis_enabled: Enable module 'vorbis' (yes|no)
#     default: True
#     actual: True
#
# module_webp_enabled: Enable module 'webp' (yes|no)
#     default: True
#     actual: True
#
# module_webrtc_enabled: Enable module 'webrtc' (yes|no)
#     default: True
#     actual: True
#
# module_websocket_enabled: Enable module 'websocket' (yes|no)
#     default: True
#     actual: True
#
# module_webxr_enabled: Enable module 'webxr' (yes|no)
#     default: True
#     actual: True
#
# module_xatlas_unwrap_enabled: Enable module 'xatlas_unwrap' (yes|no)
#     default: True
#     actual: True
#
# module_zip_enabled: Enable module 'zip' (yes|no)
#     default: True
#     actual: True
