# Patterns: Audio Management & Visual Juice

How to manage sound, add screen shake, hit flash, bounce effects, and make the game feel satisfying.

All examples target **Godot 4.6** with static typing.

---

## Audio Manager

**When to use:** Any game with sound. Centralizes audio playback and bus management.

**Setup:** In Godot, create audio buses: Master → Music, SFX, UI. This lets players control volumes independently. Add an `AudioStreamPlayer` child named `MusicPlayer` to this autoload scene.

```gdscript
# Autoload: AudioManager.gd
extends Node

const MAX_SIMULTANEOUS_SFX: int = 8

var _sfx_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
    for i: int in MAX_SIMULTANEOUS_SFX:
        var player := AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        _sfx_players.append(player)

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
    for player: AudioStreamPlayer in _sfx_players:
        if not player.playing:
            player.stream = stream
            player.volume_db = volume_db
            player.play()
            return
    # All players busy — skip this sound (or interrupt oldest)

func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
    var player := $MusicPlayer as AudioStreamPlayer
    if player.playing:
        var tween := create_tween()
        tween.tween_property(player, "volume_db", -40.0, fade_duration)
        await tween.finished
    player.stream = stream
    player.volume_db = -40.0
    player.play()
    var fade_in := create_tween()
    fade_in.tween_property(player, "volume_db", 0.0, fade_duration)

func set_bus_volume(bus_name: String, linear: float) -> void:
    var bus_idx := AudioServer.get_bus_index(bus_name)
    if bus_idx >= 0:
        AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear))
```

**Common mistakes:**
- Playing too many simultaneous sounds (causes clipping — use the pool limit)
- Not using audio buses (makes volume controls impossible to implement)
- Using `preload` for large music files (use `load` or `ResourceLoader` at runtime)

---

## Tween Patterns (Visual Juice)

**When to use:** Screen shake, hit flash, UI transitions, bounce effects, pickup animations — smooth interpolation without `AnimationPlayer` overhead.

```gdscript
# Hit flash — briefly tint a sprite
func flash_white(sprite: CanvasItem, duration: float = 0.1) -> void:
    sprite.modulate = Color(10, 10, 10)  # Bright flash
    var tween := create_tween()
    tween.tween_property(sprite, "modulate", Color.WHITE, duration)

# Bounce scale on pickup/hit
func bounce(node: Node2D, amount: float = 1.3, duration: float = 0.2) -> void:
    var tween := create_tween()
    tween.tween_property(node, "scale", Vector2.ONE * amount, duration * 0.4) \
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    tween.tween_property(node, "scale", Vector2.ONE, duration * 0.6) \
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

# Screen shake (attach to Camera2D)
func shake(camera: Camera2D, intensity: float = 5.0, duration: float = 0.3) -> void:
    var original_offset := camera.offset
    var tween := create_tween()
    for i: int in 6:
        var rand_offset := Vector2(
            randf_range(-intensity, intensity),
            randf_range(-intensity, intensity)
        )
        tween.tween_property(camera, "offset", original_offset + rand_offset, duration / 6.0)
    tween.tween_property(camera, "offset", original_offset, duration / 6.0)

# Smooth UI element slide-in
func slide_in(control: Control, from_offset: Vector2, duration: float = 0.4) -> void:
    var target_pos := control.position
    control.position = target_pos + from_offset
    control.modulate.a = 0.0
    var tween := create_tween().set_parallel(true)
    tween.tween_property(control, "position", target_pos, duration) \
        .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(control, "modulate:a", 1.0, duration * 0.6)
```

**Key rules:**
- Always use `create_tween()` (bound to the node — auto-freed when node exits tree)
- Kill previous tweens before starting new ones on the same property to avoid conflicts
- `TRANS_BACK` and `TRANS_ELASTIC` feel great for game juice
- For authored, timeline-based animation, use `AnimationPlayer` instead (see TOOLING.md editor workflow section)
