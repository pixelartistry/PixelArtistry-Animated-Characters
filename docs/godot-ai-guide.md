# Make your ActionForge character playable in Godot: AI helper guide

> **How to use this file**
>
> 1. Paste this whole file into Claude (or another AI assistant), or attach it.
> 2. Write: *"Help me set up my character in Godot, step by step."*
> 3. Answer its questions, and send screenshots of your Scene tree and of any
>    errors when it asks for them.
>
> From the PixelArtistry video *This New Local AI Character Workflow Is INSANE
> (Fully Animated!)*. ComfyUI workflows and installer:
> <https://github.com/pixelartistry/PixelArtistry-Animated-Characters>

---

## Part A: Instructions for the AI assistant

You are helping a viewer turn a rigged, animated character from
[ActionForge](https://actionforge.app) (a GLB file) into a playable
third-person character in Godot 4. The finished character runs, jumps, does
three sword attacks that move him with the clip's own lunge (root motion), and
hits training dummies that count the hits. Everything in Parts B and C was
tested in October 2026 on **Godot 4.7** (Forward+, Jolt Physics) with a 1.8 m
character and nine ActionForge clips. Treat it as the working reference.

How to guide the viewer:

1. **Ask first.** Ask for their Godot version, which clips they exported and
   whether all clips are in one GLB, whether the character holds a weapon or
   other prop, and roughly how tall the character is (the values below assume
   1.8 m).
2. **One stage at a time.** Give the actions of one stage, about six at most,
   then wait until they confirm it works or send a screenshot. Do not paste the
   whole guide at once.
3. **Use the exact names.** Node names are case-sensitive. The script needs
   `Model`, `Model/AnimationPlayer`, `%Hitbox`, `CameraPivot` and
   `CameraPivot/SpringArm3D`. Compare their Scene tree screenshot with the
   target tree in Stage 2 before moving on.
4. **Never guess clip names.** Before Stage 3, ask them for the exact clip
   names (Stage 1.3) and fill in the constants at the top of `player.gd` with
   exactly those names. With fewer or different attack clips, adapt `ATTACKS`
   (see "Adapting to other characters and clips").
5. **Give complete code.** Hand over the full adjusted `player.gd` from Part C
   in one block they can paste. Do not ask beginners to type or merge code.
6. **When something fails,** ask for the first red line in the **Debugger**
   tab at the bottom of the editor and use the Troubleshooting table. Fix one
   cause at a time.
7. **Other Godot versions.** Menu and property names are from 4.7. If
   something is not where this guide says, help them find the equivalent in
   their version instead of changing the approach.
8. Keep explanations short and plain. Explain *why* only where it prevents a
   mistake.

### What the finished setup does

- **WASD** moves relative to the camera, the **mouse** orbits the camera,
  **Space** jumps.
- **Left mouse button** attacks, **right mouse button** does a heavy attack,
  **Q** does a three-hit combo. Each attack only hurts during the fast part of
  the swing.
- **Esc** frees the mouse, a click captures it again.
- No Input Map setup is needed: the script creates its input actions when the
  game starts.

---

## Part B: The steps

### Stage 0: Export from ActionForge

- Rig the character (ActionForge has an auto-rig for unrigged models). Tag a
  held weapon as a **prop** so it follows the hand.
- Pick the clips: an idle, a run loop, jump start, jump loop, jump land, and up
  to three attacks.
- Export as **GLB** with the character mesh included, all clips in **one
  file**, and **In place off**. The attacks need their forward movement for
  root motion. (Option names as of October 2026; they may change.)
- The tested export was one ActionForge bundle with nine clips:
  `sword_idle_fit`, `jog_fwd_loop_fit`, `jump_start_fit`, `jump_loop_fit`,
  `jump_land_fit`, `sword_attack_fit`, `sword_regular_a_fit`,
  `sword_regular_c_fit`, `sword_regular_combo_fit`.

### Stage 1: Project and import

| # | Do | Details |
| --- | --- | --- |
| 1.1 | Project Manager → **Create** | Renderer **Forward+** |
| 1.2 | In the FileSystem dock, make a folder `character` and drag the GLB into it | The import takes a moment with 2K textures |
| 1.3 | Double-click the GLB → **Advanced Import Settings** → look at the animation list | Write down the exact clip names. If a name **ends** in `_loop`, Godot removes that ending (`jog_fwd_loop` becomes `jog_fwd`). Names ending in `_fit` stay as they are. Nothing to change here: the script turns on looping itself. |

### Stage 2: Player scene (`player.tscn`)

Target tree:

```
Player (CharacterBody3D, player.gd)
├── CollisionShape3D           CapsuleShape3D radius 0.35, height 1.8, position Y 0.9
├── Model                      the GLB, dragged in and renamed
│   └── Hitbox (Area3D)        Access as Unique Name (%), position (0, 1, 1), Layer 4 only, Mask 2 only
│       └── CollisionShape3D   BoxShape3D size (1.7, 1.4, 1.6)
└── CameraPivot (Node3D)       position Y 1.5
    └── SpringArm3D            Spring Length 4, Margin 0.2
        └── Camera3D           FOV 65
```

| # | Do | Details |
| --- | --- | --- |
| 2.1 | **Scene → New Scene** → Other Node → **CharacterBody3D**, rename it `Player` | This is the root |
| 2.2 | Add Child → **CollisionShape3D** | Shape: New **CapsuleShape3D**, radius `0.35`, height `1.8`. Position Y `0.9` |
| 2.3 | Drag the GLB from the FileSystem dock onto `Player`, rename it **`Model`** | The character stands on the origin and faces +Z |
| 2.4 | Right-click `Model` → Add Child Node → **Area3D**, rename it **`Hitbox`**, right-click it → **Access as Unique Name** | A `%` appears next to it. Position `(0, 1, 1)`, in front of the chest. Collision: Layer **4 only**, Mask **2 only** |
| 2.5 | Right-click `Hitbox` → Add Child Node → **CollisionShape3D** | Shape: New **BoxShape3D**, size `(1.7, 1.4, 1.6)`. This box is the weapon's reach. It must be Hitbox's **first** child. The ⚠ on Hitbox disappears |
| 2.6 | Add a **Node3D** under `Player`, rename it **`CameraPivot`** | Position Y `1.5` |
| 2.7 | Add a **SpringArm3D** under `CameraPivot` | Spring Length `4`, Margin `0.2` |
| 2.8 | Add a **Camera3D** under `SpringArm3D` | FOV `65`. Leave its position at 0; the script tilts the camera |
| 2.9 | **Ctrl+S** → save as `player.tscn` in `res://` | |

Two slips happened in the tested setup and are easy to spot in a screenshot:
the Area3D ended up *inside* a CollisionShape3D (it must be the other way
round), and the camera chain was upside down (Camera3D → SpringArm3D →
pivot). The order must be CameraPivot → SpringArm3D → Camera3D.

**Other character heights.** For a character H metres tall: capsule height
about H, radius about 0.2 × H, capsule position Y = H / 2, CameraPivot Y about
0.83 × H, Hitbox Y about 0.55 × H. Size the Hitbox box to the weapon's reach.

### Stage 3: The script (`player.gd`)

| # | Do | Details |
| --- | --- | --- |
| 3.1 | Select `Player` → **Attach Script** (scroll icon at the top of the Scene dock) | Path `res://player.gd` → Create |
| 3.2 | Replace everything in the editor with `player.gd` from Part C, with the clip names filled in | **Ctrl+S** |

What the parts of the script do, in one line each:

- **Clip names at the top:** must match the AnimationPlayer exactly.
- **`ATTACKS`:** each attack only hurts inside its hit windows (seconds into
  the clip), measured from the fastest part of the swing.
- **`_ready`:** sets looping, picks the root bone's position track for root
  motion, and runs the animation on **physics ticks**
  (`ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS`). Without that line the attack
  lunge comes out about 60 % short, because animation and physics run on
  different clocks.
- **`_move_step`:** movement relative to the camera; turns the model toward the
  movement direction (glTF characters face +Z).
- **`_attack_step`:** turns root motion into velocity so the lunge really moves
  the body, then checks for hits.
- **`_bodies_in_hitbox`:** a direct shape query with the Hitbox's box. With
  Jolt, an Area3D does not notice static bodies such as the dummies; the query
  does.

### Stage 4: Quick test on a plain floor (`test.tscn`)

Running `player.tscn` on its own does not work: there is no floor (he falls
forever) and no light. The sky and sun in the editor are only a preview and do
not exist in the running game.

| # | Do | Details |
| --- | --- | --- |
| 4.1 | **Scene → New Scene** → **3D Scene**, rename the root `Test` | |
| 4.2 | In the 3D viewport toolbar, open the **⋮** next to the sun and globe icons → **Add Sun to Scene**, then **Add Environment to Scene** | Light and sky for the game |
| 4.3 | Add a **MeshInstance3D** | Mesh: New **PlaneMesh**, Size `20 × 20` |
| 4.4 | With it selected: viewport toolbar **Mesh** → **Create Collision Shape…** | Placement **Static Body Child**, Type **Trimesh** → Create. That is the floor collision |
| 4.5 | Drag `player.tscn` from the FileSystem dock into the scene | Position `(0, 0, 0)` |
| 4.6 | Save as `test.tscn` → **F6** (Run Current Scene) | F6 runs only this scene and does not ask for a main scene |

Check: the idle plays, WASD runs, Space jumps and lands, the mouse orbits the
camera, and the three attacks swing and lunge forward.

### Stage 5: Training dummy (`dummy.tscn`, optional)

| # | Do | Details |
| --- | --- | --- |
| 5.1 | **Scene → New Scene** → Other Node → **StaticBody3D**, rename it `Dummy` | Collision Layer **1 and 2**: the player bumps into it, and the Hitbox (mask 2) finds it |
| 5.2 | Add a **MeshInstance3D**, rename it **`Body`** | Mesh: New **CapsuleMesh**, radius `0.32`, height `1.7`. Position Y `0.85`. Material: New StandardMaterial3D, a sandbag colour such as `#C7A36B`, roughness `0.9` |
| 5.3 | Add a **CollisionShape3D** | Shape: New **CylinderShape3D**, radius `0.32`, height `1.7`. Position Y `0.85` |
| 5.4 | Add a **Label3D**, rename it **`Counter`** | Text `0`, Billboard **Enabled**, font size `64`, outline size `12`. Position Y `2` |
| 5.5 | Attach a script to `Dummy` → `res://dummy.gd` → paste `dummy.gd` from Part C | It wobbles, flashes red and counts hits |
| 5.6 | Save as `dummy.tscn` | |

The names `Body` and `Counter` matter: the script looks for them, and `Body`
needs a material so it can flash.

### Stage 6: Level (`main.tscn`)

| # | Do | Details |
| --- | --- | --- |
| 6.1 | **Scene → New Scene** → **3D Scene**, rename the root `Main` | |
| 6.2 | ⋮ → **Add Sun to Scene** and **Add Environment to Scene** | As in Stage 4 |
| 6.3 | Ground: a **StaticBody3D** `Ground` with a **MeshInstance3D** (New BoxMesh `40 × 1 × 40`, green material) and a **CollisionShape3D** (New BoxShape3D, same size) | `Ground` position Y `-0.5`, so its top is at 0. The PlaneMesh trick from Stage 4 works too |
| 6.4 | Two steps to jump on, built the same way | `3 × 0.8 × 3` at `(-6, 0.4, -4)` and `3 × 1.6 × 3` at `(-6, 0.8, -8)` |
| 6.5 | Instance `player.tscn` | Position `(0, 0, 0)`. He faces +Z |
| 6.6 | Instance `dummy.tscn` three times | `(0, 0, 4)`, `(3, 0, 6)`, `(-3, 0, 6)`: in front of him |
| 6.7 | *(optional)* **CanvasLayer** → **Label** | Text: `WASD move · Space jump · LMB attack · RMB heavy · Q combo · Esc free mouse` |
| 6.8 | Save as `main.tscn` → **F5** → **Select Current** | This makes `main.tscn` the main scene |

### Stage 7: Window size

Godot's default game window is 1152 × 648 pixels, which looks tiny on a 1440p
or 4K screen. **Project → Project Settings → Display → Window → Size → Mode**:

- **Maximized:** full screen size with a title bar. Good for recording.
- **Fullscreen:** clean gameplay. Close it with Alt+F4.
- A fixed size: switch on **Advanced Settings** (top right of the dialog) and
  set **Window Width Override** and **Window Height Override**, for example
  `1920 × 1080`.

Viewport Width and Height can stay as they are; the 3D view renders at the
window's size.

### Adapting to other characters and clips

- **Different clip names:** change only the constants at the top and the clip
  names in `ATTACKS`. Every looping clip (idle, run, jump loop) must be in
  `LOOPING`.
- **Fewer attacks:** delete entries from `ATTACKS`. The keys `attack`,
  `attack_heavy` and `attack_combo` are input actions that the script creates
  in `_ensure_input_actions`; a new key needs a new action there.
- **Hit windows for other attack clips:** open the **Animation** panel at the
  bottom, select `Model/AnimationPlayer`, choose the attack and scrub to the
  part where the weapon moves fastest. Its start and end time in seconds become
  `Vector2(start, end)`. A combo gets one window per swing.
- **Root bone not called `root`** (skeletons from other tools): `_find_root_track`
  looks for a position track ending in `:root`. If none exists, the Output shows
  "No root position track found" and the attacks play in place. Change the
  ending to the skeleton's root or hips bone name.
- **The character runs backwards:** its forward axis is -Z instead of +Z. Use
  `atan2(-dir.x, -dir.z)` in `_move_step` and remove `+ PI` from the
  `cam_pivot.rotation.y` line in `_ready`.
- **Feet slide while running:** tune `move_speed` in the Inspector (select
  `Player`) until the steps match the ground.

### Troubleshooting

| Symptom or error | Cause | Fix |
| --- | --- | --- |
| `Node not found: "Model"` (or `"CameraPivot"`, `"CameraPivot/SpringArm3D"`) | A node name or the hierarchy differs | Rename exactly as in the Stage 2 tree; names are case-sensitive |
| `Node not found: "%Hitbox"` | Hitbox is missing or not a unique name | Right-click `Hitbox` → **Access as Unique Name** |
| `Animation not found: "…"`, or an error about `loop_mode` on a `Nil` value | A clip name in the script differs from the import | Copy the exact names from the AnimationPlayer. Remember that a trailing `_loop` is removed on import |
| Error at `hitbox.get_child(0)` | Hitbox has no CollisionShape3D, or it is not the first child | Put the CollisionShape3D first under Hitbox |
| ⚠ icon on `Hitbox` | The Area3D has no shape, often because it sits *inside* a CollisionShape3D | Area3D on top, CollisionShape3D as its child |
| He falls forever | No floor collision, or `player.tscn` was run on its own | Build the test scene (Stage 4); a mesh alone has no collision |
| The game is dark or has a grey background | No sun or environment in the scene | ⋮ → **Add Sun to Scene** and **Add Environment to Scene** |
| "No main scene has ever been defined" | No main scene set yet | Open `main.tscn` and choose **Select Current**, or press **F6** to run only the open scene |
| The game window is tiny | Default 1152 × 648 window | Stage 7 |
| The attack lunge is far too short | The animation runs on idle ticks while root motion is read on physics ticks | Keep the `callback_mode_process = ...PROCESS_PHYSICS` line in `_ready` |
| Attacks play in place; Output says "No root position track found" | Exported with **In place** on, or the root bone has another name | Re-export with In place off, or see "Root bone not called root" |
| The weapon never hits the dummies | Dummy is not on layer 2, the Hitbox mask is not 2, or `dummy.gd` is missing | Dummy Collision Layer 1 **and** 2, Hitbox Mask 2, `dummy.gd` attached. Keep the shape query; Area3D signals miss static bodies with Jolt |
| The camera starts in front, looking at his face | The `+ PI` camera line is missing, or the model faces -Z | Check the `cam_pivot.rotation.y` line; see "The character runs backwards" |
| He floats or sinks into the floor | Capsule position or the model's origin is off | Capsule position Y = half its height; move `Model` up or down until the feet touch 0 |
| Error in `dummy.gd` about `duplicate` on a `Nil` value | The dummy's `Body` has no material | Give the CapsuleMesh (or the Surface Material Override) a StandardMaterial3D |
| Idle or run plays once and freezes | The clip is not in `LOOPING` | Add its constant to `LOOPING` |
| The mouse is stuck in the game window | The script captures the mouse | **Esc** frees it, a click captures it again |

---

## Part C: The code

### `player.gd`

Attach to `Player` (CharacterBody3D). The clip names are those of the tested
ActionForge bundle. Replace them with the viewer's exact names.

```gdscript
extends CharacterBody3D
## Third-person player for the ActionForge sellsword (clip names as in the ActionForge bundle export, ending in _fit).
## Move: WASD · Jump: Space · Attack: LMB · Heavy: RMB · Combo: Q · Free mouse: Esc

const IDLE := "sword_idle_fit"
const RUN := "jog_fwd_loop_fit"  # ActionForge bundle names end in _fit
const JUMP_START := "jump_start_fit"
const JUMP_AIR := "jump_loop_fit"
const JUMP_LAND := "jump_land_fit"
const LOOPING := [IDLE, RUN, JUMP_AIR]

## Hit windows in seconds, measured from the arm's fastest rotation in each clip (+-0.03 s).
const ATTACKS := {
	"attack": {"clip": "sword_attack_fit", "windows": [Vector2(0.30, 0.50)]},
	"attack_heavy": {"clip": "sword_regular_c_fit", "windows": [Vector2(0.57, 0.73)]},
	"attack_combo": {"clip": "sword_regular_combo_fit",
		"windows": [Vector2(0.07, 0.33), Vector2(0.67, 0.80), Vector2(1.47, 1.63)]},
}

@export var move_speed := 4.5
@export var jump_velocity := 5.0
@export var jump_start_speed := 1.6  ## jump_start is a slow wind-up; play it faster
@export var turn_speed := 12.0
@export var mouse_sensitivity := 0.003

@onready var model: Node3D = $Model
@onready var anim: AnimationPlayer = $Model/AnimationPlayer
@onready var skeleton: Skeleton3D = $Model.find_child("Skeleton3D", true, false)
@onready var cam_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var hitbox: Area3D = %Hitbox

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var attack: Dictionary = {}       # the attack being played, empty when free
var hit_window := -1              # index of the window currently open
var hit_this_window: Array[Node] = []


func _ready() -> void:
	_ensure_input_actions()
	for clip in LOOPING:
		anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	anim.root_motion_track = _find_root_track(ATTACKS.attack.clip)
	# Root motion is read in _physics_process, so the animation must advance on physics ticks too.
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	anim.animation_finished.connect(_on_animation_finished)
	spring_arm.add_excluded_object(get_rid())
	spring_arm.rotation.x = -0.35  # camera slightly above, looking down
	cam_pivot.rotation.y = model.rotation.y + PI  # start behind the character (glTF faces +Z)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	anim.play(IDLE)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotation.x = clampf(
			spring_arm.rotation.x - event.relative.y * mouse_sensitivity, -1.2, 0.3)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if attack.is_empty():
		_move_step(delta)
	else:
		_attack_step(delta)

	var was_in_air := not is_on_floor()
	move_and_slide()
	if was_in_air and is_on_floor() and attack.is_empty():
		anim.play(JUMP_LAND, 0.1)


func _move_step(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := cam_pivot.global_basis * Vector3(input.x, 0.0, input.y)
	dir.y = 0.0
	dir = dir.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed

	if dir != Vector3.ZERO:
		# glTF characters face +Z; this turns +Z toward the move direction.
		model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), turn_speed * delta)

	for action in ATTACKS:
		if Input.is_action_just_pressed(action) and is_on_floor():
			_start_attack(ATTACKS[action])
			return
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		anim.play(JUMP_START, 0.05, jump_start_speed)
		return
	_update_locomotion(dir)


func _update_locomotion(dir: Vector3) -> void:
	var current := anim.current_animation
	if current == JUMP_START:
		return  # let the take-off finish
	if current == JUMP_LAND and dir == Vector3.ZERO:
		return  # finish the landing unless the player moves on
	if not is_on_floor():
		anim.play(JUMP_AIR, 0.15)
	elif dir != Vector3.ZERO:
		anim.play(RUN, 0.15)
	else:
		anim.play(IDLE, 0.2)


func _start_attack(a: Dictionary) -> void:
	attack = a
	hit_window = -1
	velocity.x = 0.0
	velocity.z = 0.0
	anim.play(a.clip, 0.1)


func _attack_step(delta: float) -> void:
	# Root motion: the clip's own lunge, turned to where the skeleton faces.
	var lunge := skeleton.global_basis * anim.get_root_motion_position() / delta
	velocity.x = lunge.x
	velocity.z = lunge.z

	var t := anim.current_animation_position
	var open := -1
	for i in attack.windows.size():
		var w: Vector2 = attack.windows[i]
		if t >= w.x and t <= w.y:
			open = i
	if open != hit_window:
		hit_window = open
		hit_this_window.clear()
	if open >= 0:
		for body in _bodies_in_hitbox():
			if body not in hit_this_window and body.has_method("take_hit"):
				hit_this_window.append(body)
				body.take_hit(global_position)


## The Hitbox node is only the editable volume; the check itself is a direct shape query,
## which is exact per physics tick and also sees static bodies (Jolt areas skip them).
func _bodies_in_hitbox() -> Array:
	var cs: CollisionShape3D = hitbox.get_child(0)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cs.shape
	q.transform = cs.global_transform
	q.collision_mask = hitbox.collision_mask
	q.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(q).map(func(r): return r.collider)


func _on_animation_finished(anim_name: StringName) -> void:
	if not attack.is_empty() and anim_name == attack.clip:
		attack = {}
		hit_window = -1
		anim.play(IDLE, 0.2)
	elif anim_name == JUMP_START:
		anim.play(JUMP_AIR if not is_on_floor() else IDLE, 0.1)
	elif anim_name == JUMP_LAND:
		anim.play(IDLE, 0.2)


func _find_root_track(clip: String) -> NodePath:
	var a := anim.get_animation(clip)
	for i in a.get_track_count():
		var path := String(a.track_get_path(i))
		if a.track_get_type(i) == Animation.TYPE_POSITION_3D and path.ends_with(":root"):
			return a.track_get_path(i)
	push_warning("No root position track found; attacks will play in place.")
	return NodePath()


func _ensure_input_actions() -> void:
	var keys := {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A,
		"move_right": KEY_D, "jump": KEY_SPACE, "attack_combo": KEY_Q}
	var buttons := {"attack": MOUSE_BUTTON_LEFT, "attack_heavy": MOUSE_BUTTON_RIGHT}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev := InputEventKey.new()
			ev.physical_keycode = keys[action]
			InputMap.action_add_event(action, ev)
	for action in buttons:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var mb := InputEventMouseButton.new()
			mb.button_index = buttons[action]
			InputMap.action_add_event(action, mb)
```

### `dummy.gd`

Attach to `Dummy` (StaticBody3D).

```gdscript
extends StaticBody3D
## Training dummy: wobbles, flashes and counts hits.

@onready var body: MeshInstance3D = $Body
@onready var counter: Label3D = $Counter

var hits := 0
var _mat: StandardMaterial3D


func _ready() -> void:
	_mat = body.get_active_material(0).duplicate()
	body.material_override = _mat


func take_hit(from: Vector3) -> void:
	hits += 1
	counter.text = str(hits)
	var away := (global_position - from)
	away.y = 0.0
	away = away.normalized()
	var tw := create_tween().set_parallel()
	tw.tween_property(body, "rotation", Vector3(away.z, 0.0, -away.x) * 0.35, 0.06)
	tw.tween_property(_mat, "albedo_color", Color(1.0, 0.35, 0.25), 0.04)
	tw.chain().tween_property(body, "rotation", Vector3.ZERO, 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_mat, "albedo_color", Color(0.78, 0.64, 0.42), 0.3)
```
