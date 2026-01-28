package Renderer

import "../Math"
import "base:intrinsics"
import "vendor:sdl3"

ShapeDirection :: enum {
	LEFT_RIGHT,
	RIGHT_LEFT,
}

DynamicImageShapeConfig :: struct(
	$TImageName: typeid,
	$TBitmapName: typeid,
) where intrinsics.type_is_enum(TImageName) &&
	intrinsics.type_is_enum(TBitmapName)
{
	imageFileName: TImageName,
	bounds:        Math.Rectangle,
	offset:        Math.Vector,
	direction:     ShapeDirection,
	bitmapName:    TBitmapName,
	zoomOnMap:     f32,
	zoomInEq:      f32,
}

ImageShapeConfig :: struct($TImageName: typeid, $TBitmapName: typeid) {
	imageFileName: TImageName,
	bounds:        Math.Rectangle,
	direction:     ShapeDirection,
	bitmapName:    Maybe(TBitmapName),
}


Shape :: struct {
	texture:         ^sdl3.Texture,
	bounds:          Math.Rectangle,
	direction:       ShapeDirection,
	markerVectorMap: map[int]Math.Vector,
}
