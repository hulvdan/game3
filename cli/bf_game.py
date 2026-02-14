"""
USAGE:

    from bf_lib import game_settings, glib_processor

    game_settings.itch_target = "hulvdan/cult-boy"
    game_settings.languages = ["russian", "english"]
    game_settings.yandex_metrica_counter_id = 1

    @glib_processor
    def process_glib(_genline, glib) -> None:
        for tile in glib["tiles"]:
            t = tile["type"]
"""

# Imports.  {  ###
import json
from pathlib import Path

import bf_lib as bf
from bf_typer import command, timing
from PIL import Image, ImageDraw, ImageEnhance, ImageFont

# }

bf.game_settings.itch_target = "hulvdan/emberveil2"
bf.game_settings.languages = ["russian", "english"]
bf.game_settings.yandex_metrica_counter_id = 106388631
bf.game_settings.colors = [  ###
    "#ffffff",
    "#fb6b1d",
    "#e83b3b",
    "#831c5d",
    "#c32454",
    "#f04f78",
    "#f68181",
    "#fca790",
    "#e3c896",
    "#ab947a",
    "#966c6c",
    "#625565",
    "#3e3546",
    "#0b5e65",
    "#0b8a8f",
    "#1ebc73",
    "#91db69",
    "#fbff86",
    "#fbb954",
    "#cd683d",
    "#9e4539",
    "#7a3045",
    "#6b3e75",
    "#905ea9",
    "#a884f3",
    "#eaaded",
    "#8fd3ff",
    "#4d9be6",
    "#4d65b4",
    "#484a77",
    "#30e1b9",
    "#8ff8e2",
    "#000000",
]


scoped_processing_args = ["None", "None"]


@bf.glib_processor
def process_glib(*args, **kwargs) -> None:
    # {  ###
    try:
        _process_glib(*args, **kwargs)
    except Exception:
        print("ERROR HAPPENED DURING PROCESSING:", ", ".join(scoped_processing_args))
        raise
    # }


def _process_glib(genline, glib) -> None:
    # def enumerate_table(field: str):
    #     # {  ###
    #     scoped_processing_args[0] = field
    #
    #     for i, x in enumerate(glib[field]):
    #         scoped_processing_args[1] = x["type"]
    #         yield i, x
    #
    #     scoped_processing_args[0] = "None"
    #     scoped_processing_args[1] = "None"
    #     # }

    transforms: list[tuple[str, str, str, dict[str, int]]] = []

    ldtk_codegen_data = json.loads(Path("assets/level.ldtk").read_text(encoding="utf-8"))
    for enum in ldtk_codegen_data["defs"]["enums"]:
        if enum["identifier"].startswith("CODEGEN_"):
            enum["values"] = [
                {"id": v["type"], "tileRect": None, "color": 0}
                for v in glib["progression"]
            ]
    Path("assets/level.ldtk").write_text(
        json.dumps(ldtk_codegen_data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    world = bf.ldtk_load("assets/level.ldtk")
    rooms = []
    for level in world.levels:
        if level.identifier.startswith("DONT_INCLUDE"):
            continue
        floor = level.get_layer("Floor")
        doors = []
        entities = level.get_layer("Entities")
        for door in entities.entities("Door"):
            doors.append(
                {
                    "center_pos": bf.as_dict(door.pos_center),
                    "size": bf.as_dict(door.size),
                    "direction": int(door.field("Direction").split("_", 1)[-1]),
                }
            )
        rooms.append(
            {
                "tiles": floor.intGridCsv,
                "size": bf.as_dict(floor.size),
                "doors": doors,
            }
        )
    glib["rooms"] = rooms

    # Progression.
    # ============================================================
    prog_type_2_prog = {x["type"]: x for x in glib["progression"][1:]}
    required_to_specify_progression_types = list(prog_type_2_prog.keys())
    for entity in (
        world.get_level("DONT_INCLUDE_Progression")
        .get_layer("Progression")
        .entities("Progression")
    ):
        progression_type = entity.field("progression_type")
        assert progression_type in required_to_specify_progression_types, (
            f"Progression {progression_type} must be specified in ldtk ONCE"
        )
        required_to_specify_progression_types.remove(progression_type)
        p = prog_type_2_prog[progression_type]
        p["pos"] = bf.as_dict(entity.pos)
    assert not required_to_specify_progression_types, (
        f"The folliwing progressions must be specified in LDTK: {required_to_specify_progression_types}"
    )

    # Tables.
    # ============================================================
    if 1:  # {  ###
        with open(bf.SRC_DIR / "game" / "glib.proto", encoding="utf-8") as in_file:
            glib_proto_lines = [l.strip() for l in in_file if l.strip()]

        start = -1
        end = -1
        for i, line in enumerate(glib_proto_lines):
            if "TABLE_GEN_START" in line:
                start = i + 1
            if "TABLE_GEN_END" in line:
                end = i
                break
        assert start >= 0
        assert end > start

        # tuples of field_name + type_name
        # ex: [("hostilities", "Hostility")]
        table_transform_data: list[tuple[str, str]] = []
        for i in range(start, end):
            line = glib_proto_lines[i]  # ex: `repeated Hostility hostilities = 7;`
            field_name = line.split(" =", 1)[0].rsplit(" ", 1)[-1].strip()
            type_name = line.split(" =", 1)[0].rsplit(" ", 2)[-2].strip()
            print(f"{field_name=} {type_name=}")
            table_transform_data.append((field_name, type_name))

        for field_name, type_name in table_transform_data:
            types = [x["type"] for x in glib[field_name]]
            for t in types:
                assert t.upper() == t, (
                    "{}. {}. `type` fields must be in CONSTANT_CASE".format(field_name, t)
                )
            bf.check_duplicates(types)
            bf.genenum(genline, type_name + "Type", types, add_count=True)
            transforms.append(
                (
                    field_name,
                    f"{type_name.lower()}_type",
                    f"{type_name.lower()}_types",
                    {v: i for i, v in enumerate(types)},
                )
            )
    # }

    # Transforms.
    # ============================================================
    # {  ###
    for v in transforms:
        bf.recursive_replace_transform(glib, *(v[1:]))
    # }


@command
@timing
def process_images():
    # {  ###
    for f in list(bf.ART_TEXTURES_DIR.rglob("_*.png")):
        f.unlink()

    OUTLINE_WIDTH = 10

    bf.im_conveyor(
        "volume_bands",
        "volume_bands",
        bf.imc_prefix(""),
        bf.imc_scale(0.2127),
        bf.imc_outline(radius=1, color=(0, 0, 0, 0)),
        bf.imc_outline(radius=8),
        out_dir=bf.ART_TEXTURES_DIR,
    )

    bf.im_conveyor(
        "icons_audio",
        "icons_audio",
        bf.imc_prefix(""),
        bf.imc_outline(radius=1, color=(0, 0, 0, 0)),
        bf.imc_outline(radius=8),
        # bf.imc_scale(0.5),
        out_dir=bf.ART_TEXTURES_DIR,
    )

    # _ui_background_rect
    bf.im_rectangle((412, 582), radius=30).save(
        bf.ART_TEXTURES_DIR / "_ui_background_rect.png"
    )

    # _game_item_spot_shadow
    bf.im_ellipse((120, 120)).save(bf.ART_TEXTURES_DIR / "_game_item_spot_shadow.png")

    # _ui_button
    bf.im_outline(
        bf.im_remap(
            Image.open(bf.ART_TEXTURES_DIR / "other" / "ui_button.png"),
            bf.palette_color_tuple3("ORANGE"),
            bf.palette_color_tuple3("CASABLANCA"),
        ),
        radius=OUTLINE_WIDTH,
    ).save(bf.ART_TEXTURES_DIR / "_ui_button.png")

    image_star = Image.open(bf.ART_TEXTURES_DIR / "other" / "ui_star.png")

    # _ui_star_gold, _ui_star_gray, _ui_star_gold_small, _ui_star_gray_small
    for suf, c1, c2 in (
        ("gold", "ORANGE", "CASABLANCA"),
        ("gray", "SCORPION", "SCORPION"),
    ):
        image_star_processed = bf.im_outline(
            bf.im_remap(
                image_star, bf.palette_color_tuple3(c1), bf.palette_color_tuple3(c2)
            ),
            radius=int(OUTLINE_WIDTH * 1.4),
        )
        image_star_processed.save(bf.ART_TEXTURES_DIR / f"_ui_star_{suf}.png")

        small_star_scale = 0.1
        bf.im_outline(bf.im_scale(image_star_processed, small_star_scale), radius=2).save(
            bf.ART_TEXTURES_DIR / f"_ui_star_small_{suf}.png"
        )

    # _game_particle_star
    bf.im_outline(bf.im_star(270), radius=20, color=(255, 255, 255, 255)).save(
        bf.ART_TEXTURES_DIR / "_game_particle_star.png"
    )

    # _game_particle_circle_outline
    bf.im_ellipse(
        180, width=int(20 * 7 / 8), fill=(0, 0, 0, 0), outline=(255, 255, 255)
    ).save(bf.ART_TEXTURES_DIR / "_game_particle_circle_outline.png")

    # _game_feedback_circle
    bf.im_outline(
        bf.im_ellipse(60), radius=100, is_shadow=True, color=(255, 255, 255, 255)
    ).save(bf.ART_TEXTURES_DIR / "_game_feedback_circle.png")

    # _game_particle_diamond
    diamond_size = 320
    rh = Image.new("RGBA", (diamond_size, diamond_size), (255, 255, 255, 255))
    ell = bf.im_ellipse(diamond_size, fill=(0, 0, 0, 255))
    for off in ((0, 0), (1, 0), (0, 1), (1, 1)):
        rh.paste(
            ell,
            (
                off[0] * diamond_size - diamond_size // 2,
                off[1] * diamond_size - diamond_size // 2,
            ),
            ell,
        )
    bf.im_extract_white(rh).save(bf.ART_TEXTURES_DIR / "_game_particle_diamond.png")

    # _ui_icon_ad_small
    bf.im_outline(
        bf.im_scale(Image.open(bf.ART_DIR / "src" / "icons" / "ic_video_fill.png"), 0.25),
        radius=OUTLINE_WIDTH,
    ).save(bf.ART_TEXTURES_DIR / "_ui_icon_ad_small.png")

    # Spritesheetifying items.
    bf.im_spritesheetify(
        bf.ART_DIR / "src" / "main_001.png",
        cell_size=480,
        size=(7, 8),
        gap=10,
        out_dir=bf.ART_TEXTURES_DIR / "items",
        out_filename_prefix="_game_item_",
    )
    for f in (bf.ART_TEXTURES_DIR / "items").glob("*.png"):
        img = Image.open(f)
        img.save(bf.ART_TEXTURES_DIR / f.name)
        bf.im_white(img).save(bf.ART_TEXTURES_DIR / (f.stem + "_dark.png"))

    bf.im_conveyor(
        "icons",
        "Icons",
        bf.imc_prefix(""),
        bf.imc_scale(0.55),
        bf.imc_outline(radius=OUTLINE_WIDTH),
    )

    # Screenshots.
    # if 1:
    banner = Image.open(bf.ART_DIR / "src" / "dist_screenshot.png")
    # banner =
    # h = 185
    # # margin = 20
    # margin = 0
    # outline_width = 7
    # w = 1920 + 2 * outline_width
    # rect = bf.im_rectangle(
    #     (w - margin * 2, h - margin),
    #     fill="white",
    #     # radius=80,
    #     width=outline_width,
    #     outline="black",
    # )
    # banner.paste(rect, ((1920 - w) // 2 + margin, 1080 - h + outline_width))
    # # else:
    # #     banner = Image.open(bf.ART_DIR / "src" / "screenshot_text_banner.png")
    banner = bf.im_outline(
        banner,
        radius=40,
        color=(0, 0, 0, int(255 * 4 / 16)),
        is_shadow=True,
        extend=False,
    )
    banner_colors = [
        "8fd3ff",
        "eaaded",
        "91db69",
        "8fd3ff",
    ]
    _result = bf.read_localization_csv()
    screenshot_loc_id_indices = sorted(
        i for i, x in enumerate(_result.loc_ids) if x.startswith("YANDEX_SCREENSHOT_")
    )
    font = ImageFont.truetype(
        bf.ART_DIR / "src" / "screenshots" / "SeymourOne-Regular.ttf", size=150
    )

    for language, texts in _result.loc_by_languages.items():
        out_dir = bf.ART_DIR / "src" / "screenshots_processed" / language
        for f in out_dir.glob("*.png"):
            f.unlink()
        bf.recursive_mkdir(out_dir)

        for banner_color_, loc_id_index, f in zip(
            banner_colors,
            screenshot_loc_id_indices,
            (bf.ART_DIR / "src" / "screenshots").glob("*.png"),
            strict=True,
        ):
            banner_color = bf.hex_to_rgb_ints(banner_color_)

            text_image = Image.new("RGBA", (3840, 1550))
            draw = ImageDraw.Draw(text_image)
            draw.text(
                (1920, 1478),
                texts[loc_id_index],
                fill=tuple(
                    int(x * 255)
                    for x in bf.transform_color(
                        bf.hex_to_rgb_floats(banner_color_),
                        saturation_scale=0.23,
                        value_scale=2.5,
                    )
                ),
                anchor="ms",
                font=font,
                stroke_width=14,
                stroke_fill="black",
            )
            text_image = bf.im_outline(
                text_image,
                radius=40,
                color=(0, 0, 0, round(255 * 3 / 16)),
                is_shadow=True,
                extend=False,
            )

            brightness = 1.0
            contrast = 1.0
            if 1:
                brightness = 1.06
                contrast = 1.1

            img = Image.new("RGBA", (1920, 1080))
            img.paste(
                ImageEnhance.Brightness(
                    ImageEnhance.Contrast(Image.open(f)).enhance(contrast)
                ).enhance(brightness),
                (0, -100),
            )
            bf.im_draw_on_top(
                bf.im_draw_on_top(img, banner, (*banner_color, 255)),
                text_image.resize((1920, 1080)),
            ).save(out_dir / f.name)

    import bf_cli  # noqa

    bf_cli.do_generate(bf.BuildPlatform.Win, bf.BuildType.Debug)
    bf_cli.do_activate_game_ahk()

    # }


@command
def temp():
    pass


###
