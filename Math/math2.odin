package BasePackMath

import "../../OdinBasePack"
import "core:math"
import "core:math/rand"

ONEQTR_PI :: math.PI / 4.0
THRQTR_PI :: 3.0 * ONEQTR_PI

EntityMoveDelta :: [2]int

@(require_results)
atan2Fast2 :: proc(y, x: f32) -> f32 {
	abs_y := math.abs(y) + 1e-10 // to avoid division by zero
	if x >= 0 {
		r := (x - abs_y) / (x + abs_y)
		return (ONEQTR_PI - ONEQTR_PI * r) * math.sign(y)
	}
	r := (x + abs_y) / (abs_y - x)
	return (THRQTR_PI - ONEQTR_PI * r) * math.sign(y)
}

@(require_results)
vLength :: proc(v: Vector) -> f32 {
	return math.sqrt(v.x * v.x + v.y * v.y)
}

@(require_results)
vDot :: proc(a, b: Vector) -> f32 {
	return a.x * b.x + a.y * b.y
}

@(require_results)
vRound :: proc(vec, chunk: Vector) -> (result: Vector) {
	result = roundVector(vec / chunk)
	result *= chunk
	return
}

@(require_results)
vNormalize :: proc(v: Vector) -> Vector {
	length := vLength(v)
	if length == 0 {
		return Vector{0, 0}
	}
	return Vector{v.x / length, v.y / length}
}

@(require_results)
vAbs :: proc(v: Vector) -> Vector {
	return {math.abs(v.x), math.abs(v.y)}
}


@(require_results)
angleFromVector :: proc(vector: Vector) -> f32 {
	return atan2Fast2(vector.y, vector.x) * (180.0 / math.PI)
}

@(require_results)
vectorFromAngle :: proc(angle: f32) -> (vector: Vector, error: OdinBasePack.Error) {
	radians := toRadians(angle) or_return
	vector = {math.cos(radians), math.sin(radians)}
	return
}


vMin :: proc(a, b: Vector) -> (minimal: Vector) {
	minimal.x = math.min(a.x, b.x)
	minimal.y = math.min(a.y, b.y)
	return
}


clampVector :: proc(v: ^Vector, min, max: Vector) {
	v.x = clamp(v.x, min.x, max.x)
	v.y = clamp(v.y, min.y, max.y)
}

@(require_results)
randomVector :: proc(min, max: Vector, strategy: enum {
		RANGE,
		FARTHEST,
		CIRCLE_EDGE,
	}) -> (v: Vector, error: OdinBasePack.Error) {
	if min == {0, 0} && max == {0, 0} {
		error = OdinBasePack.Error.MATH_MIN_MAX_MUST_NO_BOTH_BE_ZERO
		return
	}
	switch strategy {
	case .FARTHEST:
		v = {rand.choice([]f32{min.x, max.x}), rand.choice([]f32{min.y, max.y})}
	case .RANGE:
		v = {rand.float32_range(min.x, max.x), rand.float32_range(min.y, max.y)}
	case .CIRCLE_EDGE:
		if max.x != max.y || min.x != min.y || max.x != -min.x || max.x != -min.x {
			error = OdinBasePack.Error.MATH_VECTOR_MIN_MAX_MUST_BE_MATCHING_CIRCLE
			return
		}
		angle := rand.float32_range(0, math.TAU)
		v = {math.cos(angle) * max.x, math.sin(angle) * max.x}
	case:
		error = OdinBasePack.Error.INVALID_ENUM_VALUE
	}
	return
}


floorVector :: proc(vector: Vector) -> Vector {
	return {math.floor(vector.x), math.floor(vector.y)}
}

@(require_results)
roundVector :: proc(vector: Vector) -> (result: Vector) {
	result = {math.round(vector.x), math.round(vector.y)}
	return
}


@(require_results)
scaleToFit :: proc(
	itemSize: Vector,
	targetSize: Vector,
) -> (
	vector: Vector,
	error: OdinBasePack.Error,
) {
	scaleX := targetSize.x / itemSize.x
	scaleY := targetSize.y / itemSize.y
	scale := min(scaleX, scaleY)
	vector = itemSize * scale
	return
}

@(require_results)
scaleBounds :: proc(bounds: Rectangle, scale, origin: Vector) -> (newBounds: Rectangle) {
	newBounds = {
		{
			origin.x + ((bounds.position.x - origin.x) * scale.x),
			origin.y + ((bounds.position.y - origin.y) * scale.y),
		},
		{bounds.size.x * scale.x, bounds.size.y * scale.y},
	}
	return
}


@(require_results)
scaleBoundsToCenter :: proc(
	bounds: Rectangle,
	scale: Vector,
) -> (
	newBounds: Rectangle,
	error: OdinBasePack.Error,
) {
	newBounds = scaleBounds(bounds, scale, getRectangleCenter(bounds))
	return
}

@(require_results)
rotateVectorRad :: proc(p: Vector, center: Vector, rad: f32) -> (result: Vector) {
	s := math.sin(rad)
	c := math.cos(rad)

	abs := p - center

	result.x = abs.x * c - abs.y * s
	result.y = abs.x * s + abs.y * c
	result += center
	return
}

@(require_results)
toRadians :: proc(angle: f32) -> (radians: f32, error: OdinBasePack.Error) {
	radians = angle * math.PI / 180
	return
}

@(require_results)
rotateVector :: proc(
	vector: Vector,
	center: Vector,
	angle: f32,
) -> (
	rotated: Vector,
	error: OdinBasePack.Error,
) {
	radians := toRadians(angle) or_return
	rotated = rotateVectorRad(vector, center, radians)
	return
}

@(require_results)
rotateTriangle :: proc(
	triangle: Triangle,
	angle: f32,
) -> (
	rotated: Triangle,
	error: OdinBasePack.Error,
) {
	center := getGeometryCenter(triangle)
	radians := toRadians(angle) or_return

	rotated.a = rotateVectorRad(triangle.a, center, radians)
	rotated.b = rotateVectorRad(triangle.b, center, radians)
	rotated.c = rotateVectorRad(triangle.c, center, radians)
	return
}
