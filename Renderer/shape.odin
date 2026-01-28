package Renderer

import "../Math"
import "base:intrinsics"
import "vendor:sdl3"

ShapeDirection :: enum {
	LEFT_RIGHT,
	RIGHT_LEFT,
}

DynamicImageShapeConfig :: struct {
	imageFileName: int,
	bounds:        Math.Rectangle,
	offset:        Math.Vector,
	direction:     ShapeDirection,
	zoomOnMap:     f32,
	zoomInEq:      f32,
}

ImageShapeConfig :: struct {
	imageFileName: int,
	bounds:        Math.Rectangle,
	direction:     ShapeDirection,
	bitmapName:    Maybe(int),
}


Shape :: struct {
	texture:         ^sdl3.Texture,
	bounds:          Math.Rectangle,
	direction:       ShapeDirection,
	markerVectorMap: map[int]Math.Vector,
}
