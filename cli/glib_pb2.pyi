from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Iterable as _Iterable, Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class GV2i(_message.Message):
    __slots__ = ("x", "y")
    X_FIELD_NUMBER: _ClassVar[int]
    Y_FIELD_NUMBER: _ClassVar[int]
    x: int
    y: int
    def __init__(self, x: _Optional[int] = ..., y: _Optional[int] = ...) -> None: ...

class GV2(_message.Message):
    __slots__ = ("x", "y")
    X_FIELD_NUMBER: _ClassVar[int]
    Y_FIELD_NUMBER: _ClassVar[int]
    x: float
    y: float
    def __init__(self, x: _Optional[float] = ..., y: _Optional[float] = ...) -> None: ...

class GV3i(_message.Message):
    __slots__ = ("x", "y", "z")
    X_FIELD_NUMBER: _ClassVar[int]
    Y_FIELD_NUMBER: _ClassVar[int]
    Z_FIELD_NUMBER: _ClassVar[int]
    x: int
    y: int
    z: int
    def __init__(self, x: _Optional[int] = ..., y: _Optional[int] = ..., z: _Optional[int] = ...) -> None: ...

class GV3(_message.Message):
    __slots__ = ("x", "y", "z")
    X_FIELD_NUMBER: _ClassVar[int]
    Y_FIELD_NUMBER: _ClassVar[int]
    Z_FIELD_NUMBER: _ClassVar[int]
    x: float
    y: float
    z: float
    def __init__(self, x: _Optional[float] = ..., y: _Optional[float] = ..., z: _Optional[float] = ...) -> None: ...

class GV4i(_message.Message):
    __slots__ = ("x", "y", "z", "w")
    X_FIELD_NUMBER: _ClassVar[int]
    Y_FIELD_NUMBER: _ClassVar[int]
    Z_FIELD_NUMBER: _ClassVar[int]
    W_FIELD_NUMBER: _ClassVar[int]
    x: int
    y: int
    z: int
    w: int
    def __init__(self, x: _Optional[int] = ..., y: _Optional[int] = ..., z: _Optional[int] = ..., w: _Optional[int] = ...) -> None: ...

class GV4(_message.Message):
    __slots__ = ("x", "y", "z", "w")
    X_FIELD_NUMBER: _ClassVar[int]
    Y_FIELD_NUMBER: _ClassVar[int]
    Z_FIELD_NUMBER: _ClassVar[int]
    W_FIELD_NUMBER: _ClassVar[int]
    x: float
    y: float
    z: float
    w: float
    def __init__(self, x: _Optional[float] = ..., y: _Optional[float] = ..., z: _Optional[float] = ..., w: _Optional[float] = ...) -> None: ...

class GCreatureToSpawn(_message.Message):
    __slots__ = ("creature_type", "pos")
    CREATURE_TYPE_FIELD_NUMBER: _ClassVar[int]
    POS_FIELD_NUMBER: _ClassVar[int]
    creature_type: int
    pos: GV2
    def __init__(self, creature_type: _Optional[int] = ..., pos: _Optional[_Union[GV2, _Mapping]] = ...) -> None: ...

class GDoor(_message.Message):
    __slots__ = ("center_pos", "size", "direction")
    CENTER_POS_FIELD_NUMBER: _ClassVar[int]
    SIZE_FIELD_NUMBER: _ClassVar[int]
    DIRECTION_FIELD_NUMBER: _ClassVar[int]
    center_pos: GV2
    size: GV2
    direction: int
    def __init__(self, center_pos: _Optional[_Union[GV2, _Mapping]] = ..., size: _Optional[_Union[GV2, _Mapping]] = ..., direction: _Optional[int] = ...) -> None: ...

class GSpike(_message.Message):
    __slots__ = ("pos",)
    POS_FIELD_NUMBER: _ClassVar[int]
    pos: GV2
    def __init__(self, pos: _Optional[_Union[GV2, _Mapping]] = ...) -> None: ...

class GRoomInteractable(_message.Message):
    __slots__ = ("interactable_type", "pos")
    INTERACTABLE_TYPE_FIELD_NUMBER: _ClassVar[int]
    POS_FIELD_NUMBER: _ClassVar[int]
    interactable_type: int
    pos: GV2
    def __init__(self, interactable_type: _Optional[int] = ..., pos: _Optional[_Union[GV2, _Mapping]] = ...) -> None: ...

class GRoom(_message.Message):
    __slots__ = ("doors", "size", "tiles", "spikes", "interactables", "creatures")
    DOORS_FIELD_NUMBER: _ClassVar[int]
    SIZE_FIELD_NUMBER: _ClassVar[int]
    TILES_FIELD_NUMBER: _ClassVar[int]
    SPIKES_FIELD_NUMBER: _ClassVar[int]
    INTERACTABLES_FIELD_NUMBER: _ClassVar[int]
    CREATURES_FIELD_NUMBER: _ClassVar[int]
    doors: _containers.RepeatedCompositeFieldContainer[GDoor]
    size: GV2i
    tiles: _containers.RepeatedScalarFieldContainer[int]
    spikes: _containers.RepeatedCompositeFieldContainer[GSpike]
    interactables: _containers.RepeatedCompositeFieldContainer[GRoomInteractable]
    creatures: _containers.RepeatedCompositeFieldContainer[GCreatureToSpawn]
    def __init__(self, doors: _Optional[_Iterable[_Union[GDoor, _Mapping]]] = ..., size: _Optional[_Union[GV2i, _Mapping]] = ..., tiles: _Optional[_Iterable[int]] = ..., spikes: _Optional[_Iterable[_Union[GSpike, _Mapping]]] = ..., interactables: _Optional[_Iterable[_Union[GRoomInteractable, _Mapping]]] = ..., creatures: _Optional[_Iterable[_Union[GCreatureToSpawn, _Mapping]]] = ...) -> None: ...

class GProgression(_message.Message):
    __slots__ = ("type", "debug_name", "pos")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    POS_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    pos: GV2i
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ..., pos: _Optional[_Union[GV2i, _Mapping]] = ...) -> None: ...

class GCreatureDrop(_message.Message):
    __slots__ = ("item_type", "min", "max")
    ITEM_TYPE_FIELD_NUMBER: _ClassVar[int]
    MIN_FIELD_NUMBER: _ClassVar[int]
    MAX_FIELD_NUMBER: _ClassVar[int]
    item_type: int
    min: int
    max: int
    def __init__(self, item_type: _Optional[int] = ..., min: _Optional[int] = ..., max: _Optional[int] = ...) -> None: ...

class GTag(_message.Message):
    __slots__ = ("type", "debug_name")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ...) -> None: ...

class GTagValue(_message.Message):
    __slots__ = ("tag_type", "i1", "i2", "i3", "i4", "i5", "i6", "f1", "f2", "f3", "f4", "f5", "f6", "projectile_type", "creature_type", "team_flags")
    TAG_TYPE_FIELD_NUMBER: _ClassVar[int]
    I1_FIELD_NUMBER: _ClassVar[int]
    I2_FIELD_NUMBER: _ClassVar[int]
    I3_FIELD_NUMBER: _ClassVar[int]
    I4_FIELD_NUMBER: _ClassVar[int]
    I5_FIELD_NUMBER: _ClassVar[int]
    I6_FIELD_NUMBER: _ClassVar[int]
    F1_FIELD_NUMBER: _ClassVar[int]
    F2_FIELD_NUMBER: _ClassVar[int]
    F3_FIELD_NUMBER: _ClassVar[int]
    F4_FIELD_NUMBER: _ClassVar[int]
    F5_FIELD_NUMBER: _ClassVar[int]
    F6_FIELD_NUMBER: _ClassVar[int]
    PROJECTILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    CREATURE_TYPE_FIELD_NUMBER: _ClassVar[int]
    TEAM_FLAGS_FIELD_NUMBER: _ClassVar[int]
    tag_type: int
    i1: int
    i2: int
    i3: int
    i4: int
    i5: int
    i6: int
    f1: float
    f2: float
    f3: float
    f4: float
    f5: float
    f6: float
    projectile_type: int
    creature_type: int
    team_flags: int
    def __init__(self, tag_type: _Optional[int] = ..., i1: _Optional[int] = ..., i2: _Optional[int] = ..., i3: _Optional[int] = ..., i4: _Optional[int] = ..., i5: _Optional[int] = ..., i6: _Optional[int] = ..., f1: _Optional[float] = ..., f2: _Optional[float] = ..., f3: _Optional[float] = ..., f4: _Optional[float] = ..., f5: _Optional[float] = ..., f6: _Optional[float] = ..., projectile_type: _Optional[int] = ..., creature_type: _Optional[int] = ..., team_flags: _Optional[int] = ...) -> None: ...

class GKeyframeBool(_message.Message):
    __slots__ = ("id", "index_timeline", "value")
    ID_FIELD_NUMBER: _ClassVar[int]
    INDEX_TIMELINE_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    id: int
    index_timeline: int
    value: bool
    def __init__(self, id: _Optional[int] = ..., index_timeline: _Optional[int] = ..., value: _Optional[bool] = ...) -> None: ...

class GKeyframeInt32(_message.Message):
    __slots__ = ("id", "index_timeline", "value")
    ID_FIELD_NUMBER: _ClassVar[int]
    INDEX_TIMELINE_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    id: int
    index_timeline: int
    value: int
    def __init__(self, id: _Optional[int] = ..., index_timeline: _Optional[int] = ..., value: _Optional[int] = ...) -> None: ...

class GKeyframeFloat(_message.Message):
    __slots__ = ("id", "index_timeline", "value")
    ID_FIELD_NUMBER: _ClassVar[int]
    INDEX_TIMELINE_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    id: int
    index_timeline: int
    value: float
    def __init__(self, id: _Optional[int] = ..., index_timeline: _Optional[int] = ..., value: _Optional[float] = ...) -> None: ...

class GKeyframeString(_message.Message):
    __slots__ = ("id", "index_timeline", "value")
    ID_FIELD_NUMBER: _ClassVar[int]
    INDEX_TIMELINE_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    id: int
    index_timeline: int
    value: str
    def __init__(self, id: _Optional[int] = ..., index_timeline: _Optional[int] = ..., value: _Optional[str] = ...) -> None: ...

class GKeyframeV2(_message.Message):
    __slots__ = ("id", "index_timeline", "value")
    ID_FIELD_NUMBER: _ClassVar[int]
    INDEX_TIMELINE_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    id: int
    index_timeline: int
    value: GV2
    def __init__(self, id: _Optional[int] = ..., index_timeline: _Optional[int] = ..., value: _Optional[_Union[GV2, _Mapping]] = ...) -> None: ...

class GKeyframeV3(_message.Message):
    __slots__ = ("id", "index_timeline", "value")
    ID_FIELD_NUMBER: _ClassVar[int]
    INDEX_TIMELINE_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    id: int
    index_timeline: int
    value: GV3
    def __init__(self, id: _Optional[int] = ..., index_timeline: _Optional[int] = ..., value: _Optional[_Union[GV3, _Mapping]] = ...) -> None: ...

class GKeyframeV4(_message.Message):
    __slots__ = ("id", "index_timeline", "value")
    ID_FIELD_NUMBER: _ClassVar[int]
    INDEX_TIMELINE_FIELD_NUMBER: _ClassVar[int]
    VALUE_FIELD_NUMBER: _ClassVar[int]
    id: int
    index_timeline: int
    value: GV4
    def __init__(self, id: _Optional[int] = ..., index_timeline: _Optional[int] = ..., value: _Optional[_Union[GV4, _Mapping]] = ...) -> None: ...

class GCollider(_message.Message):
    __slots__ = ("id", "type", "debug_name", "tr", "is_active", "circle__radius", "capsule__radius", "capsule__spread", "capsule__rotation", "polygon__dist_min", "polygon__dist_max", "polygon__rotation", "polygon__spread_angle")
    ID_FIELD_NUMBER: _ClassVar[int]
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    TR_FIELD_NUMBER: _ClassVar[int]
    IS_ACTIVE_FIELD_NUMBER: _ClassVar[int]
    CIRCLE__RADIUS_FIELD_NUMBER: _ClassVar[int]
    CAPSULE__RADIUS_FIELD_NUMBER: _ClassVar[int]
    CAPSULE__SPREAD_FIELD_NUMBER: _ClassVar[int]
    CAPSULE__ROTATION_FIELD_NUMBER: _ClassVar[int]
    POLYGON__DIST_MIN_FIELD_NUMBER: _ClassVar[int]
    POLYGON__DIST_MAX_FIELD_NUMBER: _ClassVar[int]
    POLYGON__ROTATION_FIELD_NUMBER: _ClassVar[int]
    POLYGON__SPREAD_ANGLE_FIELD_NUMBER: _ClassVar[int]
    id: int
    type: int
    debug_name: str
    tr: GV2
    is_active: bool
    circle__radius: float
    capsule__radius: float
    capsule__spread: float
    capsule__rotation: float
    polygon__dist_min: float
    polygon__dist_max: float
    polygon__rotation: float
    polygon__spread_angle: float
    def __init__(self, id: _Optional[int] = ..., type: _Optional[int] = ..., debug_name: _Optional[str] = ..., tr: _Optional[_Union[GV2, _Mapping]] = ..., is_active: _Optional[bool] = ..., circle__radius: _Optional[float] = ..., capsule__radius: _Optional[float] = ..., capsule__spread: _Optional[float] = ..., capsule__rotation: _Optional[float] = ..., polygon__dist_min: _Optional[float] = ..., polygon__dist_max: _Optional[float] = ..., polygon__rotation: _Optional[float] = ..., polygon__spread_angle: _Optional[float] = ...) -> None: ...

class GColliderAnimated(_message.Message):
    __slots__ = ("id", "type", "debug_name", "tr", "is_active", "circle__radius", "capsule__radius", "capsule__spread", "capsule__rotation", "polygon__dist_min", "polygon__dist_max", "polygon__rotation", "polygon__spread_angle")
    ID_FIELD_NUMBER: _ClassVar[int]
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    TR_FIELD_NUMBER: _ClassVar[int]
    IS_ACTIVE_FIELD_NUMBER: _ClassVar[int]
    CIRCLE__RADIUS_FIELD_NUMBER: _ClassVar[int]
    CAPSULE__RADIUS_FIELD_NUMBER: _ClassVar[int]
    CAPSULE__SPREAD_FIELD_NUMBER: _ClassVar[int]
    CAPSULE__ROTATION_FIELD_NUMBER: _ClassVar[int]
    POLYGON__DIST_MIN_FIELD_NUMBER: _ClassVar[int]
    POLYGON__DIST_MAX_FIELD_NUMBER: _ClassVar[int]
    POLYGON__ROTATION_FIELD_NUMBER: _ClassVar[int]
    POLYGON__SPREAD_ANGLE_FIELD_NUMBER: _ClassVar[int]
    id: int
    type: int
    debug_name: str
    tr: _containers.RepeatedCompositeFieldContainer[GKeyframeV2]
    is_active: _containers.RepeatedCompositeFieldContainer[GKeyframeBool]
    circle__radius: _containers.RepeatedCompositeFieldContainer[GKeyframeFloat]
    capsule__radius: _containers.RepeatedCompositeFieldContainer[GKeyframeFloat]
    capsule__spread: _containers.RepeatedCompositeFieldContainer[GKeyframeFloat]
    capsule__rotation: _containers.RepeatedCompositeFieldContainer[GKeyframeFloat]
    polygon__dist_min: _containers.RepeatedCompositeFieldContainer[GKeyframeFloat]
    polygon__dist_max: _containers.RepeatedCompositeFieldContainer[GKeyframeFloat]
    polygon__rotation: _containers.RepeatedCompositeFieldContainer[GKeyframeFloat]
    polygon__spread_angle: _containers.RepeatedCompositeFieldContainer[GKeyframeFloat]
    def __init__(self, id: _Optional[int] = ..., type: _Optional[int] = ..., debug_name: _Optional[str] = ..., tr: _Optional[_Iterable[_Union[GKeyframeV2, _Mapping]]] = ..., is_active: _Optional[_Iterable[_Union[GKeyframeBool, _Mapping]]] = ..., circle__radius: _Optional[_Iterable[_Union[GKeyframeFloat, _Mapping]]] = ..., capsule__radius: _Optional[_Iterable[_Union[GKeyframeFloat, _Mapping]]] = ..., capsule__spread: _Optional[_Iterable[_Union[GKeyframeFloat, _Mapping]]] = ..., capsule__rotation: _Optional[_Iterable[_Union[GKeyframeFloat, _Mapping]]] = ..., polygon__dist_min: _Optional[_Iterable[_Union[GKeyframeFloat, _Mapping]]] = ..., polygon__dist_max: _Optional[_Iterable[_Union[GKeyframeFloat, _Mapping]]] = ..., polygon__rotation: _Optional[_Iterable[_Union[GKeyframeFloat, _Mapping]]] = ..., polygon__spread_angle: _Optional[_Iterable[_Union[GKeyframeFloat, _Mapping]]] = ...) -> None: ...

class GAttackMelee(_message.Message):
    __slots__ = ("damage", "damage_stamina", "evade_flags", "colliders", "hp_rally_recover")
    DAMAGE_FIELD_NUMBER: _ClassVar[int]
    DAMAGE_STAMINA_FIELD_NUMBER: _ClassVar[int]
    EVADE_FLAGS_FIELD_NUMBER: _ClassVar[int]
    COLLIDERS_FIELD_NUMBER: _ClassVar[int]
    HP_RALLY_RECOVER_FIELD_NUMBER: _ClassVar[int]
    damage: int
    damage_stamina: GStaminaCost
    evade_flags: int
    colliders: _containers.RepeatedCompositeFieldContainer[GColliderAnimated]
    hp_rally_recover: int
    def __init__(self, damage: _Optional[int] = ..., damage_stamina: _Optional[_Union[GStaminaCost, _Mapping]] = ..., evade_flags: _Optional[int] = ..., colliders: _Optional[_Iterable[_Union[GColliderAnimated, _Mapping]]] = ..., hp_rally_recover: _Optional[int] = ...) -> None: ...

class GStaminaCost(_message.Message):
    __slots__ = ("flat", "rally_discard_mult_pre", "rally", "rally_discard_mult_post")
    FLAT_FIELD_NUMBER: _ClassVar[int]
    RALLY_DISCARD_MULT_PRE_FIELD_NUMBER: _ClassVar[int]
    RALLY_FIELD_NUMBER: _ClassVar[int]
    RALLY_DISCARD_MULT_POST_FIELD_NUMBER: _ClassVar[int]
    flat: float
    rally_discard_mult_pre: float
    rally: float
    rally_discard_mult_post: float
    def __init__(self, flat: _Optional[float] = ..., rally_discard_mult_pre: _Optional[float] = ..., rally: _Optional[float] = ..., rally_discard_mult_post: _Optional[float] = ...) -> None: ...

class GProjectileSpawn(_message.Message):
    __slots__ = ("at", "angle")
    AT_FIELD_NUMBER: _ClassVar[int]
    ANGLE_FIELD_NUMBER: _ClassVar[int]
    at: int
    angle: float
    def __init__(self, at: _Optional[int] = ..., angle: _Optional[float] = ...) -> None: ...

class GImpulseData(_message.Message):
    __slots__ = ("id", "at", "distance", "dur", "pow", "rotation")
    ID_FIELD_NUMBER: _ClassVar[int]
    AT_FIELD_NUMBER: _ClassVar[int]
    DISTANCE_FIELD_NUMBER: _ClassVar[int]
    DUR_FIELD_NUMBER: _ClassVar[int]
    POW_FIELD_NUMBER: _ClassVar[int]
    ROTATION_FIELD_NUMBER: _ClassVar[int]
    id: int
    at: int
    distance: float
    dur: int
    pow: float
    rotation: float
    def __init__(self, id: _Optional[int] = ..., at: _Optional[int] = ..., distance: _Optional[float] = ..., dur: _Optional[int] = ..., pow: _Optional[float] = ..., rotation: _Optional[float] = ...) -> None: ...

class GAttack(_message.Message):
    __slots__ = ("debug_name", "debug_mirrored", "duration_frames", "stamina_consumption_frame", "cooldown_min", "cooldown_max", "movement_scale", "stamina_cost", "stops_tracking_at", "projectile_type", "projectile_spawns", "melee", "tags", "impulses", "conditions")
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    DEBUG_MIRRORED_FIELD_NUMBER: _ClassVar[int]
    DURATION_FRAMES_FIELD_NUMBER: _ClassVar[int]
    STAMINA_CONSUMPTION_FRAME_FIELD_NUMBER: _ClassVar[int]
    COOLDOWN_MIN_FIELD_NUMBER: _ClassVar[int]
    COOLDOWN_MAX_FIELD_NUMBER: _ClassVar[int]
    MOVEMENT_SCALE_FIELD_NUMBER: _ClassVar[int]
    STAMINA_COST_FIELD_NUMBER: _ClassVar[int]
    STOPS_TRACKING_AT_FIELD_NUMBER: _ClassVar[int]
    PROJECTILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    PROJECTILE_SPAWNS_FIELD_NUMBER: _ClassVar[int]
    MELEE_FIELD_NUMBER: _ClassVar[int]
    TAGS_FIELD_NUMBER: _ClassVar[int]
    IMPULSES_FIELD_NUMBER: _ClassVar[int]
    CONDITIONS_FIELD_NUMBER: _ClassVar[int]
    debug_name: str
    debug_mirrored: bool
    duration_frames: int
    stamina_consumption_frame: int
    cooldown_min: float
    cooldown_max: float
    movement_scale: float
    stamina_cost: GStaminaCost
    stops_tracking_at: float
    projectile_type: int
    projectile_spawns: _containers.RepeatedCompositeFieldContainer[GProjectileSpawn]
    melee: GAttackMelee
    tags: _containers.RepeatedCompositeFieldContainer[GTagValue]
    impulses: _containers.RepeatedCompositeFieldContainer[GImpulseData]
    conditions: _containers.RepeatedCompositeFieldContainer[GCollider]
    def __init__(self, debug_name: _Optional[str] = ..., debug_mirrored: _Optional[bool] = ..., duration_frames: _Optional[int] = ..., stamina_consumption_frame: _Optional[int] = ..., cooldown_min: _Optional[float] = ..., cooldown_max: _Optional[float] = ..., movement_scale: _Optional[float] = ..., stamina_cost: _Optional[_Union[GStaminaCost, _Mapping]] = ..., stops_tracking_at: _Optional[float] = ..., projectile_type: _Optional[int] = ..., projectile_spawns: _Optional[_Iterable[_Union[GProjectileSpawn, _Mapping]]] = ..., melee: _Optional[_Union[GAttackMelee, _Mapping]] = ..., tags: _Optional[_Iterable[_Union[GTagValue, _Mapping]]] = ..., impulses: _Optional[_Iterable[_Union[GImpulseData, _Mapping]]] = ..., conditions: _Optional[_Iterable[_Union[GCollider, _Mapping]]] = ...) -> None: ...

class GAbility(_message.Message):
    __slots__ = ("type", "debug_name", "attacks", "recovering_attacks")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    ATTACKS_FIELD_NUMBER: _ClassVar[int]
    RECOVERING_ATTACKS_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    attacks: _containers.RepeatedCompositeFieldContainer[GAttack]
    recovering_attacks: int
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ..., attacks: _Optional[_Iterable[_Union[GAttack, _Mapping]]] = ..., recovering_attacks: _Optional[int] = ...) -> None: ...

class GCreature(_message.Message):
    __slots__ = ("type", "debug_name", "res", "creature_type", "hp", "speed", "rotation_speed", "mass", "collider_size", "drops", "attacks", "ability_types")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    RES_FIELD_NUMBER: _ClassVar[int]
    CREATURE_TYPE_FIELD_NUMBER: _ClassVar[int]
    HP_FIELD_NUMBER: _ClassVar[int]
    SPEED_FIELD_NUMBER: _ClassVar[int]
    ROTATION_SPEED_FIELD_NUMBER: _ClassVar[int]
    MASS_FIELD_NUMBER: _ClassVar[int]
    COLLIDER_SIZE_FIELD_NUMBER: _ClassVar[int]
    DROPS_FIELD_NUMBER: _ClassVar[int]
    ATTACKS_FIELD_NUMBER: _ClassVar[int]
    ABILITY_TYPES_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    res: str
    creature_type: int
    hp: int
    speed: float
    rotation_speed: float
    mass: float
    collider_size: float
    drops: _containers.RepeatedCompositeFieldContainer[GCreatureDrop]
    attacks: _containers.RepeatedCompositeFieldContainer[GAttack]
    ability_types: _containers.RepeatedScalarFieldContainer[int]
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ..., res: _Optional[str] = ..., creature_type: _Optional[int] = ..., hp: _Optional[int] = ..., speed: _Optional[float] = ..., rotation_speed: _Optional[float] = ..., mass: _Optional[float] = ..., collider_size: _Optional[float] = ..., drops: _Optional[_Iterable[_Union[GCreatureDrop, _Mapping]]] = ..., attacks: _Optional[_Iterable[_Union[GAttack, _Mapping]]] = ..., ability_types: _Optional[_Iterable[int]] = ...) -> None: ...

class GDamage(_message.Message):
    __slots__ = ("type", "debug_name")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ...) -> None: ...

class GEvade(_message.Message):
    __slots__ = ("type", "debug_name")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ...) -> None: ...

class GTeam(_message.Message):
    __slots__ = ("type", "debug_name")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ...) -> None: ...

class GItem(_message.Message):
    __slots__ = ("type", "debug_name")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ...) -> None: ...

class GCollectible(_message.Message):
    __slots__ = ("type", "debug_name", "item_type")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    ITEM_TYPE_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    item_type: int
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ..., item_type: _Optional[int] = ...) -> None: ...

class GProjectileFly(_message.Message):
    __slots__ = ("type", "debug_name")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ...) -> None: ...

class GImpulse(_message.Message):
    __slots__ = ("type", "debug_name")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ...) -> None: ...

class GProjectile(_message.Message):
    __slots__ = ("type", "debug_name", "res", "damage", "damage_stamina", "hp_rally_recover", "impulse", "impulse_type", "evade_flags", "pierce", "collider_radius", "distance", "projectilefly_type", "arc__height", "arc_or_area__duration", "default__speed", "touch_team_flags", "tags")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    RES_FIELD_NUMBER: _ClassVar[int]
    DAMAGE_FIELD_NUMBER: _ClassVar[int]
    DAMAGE_STAMINA_FIELD_NUMBER: _ClassVar[int]
    HP_RALLY_RECOVER_FIELD_NUMBER: _ClassVar[int]
    IMPULSE_FIELD_NUMBER: _ClassVar[int]
    IMPULSE_TYPE_FIELD_NUMBER: _ClassVar[int]
    EVADE_FLAGS_FIELD_NUMBER: _ClassVar[int]
    PIERCE_FIELD_NUMBER: _ClassVar[int]
    COLLIDER_RADIUS_FIELD_NUMBER: _ClassVar[int]
    DISTANCE_FIELD_NUMBER: _ClassVar[int]
    PROJECTILEFLY_TYPE_FIELD_NUMBER: _ClassVar[int]
    ARC__HEIGHT_FIELD_NUMBER: _ClassVar[int]
    ARC_OR_AREA__DURATION_FIELD_NUMBER: _ClassVar[int]
    DEFAULT__SPEED_FIELD_NUMBER: _ClassVar[int]
    TOUCH_TEAM_FLAGS_FIELD_NUMBER: _ClassVar[int]
    TAGS_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    res: str
    damage: int
    damage_stamina: GStaminaCost
    hp_rally_recover: int
    impulse: float
    impulse_type: int
    evade_flags: int
    pierce: int
    collider_radius: float
    distance: float
    projectilefly_type: int
    arc__height: float
    arc_or_area__duration: float
    default__speed: float
    touch_team_flags: int
    tags: _containers.RepeatedCompositeFieldContainer[GTagValue]
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ..., res: _Optional[str] = ..., damage: _Optional[int] = ..., damage_stamina: _Optional[_Union[GStaminaCost, _Mapping]] = ..., hp_rally_recover: _Optional[int] = ..., impulse: _Optional[float] = ..., impulse_type: _Optional[int] = ..., evade_flags: _Optional[int] = ..., pierce: _Optional[int] = ..., collider_radius: _Optional[float] = ..., distance: _Optional[float] = ..., projectilefly_type: _Optional[int] = ..., arc__height: _Optional[float] = ..., arc_or_area__duration: _Optional[float] = ..., default__speed: _Optional[float] = ..., touch_team_flags: _Optional[int] = ..., tags: _Optional[_Iterable[_Union[GTagValue, _Mapping]]] = ...) -> None: ...

class GInteractable(_message.Message):
    __slots__ = ("type", "debug_name", "res", "hp", "projectile_type", "mass")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    RES_FIELD_NUMBER: _ClassVar[int]
    HP_FIELD_NUMBER: _ClassVar[int]
    PROJECTILE_TYPE_FIELD_NUMBER: _ClassVar[int]
    MASS_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    res: str
    hp: int
    projectile_type: int
    mass: float
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ..., res: _Optional[str] = ..., hp: _Optional[int] = ..., projectile_type: _Optional[int] = ..., mass: _Optional[float] = ...) -> None: ...

class GMask(_message.Message):
    __slots__ = ("type", "debug_name")
    TYPE_FIELD_NUMBER: _ClassVar[int]
    DEBUG_NAME_FIELD_NUMBER: _ClassVar[int]
    type: int
    debug_name: str
    def __init__(self, type: _Optional[int] = ..., debug_name: _Optional[str] = ...) -> None: ...

class GConfigControls(_message.Message):
    __slots__ = ("action_consumption_duration",)
    ACTION_CONSUMPTION_DURATION_FIELD_NUMBER: _ClassVar[int]
    action_consumption_duration: float
    def __init__(self, action_consumption_duration: _Optional[float] = ...) -> None: ...

class GConfigSpikes(_message.Message):
    __slots__ = ("duration_seconds", "damage_starts_at", "damage", "initial_evade_flags", "continuous_evade_flags")
    DURATION_SECONDS_FIELD_NUMBER: _ClassVar[int]
    DAMAGE_STARTS_AT_FIELD_NUMBER: _ClassVar[int]
    DAMAGE_FIELD_NUMBER: _ClassVar[int]
    INITIAL_EVADE_FLAGS_FIELD_NUMBER: _ClassVar[int]
    CONTINUOUS_EVADE_FLAGS_FIELD_NUMBER: _ClassVar[int]
    duration_seconds: float
    damage_starts_at: float
    damage: int
    initial_evade_flags: int
    continuous_evade_flags: int
    def __init__(self, duration_seconds: _Optional[float] = ..., damage_starts_at: _Optional[float] = ..., damage: _Optional[int] = ..., initial_evade_flags: _Optional[int] = ..., continuous_evade_flags: _Optional[int] = ...) -> None: ...

class GConfigPlayer(_message.Message):
    __slots__ = ("speed_scale__shooting", "speed_scale__blocking", "speed_scale__inside_enemies", "roll_distance", "roll_pow", "roll_invincibility_start", "roll_invincibility_end", "roll_duration_seconds", "roll_control_return_starts_at", "stamina", "stamina_regen_per_second", "roll_stamina_cost", "dodge_stamina_retrieve_percent", "stamina_rally_decay_after", "stamina_rally_decay_per_second", "stamina_attack_cost", "stamina_attack_rally_scale", "stamina_roll_rally_scale", "stamina_regen_on_kill", "stamina_ki_decay_after", "stamina_ki_decay_speed", "stamina_regen_scale__blocking", "stamina_regen_scale__shooting", "block__activation_start", "ki__rally_increase_per_second", "block__min_duration", "block__idle_after_block", "cooldown__block", "cooldown__roll", "block__perfect_end", "stamina_depletion_regen_delay", "invincibility_after_hit_seconds")
    SPEED_SCALE__SHOOTING_FIELD_NUMBER: _ClassVar[int]
    SPEED_SCALE__BLOCKING_FIELD_NUMBER: _ClassVar[int]
    SPEED_SCALE__INSIDE_ENEMIES_FIELD_NUMBER: _ClassVar[int]
    ROLL_DISTANCE_FIELD_NUMBER: _ClassVar[int]
    ROLL_POW_FIELD_NUMBER: _ClassVar[int]
    ROLL_INVINCIBILITY_START_FIELD_NUMBER: _ClassVar[int]
    ROLL_INVINCIBILITY_END_FIELD_NUMBER: _ClassVar[int]
    ROLL_DURATION_SECONDS_FIELD_NUMBER: _ClassVar[int]
    ROLL_CONTROL_RETURN_STARTS_AT_FIELD_NUMBER: _ClassVar[int]
    STAMINA_FIELD_NUMBER: _ClassVar[int]
    STAMINA_REGEN_PER_SECOND_FIELD_NUMBER: _ClassVar[int]
    ROLL_STAMINA_COST_FIELD_NUMBER: _ClassVar[int]
    DODGE_STAMINA_RETRIEVE_PERCENT_FIELD_NUMBER: _ClassVar[int]
    STAMINA_RALLY_DECAY_AFTER_FIELD_NUMBER: _ClassVar[int]
    STAMINA_RALLY_DECAY_PER_SECOND_FIELD_NUMBER: _ClassVar[int]
    STAMINA_ATTACK_COST_FIELD_NUMBER: _ClassVar[int]
    STAMINA_ATTACK_RALLY_SCALE_FIELD_NUMBER: _ClassVar[int]
    STAMINA_ROLL_RALLY_SCALE_FIELD_NUMBER: _ClassVar[int]
    STAMINA_REGEN_ON_KILL_FIELD_NUMBER: _ClassVar[int]
    STAMINA_KI_DECAY_AFTER_FIELD_NUMBER: _ClassVar[int]
    STAMINA_KI_DECAY_SPEED_FIELD_NUMBER: _ClassVar[int]
    STAMINA_REGEN_SCALE__BLOCKING_FIELD_NUMBER: _ClassVar[int]
    STAMINA_REGEN_SCALE__SHOOTING_FIELD_NUMBER: _ClassVar[int]
    BLOCK__ACTIVATION_START_FIELD_NUMBER: _ClassVar[int]
    KI__RALLY_INCREASE_PER_SECOND_FIELD_NUMBER: _ClassVar[int]
    BLOCK__MIN_DURATION_FIELD_NUMBER: _ClassVar[int]
    BLOCK__IDLE_AFTER_BLOCK_FIELD_NUMBER: _ClassVar[int]
    COOLDOWN__BLOCK_FIELD_NUMBER: _ClassVar[int]
    COOLDOWN__ROLL_FIELD_NUMBER: _ClassVar[int]
    BLOCK__PERFECT_END_FIELD_NUMBER: _ClassVar[int]
    STAMINA_DEPLETION_REGEN_DELAY_FIELD_NUMBER: _ClassVar[int]
    INVINCIBILITY_AFTER_HIT_SECONDS_FIELD_NUMBER: _ClassVar[int]
    speed_scale__shooting: float
    speed_scale__blocking: float
    speed_scale__inside_enemies: float
    roll_distance: float
    roll_pow: float
    roll_invincibility_start: float
    roll_invincibility_end: float
    roll_duration_seconds: float
    roll_control_return_starts_at: float
    stamina: float
    stamina_regen_per_second: float
    roll_stamina_cost: GStaminaCost
    dodge_stamina_retrieve_percent: float
    stamina_rally_decay_after: float
    stamina_rally_decay_per_second: float
    stamina_attack_cost: float
    stamina_attack_rally_scale: float
    stamina_roll_rally_scale: float
    stamina_regen_on_kill: float
    stamina_ki_decay_after: float
    stamina_ki_decay_speed: float
    stamina_regen_scale__blocking: float
    stamina_regen_scale__shooting: float
    block__activation_start: float
    ki__rally_increase_per_second: float
    block__min_duration: float
    block__idle_after_block: float
    cooldown__block: float
    cooldown__roll: float
    block__perfect_end: float
    stamina_depletion_regen_delay: float
    invincibility_after_hit_seconds: float
    def __init__(self, speed_scale__shooting: _Optional[float] = ..., speed_scale__blocking: _Optional[float] = ..., speed_scale__inside_enemies: _Optional[float] = ..., roll_distance: _Optional[float] = ..., roll_pow: _Optional[float] = ..., roll_invincibility_start: _Optional[float] = ..., roll_invincibility_end: _Optional[float] = ..., roll_duration_seconds: _Optional[float] = ..., roll_control_return_starts_at: _Optional[float] = ..., stamina: _Optional[float] = ..., stamina_regen_per_second: _Optional[float] = ..., roll_stamina_cost: _Optional[_Union[GStaminaCost, _Mapping]] = ..., dodge_stamina_retrieve_percent: _Optional[float] = ..., stamina_rally_decay_after: _Optional[float] = ..., stamina_rally_decay_per_second: _Optional[float] = ..., stamina_attack_cost: _Optional[float] = ..., stamina_attack_rally_scale: _Optional[float] = ..., stamina_roll_rally_scale: _Optional[float] = ..., stamina_regen_on_kill: _Optional[float] = ..., stamina_ki_decay_after: _Optional[float] = ..., stamina_ki_decay_speed: _Optional[float] = ..., stamina_regen_scale__blocking: _Optional[float] = ..., stamina_regen_scale__shooting: _Optional[float] = ..., block__activation_start: _Optional[float] = ..., ki__rally_increase_per_second: _Optional[float] = ..., block__min_duration: _Optional[float] = ..., block__idle_after_block: _Optional[float] = ..., cooldown__block: _Optional[float] = ..., cooldown__roll: _Optional[float] = ..., block__perfect_end: _Optional[float] = ..., stamina_depletion_regen_delay: _Optional[float] = ..., invincibility_after_hit_seconds: _Optional[float] = ...) -> None: ...

class Lib(_message.Message):
    __slots__ = ("controls", "player", "spikes", "debug_collisions", "debug_collisions__chase", "hp_damage_rally_percent", "hp_rally_decays_after", "hp_rally_decay_speed", "rooms", "mob_invincibility_spikes_seconds", "blocked_attack_damages_again_after", "creatures_push_radius", "creatures_push_force", "mob_arc_throw_distance_delta", "default_impulse_duration_seconds", "default_impulse_pow", "impulse_block_scale", "world_size", "progression_size", "damages", "evades", "teams", "progression", "abilities", "creatures", "items", "collectibles", "projectile_fly_types", "projectiles", "interactables", "masks", "tags", "impulses")
    CONTROLS_FIELD_NUMBER: _ClassVar[int]
    PLAYER_FIELD_NUMBER: _ClassVar[int]
    SPIKES_FIELD_NUMBER: _ClassVar[int]
    DEBUG_COLLISIONS_FIELD_NUMBER: _ClassVar[int]
    DEBUG_COLLISIONS__CHASE_FIELD_NUMBER: _ClassVar[int]
    HP_DAMAGE_RALLY_PERCENT_FIELD_NUMBER: _ClassVar[int]
    HP_RALLY_DECAYS_AFTER_FIELD_NUMBER: _ClassVar[int]
    HP_RALLY_DECAY_SPEED_FIELD_NUMBER: _ClassVar[int]
    ROOMS_FIELD_NUMBER: _ClassVar[int]
    MOB_INVINCIBILITY_SPIKES_SECONDS_FIELD_NUMBER: _ClassVar[int]
    BLOCKED_ATTACK_DAMAGES_AGAIN_AFTER_FIELD_NUMBER: _ClassVar[int]
    CREATURES_PUSH_RADIUS_FIELD_NUMBER: _ClassVar[int]
    CREATURES_PUSH_FORCE_FIELD_NUMBER: _ClassVar[int]
    MOB_ARC_THROW_DISTANCE_DELTA_FIELD_NUMBER: _ClassVar[int]
    DEFAULT_IMPULSE_DURATION_SECONDS_FIELD_NUMBER: _ClassVar[int]
    DEFAULT_IMPULSE_POW_FIELD_NUMBER: _ClassVar[int]
    IMPULSE_BLOCK_SCALE_FIELD_NUMBER: _ClassVar[int]
    WORLD_SIZE_FIELD_NUMBER: _ClassVar[int]
    PROGRESSION_SIZE_FIELD_NUMBER: _ClassVar[int]
    DAMAGES_FIELD_NUMBER: _ClassVar[int]
    EVADES_FIELD_NUMBER: _ClassVar[int]
    TEAMS_FIELD_NUMBER: _ClassVar[int]
    PROGRESSION_FIELD_NUMBER: _ClassVar[int]
    ABILITIES_FIELD_NUMBER: _ClassVar[int]
    CREATURES_FIELD_NUMBER: _ClassVar[int]
    ITEMS_FIELD_NUMBER: _ClassVar[int]
    COLLECTIBLES_FIELD_NUMBER: _ClassVar[int]
    PROJECTILE_FLY_TYPES_FIELD_NUMBER: _ClassVar[int]
    PROJECTILES_FIELD_NUMBER: _ClassVar[int]
    INTERACTABLES_FIELD_NUMBER: _ClassVar[int]
    MASKS_FIELD_NUMBER: _ClassVar[int]
    TAGS_FIELD_NUMBER: _ClassVar[int]
    IMPULSES_FIELD_NUMBER: _ClassVar[int]
    controls: GConfigControls
    player: GConfigPlayer
    spikes: GConfigSpikes
    debug_collisions: int
    debug_collisions__chase: int
    hp_damage_rally_percent: float
    hp_rally_decays_after: float
    hp_rally_decay_speed: float
    rooms: _containers.RepeatedCompositeFieldContainer[GRoom]
    mob_invincibility_spikes_seconds: float
    blocked_attack_damages_again_after: float
    creatures_push_radius: float
    creatures_push_force: float
    mob_arc_throw_distance_delta: float
    default_impulse_duration_seconds: float
    default_impulse_pow: float
    impulse_block_scale: float
    world_size: GV2i
    progression_size: GV2i
    damages: _containers.RepeatedCompositeFieldContainer[GDamage]
    evades: _containers.RepeatedCompositeFieldContainer[GEvade]
    teams: _containers.RepeatedCompositeFieldContainer[GTeam]
    progression: _containers.RepeatedCompositeFieldContainer[GProgression]
    abilities: _containers.RepeatedCompositeFieldContainer[GAbility]
    creatures: _containers.RepeatedCompositeFieldContainer[GCreature]
    items: _containers.RepeatedCompositeFieldContainer[GItem]
    collectibles: _containers.RepeatedCompositeFieldContainer[GCollectible]
    projectile_fly_types: _containers.RepeatedCompositeFieldContainer[GProjectileFly]
    projectiles: _containers.RepeatedCompositeFieldContainer[GProjectile]
    interactables: _containers.RepeatedCompositeFieldContainer[GInteractable]
    masks: _containers.RepeatedCompositeFieldContainer[GMask]
    tags: _containers.RepeatedCompositeFieldContainer[GTag]
    impulses: _containers.RepeatedCompositeFieldContainer[GImpulse]
    def __init__(self, controls: _Optional[_Union[GConfigControls, _Mapping]] = ..., player: _Optional[_Union[GConfigPlayer, _Mapping]] = ..., spikes: _Optional[_Union[GConfigSpikes, _Mapping]] = ..., debug_collisions: _Optional[int] = ..., debug_collisions__chase: _Optional[int] = ..., hp_damage_rally_percent: _Optional[float] = ..., hp_rally_decays_after: _Optional[float] = ..., hp_rally_decay_speed: _Optional[float] = ..., rooms: _Optional[_Iterable[_Union[GRoom, _Mapping]]] = ..., mob_invincibility_spikes_seconds: _Optional[float] = ..., blocked_attack_damages_again_after: _Optional[float] = ..., creatures_push_radius: _Optional[float] = ..., creatures_push_force: _Optional[float] = ..., mob_arc_throw_distance_delta: _Optional[float] = ..., default_impulse_duration_seconds: _Optional[float] = ..., default_impulse_pow: _Optional[float] = ..., impulse_block_scale: _Optional[float] = ..., world_size: _Optional[_Union[GV2i, _Mapping]] = ..., progression_size: _Optional[_Union[GV2i, _Mapping]] = ..., damages: _Optional[_Iterable[_Union[GDamage, _Mapping]]] = ..., evades: _Optional[_Iterable[_Union[GEvade, _Mapping]]] = ..., teams: _Optional[_Iterable[_Union[GTeam, _Mapping]]] = ..., progression: _Optional[_Iterable[_Union[GProgression, _Mapping]]] = ..., abilities: _Optional[_Iterable[_Union[GAbility, _Mapping]]] = ..., creatures: _Optional[_Iterable[_Union[GCreature, _Mapping]]] = ..., items: _Optional[_Iterable[_Union[GItem, _Mapping]]] = ..., collectibles: _Optional[_Iterable[_Union[GCollectible, _Mapping]]] = ..., projectile_fly_types: _Optional[_Iterable[_Union[GProjectileFly, _Mapping]]] = ..., projectiles: _Optional[_Iterable[_Union[GProjectile, _Mapping]]] = ..., interactables: _Optional[_Iterable[_Union[GInteractable, _Mapping]]] = ..., masks: _Optional[_Iterable[_Union[GMask, _Mapping]]] = ..., tags: _Optional[_Iterable[_Union[GTag, _Mapping]]] = ..., impulses: _Optional[_Iterable[_Union[GImpulse, _Mapping]]] = ...) -> None: ...
