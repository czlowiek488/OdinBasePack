package BasePackMath

import "core:math"
import "vendor:sdl3"

Vector :: sdl3.FPoint

IntVector :: [2]int

Rectangle :: struct {
	position, size: Vector,
}
Circle :: struct {
	position: Vector,
	radius:   f32,
}

Triangle :: struct {
	a, b, c: Vector,
}

Geometry :: union {
	Rectangle,
	Circle,
	Triangle,
}

@(require_results)
isCollidingCircleCircle :: proc(circleA, circleB: Circle) -> (result: bool) {
	dx := circleA.position.x - circleB.position.x
	dy := circleA.position.y - circleB.position.y
	distSquared := dx * dx + dy * dy
	radiusSum := circleA.radius + circleB.radius
	result = distSquared <= radiusSum * radiusSum
	return
}


@(require_results)
project :: proc(a, b, c: Vector, axis: Vector) -> (min: f32, max: f32) {
	a := a[0] * axis[0] + a[1] * axis[1]
	b := b[0] * axis[0] + b[1] * axis[1]
	c := c[0] * axis[0] + c[1] * axis[1]
	min = math.min(a, b, c)
	max = math.max(a, b, c)
	return
}

@(require_results)
isCollidingTriangleTriangle :: proc(triangleA, triangleB: Triangle) -> (result: bool) {
	axes := [6]Vector {
		{triangleA.b[1] - triangleA.a[1], triangleA.a[0] - triangleA.b[0]},
		{triangleA.c[1] - triangleB.b[1], triangleA.b[0] - triangleA.c[0]},
		{triangleA.a[1] - triangleA.c[1], triangleA.c[0] - triangleA.a[0]},
		{triangleB.b[1] - triangleB.a[1], triangleB.a[0] - triangleB.b[0]},
		{triangleB.c[1] - triangleB.b[1], triangleB.b[0] - triangleB.c[0]},
		{triangleB.a[1] - triangleB.c[1], triangleB.c[0] - triangleB.a[0]},
	}
	for axis in axes {
		minA, maxA := project(triangleA.a, triangleA.b, triangleA.c, axis)
		minB, maxB := project(triangleB.a, triangleB.b, triangleB.c, axis)
		if maxA < minB || maxB < minA {
			result = false
			return
		}
	}
	result = true
	return
}

@(require_results)
isCollidingRectangleRectangle :: proc(rectangleA, rectangleB: Rectangle) -> (result: bool) {
	aMinX := rectangleA.position.x
	aMaxX := rectangleA.position.x + rectangleA.size.x
	aMinY := rectangleA.position.y
	aMaxY := rectangleA.position.y + rectangleA.size.y

	bMinX := rectangleB.position.x
	bMaxX := rectangleB.position.x + rectangleB.size.x
	bMinY := rectangleB.position.y
	bMaxY := rectangleB.position.y + rectangleB.size.y

	result = !(aMaxX < bMinX || aMinX > bMaxX || aMaxY < bMinY || aMinY > bMaxY)
	return
}

@(require_results)
isCollidingRectangleCircle :: proc(rectangle: Rectangle, circle: Circle) -> (result: bool) {
	closestX := clamp(
		circle.position.x,
		rectangle.position.x,
		rectangle.position.x + rectangle.size.x,
	)
	closestY := clamp(
		circle.position.y,
		rectangle.position.y,
		rectangle.position.y + rectangle.size.y,
	)

	dx := circle.position.x - closestX
	dy := circle.position.y - closestY
	result = dx * dx + dy * dy <= circle.radius * circle.radius
	return
}

@(require_results)
getGeometryAABB :: proc(geometry: Geometry) -> (min, max: Vector) {
	switch value in geometry {
	case Circle:
		min.x = value.position.x - value.radius
		min.y = value.position.y - value.radius
		max.x = value.position.x + value.radius
		max.y = value.position.y + value.radius
	case Rectangle:
		min.x = value.position.x
		min.y = value.position.y
		max.x = value.position.x + value.size.x
		max.y = value.position.y + value.size.y
	case Triangle:
		min.x = math.min(value.a.x, value.b.x, value.c.x)
		min.y = math.min(value.a.y, value.b.y, value.c.y)
		max.x = math.max(value.a.x, value.b.x, value.c.x)
		max.y = math.max(value.a.y, value.b.y, value.c.y)
	}
	return
}

@(require_results)
getGeometryCenter :: proc(geometry: Geometry) -> (result: Vector) {
	min, max := getGeometryAABB(geometry)
	result = {(min.x + max.x) * .5, (min.y + max.y) * .5}
	return
}


@(require_results)
isCollidingRectangleTriangle :: proc(rectangle: Rectangle, triangle: Triangle) -> (result: bool) {
	rA := rectangle.position
	rB := rA + Vector{rectangle.size.x, 0}
	rC := rA + rectangle.size
	rD := rA + Vector{0, rectangle.size.y}

	t1 := Triangle {
		a = rA,
		b = rB,
		c = rC,
	}
	t2 := Triangle {
		a = rA,
		b = rC,
		c = rD,
	}

	result = isCollidingTriangleTriangle(t1, triangle)
	if result {
		return
	}
	result = isCollidingTriangleTriangle(t2, triangle)
	return
}


@(require_results)
distanceSqToSegment :: proc(p, a, b: Vector) -> f32 {
	ap := p - a
	ab := b - a
	t := math.clamp((ap[0] * ab[0] + ap[1] * ab[1]) / (ab[0] * ab[0] + ab[1] * ab[1]), 0.0, 1.0)
	closest := a + ab * t
	dx := p[0] - closest[0]
	dy := p[1] - closest[1]
	return dx * dx + dy * dy
}

@(require_results)
isPointInTriangle :: proc(p, a, b, c: Vector) -> bool {
	dx := p[0]
	dy := p[1]
	ax := a[0] - dx
	ay := a[1] - dy
	bx := b[0] - dx
	by := b[1] - dy
	cx := c[0] - dx
	cy := c[1] - dy

	ab := ax * by - ay * bx
	bc := bx * cy - by * cx
	ca := cx * ay - cy * ax
	return (ab >= 0 && bc >= 0 && ca >= 0) || (ab <= 0 && bc <= 0 && ca <= 0)
}

@(require_results)
isCollidingTriangleCircle :: proc(triangle: Triangle, circle: Circle) -> (result: bool) {
	if isPointInTriangle(circle.position, triangle.a, triangle.b, triangle.c) {
		result = true
		return
	}

	r2 := circle.radius * circle.radius
	if distanceSqToSegment(circle.position, triangle.a, triangle.b) <= r2 {
		result = true
		return
	}
	if distanceSqToSegment(circle.position, triangle.b, triangle.c) <= r2 {
		result = true
		return
	}
	if distanceSqToSegment(circle.position, triangle.c, triangle.a) <= r2 {
		result = true
		return
	}

	result = false
	return
}

@(require_results)
isCollidingTriangleRectangle :: proc(triangle: Triangle, rectangle: Rectangle) -> (result: bool) {
	return isCollidingRectangleTriangle(rectangle, triangle)
}

@(require_results)
isCollidingCircleRectangle :: proc(circle: Circle, rectangle: Rectangle) -> (result: bool) {
	return isCollidingRectangleCircle(rectangle, circle)
}

@(require_results)
isCollidingCircleTriangle :: proc(circle: Circle, triangle: Triangle) -> (result: bool) {
	return isCollidingTriangleCircle(triangle, circle)
}

@(require_results)
isCollidingCircleGeometry :: proc(circle: Circle, geometry: Geometry) -> (result: bool) {
	return isCollidingGeometryCircle(geometry, circle)
}

@(require_results)
isCollidingGeometryCircle :: proc(geometry: Geometry, circle: Circle) -> (result: bool) {
	switch value in geometry {
	case Circle:
		result = isCollidingCircleCircle(value, circle)
	case Rectangle:
		result = isCollidingRectangleCircle(value, circle)
	case Triangle:
		result = isCollidingTriangleCircle(value, circle)
	}
	return
}

@(require_results)
isCollidingTriangleGeometry :: proc(triangle: Triangle, geometry: Geometry) -> (result: bool) {
	return isCollidingGeometryTriangle(geometry, triangle)
}

@(require_results)
isCollidingGeometryTriangle :: proc(geometry: Geometry, triangle: Triangle) -> (result: bool) {
	switch value in geometry {
	case Circle:
		result = isCollidingCircleTriangle(value, triangle)
	case Rectangle:
		result = isCollidingRectangleTriangle(value, triangle)
	case Triangle:
		result = isCollidingTriangleTriangle(value, triangle)
	}
	return
}

@(require_results)
isCollidingRectangleGeometry :: proc(rectangle: Rectangle, geometry: Geometry) -> (result: bool) {
	return isCollidingGeometryRectangle(geometry, rectangle)
}

@(require_results)
isCollidingGeometryRectangle :: proc(geometry: Geometry, rectangle: Rectangle) -> (result: bool) {
	switch value in geometry {
	case Circle:
		result = isCollidingCircleRectangle(value, rectangle)
	case Rectangle:
		result = isCollidingRectangleRectangle(value, rectangle)
	case Triangle:
		result = isCollidingTriangleRectangle(value, rectangle)
	}
	return
}

@(require_results)
isCollidingGeometryGeometry :: proc(hitBoxA, hitBoxB: Geometry) -> (result: bool) {
	switch value in hitBoxA {
	case Circle:
		result = isCollidingCircleGeometry(value, hitBoxB)
	case Rectangle:
		result = isCollidingRectangleGeometry(value, hitBoxB)
	case Triangle:
		result = isCollidingTriangleGeometry(value, hitBoxB)
	}
	return
}

@(require_results)
isPointCollidingWithRectangle :: proc(rectangle: Rectangle, position: Vector) -> (result: bool) {
	result =
		position.x >= rectangle.position.x &&
		position.x < rectangle.position.x + rectangle.size.x &&
		position.y >= rectangle.position.y &&
		position.y < rectangle.position.y + rectangle.size.y
	return
}

@(require_results)
isPointCollidingWithCircle :: proc(circle: Circle, position: Vector) -> (hovered: bool) {
	distanceSquared :=
		(position.x - circle.position.x) * (position.x - circle.position.x) +
		(position.y - circle.position.y) * (position.y - circle.position.y)
	hovered = distanceSquared <= (circle.radius * circle.radius)
	return
}
