package RendererBitmap

import "../../Math"
import "base:intrinsics"
import "vendor:sdl3"

PixelColorListMapElement :: [dynamic]Math.Vector

BitmapConfig :: struct($TMarkerName: typeid) where intrinsics.type_is_enum(TMarkerName) {
	filePath:     string,
	enumColorMap: map[sdl3.Color]TMarkerName,
}

Bitmap :: struct($TMarkerName: typeid) {
	config:            BitmapConfig(TMarkerName),
	pixelColorListMap: map[TMarkerName]PixelColorListMapElement,
}
