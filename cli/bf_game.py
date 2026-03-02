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

## Imports
import json
from collections import defaultdict
from pathlib import Path

import bf_lib as bf
import numpy as np
from bf_typer import command, timing
from PIL import Image

##

bf.game_settings.itch_target = "hulvdan/emberveil2"
bf.game_settings.languages = ["russian", "english"]
bf.game_settings.yandex_metrica_counter_id = 106388631
bf.game_settings.colors = [  ##
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
]  ##


scoped_processing_args = ["None", "None"]


@bf.glib_processor
def process_glib(*args, **kwargs) -> None:  ##
    try:
        _process_glib(*args, **kwargs)
    except Exception:
        print("ERROR HAPPENED DURING PROCESSING:", ", ".join(scoped_processing_args))
        raise
    ##


def outer_transpose_pos(
    object_pos: tuple[int, int], object_size: tuple[int, int], level_size: tuple[int, int]
) -> tuple[int, int]:  ##
    x, y = object_pos
    _w, h = object_size
    _level_w, level_h = level_size
    new_x = level_h - h - y
    new_y = x
    return new_x, new_y
    ##


def test_outer_transpose_pos() -> None:  ##
    assert outer_transpose_pos((0, 0), (1, 1), (3, 2)) == (1, 0)
    assert outer_transpose_pos((2, 1), (1, 1), (3, 2)) == (0, 2)
    assert outer_transpose_pos((0, 0), (2, 2), (4, 3)) == (1, 0)
    assert outer_transpose_pos((2, 1), (2, 2), (4, 3)) == (0, 2)
    ##


def _process_glib(genline, glib) -> None:
    test_outer_transpose_pos()

    # def enumerate_table(field: str): ##
    #     scoped_processing_args[0] = field
    #
    #     for i, x in enumerate(glib[field]):
    #         scoped_processing_args[1] = x["type"]
    #         yield i, x
    #
    #     scoped_processing_args[0] = "None"
    #     scoped_processing_args[1] = "None"
    #     ##

    transforms: list[tuple[str, str, str, dict[str, int]]] = []

    evade_type_2_value: dict[str, int] = {
        x["type"]: x["enum__value"] for x in glib["evades"]
    }
    team_type_2_value: dict[str, int] = {
        x["type"]: x["enum__value"] for x in glib["teams"]
    }

    def transform_evade_flags_list_of_strings_to_number(x: list[str], setter) -> None:  ##
        flags = 0
        for t in x:
            flags = flags | evade_type_2_value[t]
        setter(flags)
        ##

    def transform_team_flags_list_of_strings_to_number(x: list[str], setter) -> None:  ##
        flags = 0
        for t in x or []:
            flags = flags | team_type_2_value[t]
        setter(flags)
        ##

    ## LDTK. Enums
    ldtk_data = json.loads(Path("assets/level.ldtk").read_text(encoding="utf-8"))
    for enum in ldtk_data["defs"]["enums"]:
        identifier = enum["identifier"].lower()
        if identifier.startswith("codegen_"):
            enum["values"] = [
                {"id": v["type"], "tileRect": None, "color": 0}
                for v in glib[identifier.removeprefix("codegen_")]
                if v["type"] != "INVALID"
            ]
    Path("assets/level.ldtk").write_text(
        json.dumps(ldtk_data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    ##

    ## LDTK. Levels
    world = bf.ldtk_load("assets/level.ldtk")
    rooms = []
    for level in world.levels:
        if level.field("disable_export"):
            continue
        if level.identifier.startswith("DONT_INCLUDE"):
            continue

        for rotation_index in range(4):

            def transpose_pos(
                value: tuple[int, int] | tuple[float, float], size: tuple[int, int]
            ) -> tuple[int, int] | tuple[float, float]:
                outer_size = level.size
                for _ in range(rotation_index):
                    value = outer_transpose_pos(value, size, outer_size)
                    size = (size[1], size[0])
                    outer_size = (outer_size[1], outer_size[0])
                if rotation_index // 2:
                    value = (value[0], value[1] + size[1])
                if rotation_index in (1, 2):
                    value = (value[0] + size[0], value[1])
                return value

            def transpose_size(value: tuple[int, int]) -> tuple[int, int]:
                if rotation_index % 2:
                    return (value[1], value[0])
                return value

            def transpose_direction(value: int) -> int:
                return (value + rotation_index) % 4

            def transpose_array(value: list[int]) -> list[int]:
                size = level.size
                for _ in range(rotation_index):
                    arr = np.array(value).reshape(size[1], size[0])
                    rotated = np.rot90(arr, k=-1)
                    value = rotated.ravel().tolist()
                    size = (size[1], size[0])
                return value

            floor = level.get_layer("Floor")
            doors = []
            creatures = []
            spikes = []
            interactables = []
            entities = level.get_layer("Entities")
            for x in entities.entities("Door"):
                doors.append(
                    {
                        "center_pos": bf.as_dict(transpose_pos(x.pos_center, x.size)),
                        "size": bf.as_dict(transpose_size(x.size)),
                        "direction": transpose_direction(
                            int(x.field("Direction").split("_", 1)[-1])
                        ),
                    }
                )
            for x in entities.entities("Spike"):
                spikes.append({"pos": bf.as_dict(transpose_pos(x.pos_center, x.size))})
            for x in entities.entities("Interactable"):
                interactables.append(
                    {
                        "interactable_type": x.field("Interactable"),
                        "pos": bf.as_dict(transpose_pos(x.pos_center, x.size)),
                    }
                )
            for x in entities.entities("Creature"):
                creatures.append(
                    {
                        "creature_type": x.field("Type"),
                        "pos": bf.as_dict(transpose_pos(x.pos_center, x.size)),
                    }
                )
            rooms.append(
                {
                    "tiles": transpose_array(floor.intGridCsv),
                    "size": bf.as_dict(transpose_size(floor.size)),
                    "doors": doors,
                    "spikes": spikes,
                    "creatures": creatures,
                    "interactables": interactables,
                }
            )
    glib["rooms"] = rooms
    ##

    context = []
    not_found_tag_fields = []

    ## Tags
    entity_2_tag_required_fields: dict[str, dict[str, list[str]]] = defaultdict(
        defaultdict
    )
    for tag in glib["tags"]:
        for k, v in tag.items():
            if not k.endswith("_requirements"):
                continue
            table = k.removesuffix("_requirements")
            entity_2_tag_required_fields[table][tag["type"]] = list(v.keys()) if v else []

    def validate_tags(tags: list, entity: str) -> None:
        assert entity in entity_2_tag_required_fields
        for tag in tags:
            assert tag["tag_type"] in entity_2_tag_required_fields[entity], (
                "{}: Tag {} can't be used on {} because it doesn't have `{}`".format(
                    context, tag["tag_type"], entity, f"{entity}_requirements"
                )
            )
            for field in entity_2_tag_required_fields[entity][tag["tag_type"]]:
                if field not in tag:
                    not_found_tag_fields.append(field)
            assert not not_found_tag_fields, (
                "{}: Tag {} doesn't have required fields: {}".format(
                    context, tag["tag_type"], not_found_tag_fields
                )
            )

    ##

    def validate_attack(x: dict, is_player: bool) -> None:  ##
        x.get("projectiles_spawns", []).sort(key=lambda x: x["at"])
        if "stops_tracking_at" not in x:
            x["stops_tracking_at"] = x["duration"]
        if is_player:
            assert "stamina_cost" in x, context
        validate_tags(x.get("tags", []), "attack")
        if melee := x.get("melee"):
            if polygon := melee.get("polygon"):
                assert polygon["angle_degrees"] < 180, context
            if not is_player:
                assert "damage_stamina" in melee, context
        ##

    ## Creatures
    context.append("creatures")
    for x in glib["creatures"][1:]:
        context.append(x["type"])
        is_player = x["type"] == "PLAYER"
        x["res"] = "res://src/game/res_creatures/_{}.tres".format(x["type"].lower())
        context.append("attacks")
        for i, attack in enumerate(x.get("attacks", [])):
            context.append(i)
            validate_attack(attack, is_player)
            context.pop()
        context.pop()
        context.append("abilities")
        for i, ability in enumerate(x.get("abilities", [])):
            context.append(i)
            if "attack" in ability:
                context.append("attack")
                validate_tags(attack.get("tags", []), "attack")
                context.pop()
            context.pop()
        context.pop()
        context.pop()
    context.pop()
    ##

    ## Abilities
    context.append("abilities")
    for i, x in enumerate(glib["abilities"]):
        context.append(i)
        context.append("attack")
        validate_attack(x["attack"], True)
        context.pop()
        context.pop()
    context.pop()
    ##

    ## Projectiles
    need_to_have_damage_stamina = []
    context.append("projectiles")
    for x in glib["projectiles"][1:]:
        context.append(x["type"])
        x["res"] = "res://src/game/res_projectiles/_{}.tres".format(x["type"].lower())
        evade_flags = x.get("evade_flags", [])
        stamina_blockable = ("JUST_BLOCKABLE" in evade_flags) or (
            "BLOCKABLE_IN_ANY_WAY" in evade_flags
        )
        if ("damage" in x) and ("damage_stamina" not in x) and stamina_blockable:
            need_to_have_damage_stamina.append(x["type"])
        validate_tags(x.get("tags", []), "projectile")
        context.pop()
    assert not need_to_have_damage_stamina, (
        context,
        "projectiles need to have damage_stamina",
        need_to_have_damage_stamina,
    )
    context.pop()
    ##

    ## Interactables
    for x in glib["interactables"][1:]:
        x["res"] = "res://src/game/res_interactables/_{}.tres".format(x["type"].lower())
    ##

    ## Progression
    prog_type_2_prog = {x["type"]: x for x in glib["progression"][1:]}
    required_to_specify_progression_types = list(prog_type_2_prog.keys())
    level_progression = world.get_level("DONT_INCLUDE_Progression")
    for entity in level_progression.get_layer("Progression").entities("Progression"):
        progression_type = entity.field("progression_type")
        assert progression_type in required_to_specify_progression_types, (
            f"Progression {progression_type} must be specified in ldtk ONCE",
        )
        required_to_specify_progression_types.remove(progression_type)
        p = prog_type_2_prog[progression_type]
        p["pos"] = bf.as_dict(entity.pos)
    assert not required_to_specify_progression_types, (
        f"{context} The folliwing progressions must be specified in LDTK: {required_to_specify_progression_types}"
    )
    glib["progression_size"] = bf.as_dict(level_progression.size)
    ##

    ## Tags
    for tag in glib["tags"]:
        for k in [k for k in tag if k.endswith("_requirements")]:
            tag.pop(k)
    ##

    def transform_damage_stamina(x: float, setter) -> None:  ##
        setter(
            {
                "flat": x,
                "rally": x * glib["player"]["block_damage_stamina_rally_perfent_of_flat"],
                "rally_discard_mult_pre": glib["player"][
                    "block_damage_stamina_rally_discard_mult_pre"
                ],
                "rally_discard_mult_post": glib["player"][
                    "block_damage_stamina_rally_discard_mult_post"
                ],
            }
        )
        ##

    bf.recursive_visiter(glib, "damage_stamina", None, transform_damage_stamina)

    glib["player"].pop("block_damage_stamina_rally_discard_mult_pre")
    glib["player"].pop("block_damage_stamina_rally_perfent_of_flat")
    glib["player"].pop("block_damage_stamina_rally_discard_mult_post")

    bf.recursive_visiter(
        glib, "evade_flags", None, transform_evade_flags_list_of_strings_to_number
    )
    bf.recursive_visiter(
        glib, "team_flags", None, transform_team_flags_list_of_strings_to_number
    )

    ## Tables
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
    table_field_name_type_pairs: list[tuple[str, str]] = []
    for i in range(start, end):
        line = glib_proto_lines[i]  # ex: `repeated Hostility hostilities = 7;`
        field_name = line.split(" =", 1)[0].rsplit(" ", 1)[-1].strip()
        type_name = line.split(" =", 1)[0].rsplit(" ", 2)[-2].strip()
        print(f"{field_name=} {type_name=}")
        table_field_name_type_pairs.append((field_name, type_name))

    print(f"{table_field_name_type_pairs=}")
    for field_name, type_name in table_field_name_type_pairs:
        table = glib[field_name]
        types = [x["type"] for x in table]
        for t in types:
            assert t.upper() == t, (
                "{}. {}. `type` fields must be in CONSTANT_CASE".format(field_name, t)
            )
        container = glib[field_name]
        for i in range(len(container)):
            container[i]["type"] = i
        bf.check_duplicates(types)
        flags = field_name.endswith("flags")
        overridden_values = [x.pop("enum__value", None) for x in table]
        assert bf.all_are_none(overridden_values) or bf.all_are_not_none(
            overridden_values
        ), "All entries must have enum__value field specified in {}".format(field_name)
        bf.genenum(
            genline,
            type_name + "Type",
            types,
            flag_values=flags,
            overridden_values=(
                None if bf.all_are_none(overridden_values) else overridden_values
            ),
            add_count=not flags,
        )
        transforms.append(
            (
                field_name,
                f"{type_name.lower()[1:]}_type",
                f"{type_name.lower()[1:]}_types",
                {v: i for i, v in enumerate(types)},
            )
        )
    ##

    ## Transforms
    for v in transforms:
        bf.recursive_replace_transform(glib, *(v[1:]))
    ##

    ## Tres checks
    required_to_be_bound_tres_filepaths = [
        x.as_posix() for x in Path("src").rglob("**/_*.tres")
    ]

    tres_errors = []

    def tres_callback(value: str, _) -> None:
        if not value.startswith("res://src/game/res_"):
            tres_errors.append(("INVALID PREFIX", value))
            return
        check_path = Path(value.removeprefix("res://"))
        if not check_path.exists():
            tres_errors.append(("NOT FOUND", check_path))
            return
        required_to_be_bound_tres_filepaths.remove(check_path.as_posix())

    bf.recursive_visiter(glib, "res", "ress", tres_callback)
    assert not tres_errors, tres_errors
    assert not required_to_be_bound_tres_filepaths, (
        "Found excessive tres files:\n{}".format(
            "\n".join(f"- {x}" for x in required_to_be_bound_tres_filepaths)
        )
    )
    ##


@command
@timing
def process_images():  ##
    for f in list(bf.ART_TEXTURES_DIR.rglob("_*.png")):
        f.unlink()

    for f in ("tile", "circle"):
        image = Image.open(bf.ART_SRC_DIR / f"{f}.png")
        index = -1
        for name_, color in zip(
            bf.game_settings.computed_color_names, bf.game_settings.colors, strict=True
        ):
            index += 1
            name = name_.lower().replace(" ", "_")
            bf.im_multiply(image, color).save(
                bf.ART_TEXTURES_DIR / "removeme" / f"_{f}_{index:02}_{name}.png"
            )

    # OUTLINE_WIDTH = 10

    # bf.im_conveyor(
    #     "volume_bands",
    #     "volume_bands",
    #     bf.imc_prefix(""),
    #     bf.imc_scale(0.2127),
    #     bf.imc_outline(radius=1, color=(0, 0, 0, 0)),
    #     bf.imc_outline(radius=8),
    #     out_dir=bf.ART_TEXTURES_DIR,
    # )

    # bf.im_conveyor(
    #     "icons_audio",
    #     "icons_audio",
    #     bf.imc_prefix(""),
    #     bf.imc_outline(radius=1, color=(0, 0, 0, 0)),
    #     bf.imc_outline(radius=8),
    #     # bf.imc_scale(0.5),
    #     out_dir=bf.ART_TEXTURES_DIR,
    # )

    # # _ui_background_rect
    # bf.im_rectangle((412, 582), radius=30).save(
    #     bf.ART_TEXTURES_DIR / "_ui_background_rect.png"
    # )

    # # _game_item_spot_shadow
    # bf.im_ellipse((120, 120)).save(bf.ART_TEXTURES_DIR / "_game_item_spot_shadow.png")

    # # _ui_button
    # bf.im_outline(
    #     bf.im_remap(
    #         Image.open(bf.ART_TEXTURES_DIR / "other" / "ui_button.png"),
    #         bf.palette_color_tuple3("ORANGE"),
    #         bf.palette_color_tuple3("CASABLANCA"),
    #     ),
    #     radius=OUTLINE_WIDTH,
    # ).save(bf.ART_TEXTURES_DIR / "_ui_button.png")

    # image_star = Image.open(bf.ART_TEXTURES_DIR / "other" / "ui_star.png")

    # # _ui_star_gold, _ui_star_gray, _ui_star_gold_small, _ui_star_gray_small
    # for suf, c1, c2 in (
    #     ("gold", "ORANGE", "CASABLANCA"),
    #     ("gray", "SCORPION", "SCORPION"),
    # ):
    #     image_star_processed = bf.im_outline(
    #         bf.im_remap(
    #             image_star, bf.palette_color_tuple3(c1), bf.palette_color_tuple3(c2)
    #         ),
    #         radius=int(OUTLINE_WIDTH * 1.4),
    #     )
    #     image_star_processed.save(bf.ART_TEXTURES_DIR / f"_ui_star_{suf}.png")

    #     small_star_scale = 0.1
    #     bf.im_outline(bf.im_scale(image_star_processed, small_star_scale), radius=2).save(
    #         bf.ART_TEXTURES_DIR / f"_ui_star_small_{suf}.png"
    #     )

    # # _game_particle_star
    # bf.im_outline(bf.im_star(270), radius=20, color=(255, 255, 255, 255)).save(
    #     bf.ART_TEXTURES_DIR / "_game_particle_star.png"
    # )

    # # _game_particle_circle_outline
    # bf.im_ellipse(
    #     180, width=int(20 * 7 / 8), fill=(0, 0, 0, 0), outline=(255, 255, 255)
    # ).save(bf.ART_TEXTURES_DIR / "_game_particle_circle_outline.png")

    # # _game_feedback_circle
    # bf.im_outline(
    #     bf.im_ellipse(60), radius=100, is_shadow=True, color=(255, 255, 255, 255)
    # ).save(bf.ART_TEXTURES_DIR / "_game_feedback_circle.png")

    # # _game_particle_diamond
    # diamond_size = 320
    # rh = Image.new("RGBA", (diamond_size, diamond_size), (255, 255, 255, 255))
    # ell = bf.im_ellipse(diamond_size, fill=(0, 0, 0, 255))
    # for off in ((0, 0), (1, 0), (0, 1), (1, 1)):
    #     rh.paste(
    #         ell,
    #         (
    #             off[0] * diamond_size - diamond_size // 2,
    #             off[1] * diamond_size - diamond_size // 2,
    #         ),
    #         ell,
    #     )
    # bf.im_extract_white(rh).save(bf.ART_TEXTURES_DIR / "_game_particle_diamond.png")

    # # _ui_icon_ad_small
    # bf.im_outline(
    #     bf.im_scale(Image.open(bf.ART_DIR / "src" / "icons" / "ic_video_fill.png"), 0.25),
    #     radius=OUTLINE_WIDTH,
    # ).save(bf.ART_TEXTURES_DIR / "_ui_icon_ad_small.png")

    # # Spritesheetifying items.
    # bf.im_spritesheetify(
    #     bf.ART_DIR / "src" / "main_001.png",
    #     cell_size=480,
    #     size=(7, 8),
    #     gap=10,
    #     out_dir=bf.ART_TEXTURES_DIR / "items",
    #     out_filename_prefix="_game_item_",
    # )
    # for f in (bf.ART_TEXTURES_DIR / "items").glob("*.png"):
    #     img = Image.open(f)
    #     img.save(bf.ART_TEXTURES_DIR / f.name)
    #     bf.im_white(img).save(bf.ART_TEXTURES_DIR / (f.stem + "_dark.png"))

    # bf.im_conveyor(
    #     "icons",
    #     "Icons",
    #     bf.imc_prefix(""),
    #     bf.imc_scale(0.55),
    #     bf.imc_outline(radius=OUTLINE_WIDTH),
    # )

    # # Screenshots.
    # # if 1:
    # banner = Image.open(bf.ART_DIR / "src" / "dist_screenshot.png")
    # # banner =
    # # h = 185
    # # # margin = 20
    # # margin = 0
    # # outline_width = 7
    # # w = 1920 + 2 * outline_width
    # # rect = bf.im_rectangle(
    # #     (w - margin * 2, h - margin),
    # #     fill="white",
    # #     # radius=80,
    # #     width=outline_width,
    # #     outline="black",
    # # )
    # # banner.paste(rect, ((1920 - w) // 2 + margin, 1080 - h + outline_width))
    # # # else:
    # # #     banner = Image.open(bf.ART_DIR / "src" / "screenshot_text_banner.png")
    # banner = bf.im_outline(
    #     banner,
    #     radius=40,
    #     color=(0, 0, 0, int(255 * 4 / 16)),
    #     is_shadow=True,
    #     extend=False,
    # )
    # banner_colors = [
    #     "8fd3ff",
    #     "eaaded",
    #     "91db69",
    #     "8fd3ff",
    # ]
    # _result = bf.read_localization_csv()
    # screenshot_loc_id_indices = sorted(
    #     i for i, x in enumerate(_result.loc_ids) if x.startswith("YANDEX_SCREENSHOT_")
    # )
    # font = ImageFont.truetype(
    #     bf.ART_DIR / "src" / "screenshots" / "SeymourOne-Regular.ttf", size=150
    # )

    # for language, texts in _result.loc_by_languages.items():
    #     out_dir = bf.ART_DIR / "src" / "screenshots_processed" / language
    #     for f in out_dir.glob("*.png"):
    #         f.unlink()
    #     bf.recursive_mkdir(out_dir)

    #     for banner_color_, loc_id_index, f in zip(
    #         banner_colors,
    #         screenshot_loc_id_indices,
    #         (bf.ART_DIR / "src" / "screenshots").glob("*.png"),
    #         strict=True,
    #     ):
    #         banner_color = bf.hex_to_rgb_ints(banner_color_)

    #         text_image = Image.new("RGBA", (3840, 1550))
    #         draw = ImageDraw.Draw(text_image)
    #         draw.text(
    #             (1920, 1478),
    #             texts[loc_id_index],
    #             fill=tuple(
    #                 int(x * 255)
    #                 for x in bf.transform_color(
    #                     bf.hex_to_rgb_floats(banner_color_),
    #                     saturation_scale=0.23,
    #                     value_scale=2.5,
    #                 )
    #             ),
    #             anchor="ms",
    #             font=font,
    #             stroke_width=14,
    #             stroke_fill="black",
    #         )
    #         text_image = bf.im_outline(
    #             text_image,
    #             radius=40,
    #             color=(0, 0, 0, round(255 * 3 / 16)),
    #             is_shadow=True,
    #             extend=False,
    #         )

    #         brightness = 1.0
    #         contrast = 1.0
    #         if 1:
    #             brightness = 1.06
    #             contrast = 1.1

    #         img = Image.new("RGBA", (1920, 1080))
    #         img.paste(
    #             ImageEnhance.Brightness(
    #                 ImageEnhance.Contrast(Image.open(f)).enhance(contrast)
    #             ).enhance(brightness),
    #             (0, -100),
    #         )
    #         bf.im_draw_on_top(
    #             bf.im_draw_on_top(img, banner, (*banner_color, 255)),
    #             text_image.resize((1920, 1080)),
    #         ).save(out_dir / f.name)

    # import bf_cli

    # bf_cli.do_generate(bf.BuildPlatform.Win, bf.BuildType.Debug)
    # bf_cli.do_activate_game_ahk()

    ##


@command
def temp():  ##
    pass
    ##
