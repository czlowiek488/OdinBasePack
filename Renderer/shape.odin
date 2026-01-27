package Renderer

import "../Math"
import "base:intrinsics"
import "vendor:sdl3"

ShapeDirection :: enum {
	LEFT_RIGHT,
	RIGHT_LEFT,
}

DynamicImageShapeConfig :: struct(
	$TFileImageName: typeid,
	$TBitmapName: typeid,
) where intrinsics.type_is_enum(TFileImageName) &&
	intrinsics.type_is_enum(TBitmapName)
{
	imageFileName: TFileImageName,
	bounds:        Math.Rectangle,
	offset:        Math.Vector,
	direction:     ShapeDirection,
	bitmapName:    TBitmapName,
	zoomOnMap:     f32,
	zoomInEq:      f32,
}

ImageShapeConfig :: struct($TFileImageName: typeid, $TBitmapName: typeid) {
	imageFileName: TFileImageName,
	bounds:        Math.Rectangle,
	direction:     ShapeDirection,
	bitmapName:    Maybe(TBitmapName),
}


Shape :: struct($TMarkerName: typeid) {
	texture:         ^sdl3.Texture,
	bounds:          Math.Rectangle,
	direction:       ShapeDirection,
	markerVectorMap: map[TMarkerName]Math.Vector,
}
