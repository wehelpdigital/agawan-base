class_name FxField
extends MultiMeshInstance3D
## All the particles in a 3D world: one mesh, one draw call, updated from script. `density` scales how
## many cosmetic particles get made (lower on phones).

const STRIDE := 20  # 12 transform + 4 colour + 4 custom floats per instance.

var density := 1.0
var _max := 320
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _life := PackedFloat32Array()
var _age := PackedFloat32Array()
var _size := PackedFloat32Array()
var _cell := PackedByteArray()
var _spin := PackedFloat32Array()
var _rot := PackedFloat32Array()
var _col := PackedColorArray()
var _grav := PackedFloat32Array()
var _count := 0
var _buffer := PackedFloat32Array()


func _init(max_particles := 320) -> void:
	_max = max_particles
	_pos.resize(_max)
	_vel.resize(_max)
	_life.resize(_max)
	_age.resize(_max)
	_size.resize(_max)
	_cell.resize(_max)
	_spin.resize(_max)
	_rot.resize(_max)
	_col.resize(_max)
	_grav.resize(_max)
	_buffer.resize(_max * STRIDE)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = _max
	mm.visible_instance_count = 0
	multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://gfx/shaders/fx_particle.gdshader")
	mat.set_shader_parameter("atlas", preload("res://assets/fx/atlas.png"))
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = AABB(Vector3(-200, -50, -200), Vector3(400, 100, 400))


func spawn(at: Vector3, vel: Vector3, life: float, size: float, cell: int, color: Color, spin := 0.0, gravity := 0.0) -> void:
	if _count >= _max:
		return
	var i := _count
	_count += 1
	_pos[i] = at
	_vel[i] = vel
	_life[i] = life
	_age[i] = 0.0
	_size[i] = size
	_cell[i] = cell
	_spin[i] = spin
	_rot[i] = randf() * TAU
	_col[i] = color
	_grav[i] = gravity


## A round explosion of particles.
func burst(at: Vector3, count: int, speed: float, life: float, size: float, cell: int, colors: Array, gravity := 7.0) -> void:
	var n := int(ceil(count * density))
	for i in n:
		var dir := Vector3(randf_range(-1.0, 1.0), randf_range(0.2, 1.0), randf_range(-1.0, 1.0)).normalized()
		var c: Variant = colors[i % colors.size()]
		var col: Color = Color(c) if c is String else c
		spawn(at, dir * speed * randf_range(0.5, 1.2), life * randf_range(0.7, 1.2), size * randf_range(0.7, 1.2), cell, col, randf_range(-6.0, 6.0), gravity)


## A flat expanding ring of particles on the ground.
func shock_ring(at: Vector3, radius: float, cell: int, color: Color, count := 24) -> void:
	var n := int(ceil(count * density))
	for i in n:
		var a := TAU * i / n
		var d := Vector3(cos(a), 0.0, sin(a))
		spawn(at + d * 0.3 + Vector3(0, 0.2, 0), d * radius * 2.5, 0.42, 0.45, cell, color, 2.0)


func clear_all() -> void:
	_count = 0
	multimesh.visible_instance_count = 0


func _process(delta: float) -> void:
	var i := 0
	while i < _count:
		_age[i] += delta
		if _age[i] >= _life[i]:
			_count -= 1
			if i < _count:
				_pos[i] = _pos[_count]
				_vel[i] = _vel[_count]
				_life[i] = _life[_count]
				_age[i] = _age[_count]
				_size[i] = _size[_count]
				_cell[i] = _cell[_count]
				_spin[i] = _spin[_count]
				_rot[i] = _rot[_count]
				_col[i] = _col[_count]
				_grav[i] = _grav[_count]
			continue
		var v := _vel[i]
		v.y -= _grav[i] * delta
		var p := _pos[i] + v * delta
		if p.y < 0.06:
			p.y = 0.06
			v.y = -v.y * 0.4
			v.x *= 0.7
			v.z *= 0.7
		_pos[i] = p
		_vel[i] = v
		_rot[i] += _spin[i] * delta
		var o := i * STRIDE
		var fade := _age[i] / _life[i]
		var c := _col[i]
		_buffer[o] = 1.0
		_buffer[o + 1] = 0.0
		_buffer[o + 2] = 0.0
		_buffer[o + 3] = p.x
		_buffer[o + 4] = 0.0
		_buffer[o + 5] = 1.0
		_buffer[o + 6] = 0.0
		_buffer[o + 7] = p.y
		_buffer[o + 8] = 0.0
		_buffer[o + 9] = 0.0
		_buffer[o + 10] = 1.0
		_buffer[o + 11] = p.z
		_buffer[o + 12] = c.r
		_buffer[o + 13] = c.g
		_buffer[o + 14] = c.b
		_buffer[o + 15] = c.a * (1.0 - fade * fade)
		_buffer[o + 16] = float(_cell[i])
		_buffer[o + 17] = _size[i] * (1.0 - fade * 0.45)
		_buffer[o + 18] = _rot[i]
		_buffer[o + 19] = 0.0
		i += 1
	if _count > 0:
		multimesh.buffer = _buffer
	multimesh.visible_instance_count = _count
