package Painter

import "../../../OdinBasePack"
import "../../EventLoop"
import "../../Math"
import "../Animation"
import "../Renderer"
import "vendor:sdl3"

AnimationId :: distinct int
PieMaskId :: Renderer.PieMaskId
TextureId :: Renderer.TextureId
StringId :: Renderer.StringId
RectangleId :: Renderer.RectangleId
CircleId :: Renderer.CircleId
LineId :: Renderer.LineId
TriangleId :: Renderer.TriangleId
GeometryId :: union {
	RectangleId,
	CircleId,
	TriangleId,
}

AnimationConfig :: struct($TAnimationName: typeid) {
	animationName: union {
		TAnimationName,
		string,
	},
	rotation:      f32,
	zoom:          f32,
	bounds:        Math.Rectangle,
	metaConfig:    Renderer.MetaConfig,
}

Animation :: struct($TShapeName: typeid, $TAnimationName: typeid) {
	animationId:      AnimationId,
	config:           AnimationConfig(TAnimationName),
	currentTextureId: TextureId,
	timeoutId:        Maybe(EventLoop.ReferenceId),
	offset:           Math.Vector,
	animation:        Animation.Animation(TShapeName, TAnimationName),
}

Color :: sdl3.Color

ColorName :: enum {
	INVALID,
	WHITE,
	WHITE_ALPHA_20,
	WHITE_ALPHA_60,
	RED,
	RED_ALPHA_20,
	GREEN,
	GREEN_ALPHA_20,
	BLUE,
	BLUE_ALPHA_20,
	BLACK,
	BLACK_ALPHA_20,
	BLACK_ALPHA_80,
	BLACK_ALPHA_60,
	GREY_BROWN,
	GREY_BROWN_ALPHA_20,
	GREY_BROWN_LIGHT,
	GREY_BROWN_LIGHT_ALPHA_20,
	YELLOW,
	YELLOW_ALPHA_20,
	ORANGE,
	PINK,
	DARK_GRAY,
	LIGHT_GRAY,
	GRAY,
	TRANSPARENT,
}

colorToInt :: proc(c: sdl3.Color) -> u32 {
	return (u32(c.r) << 24) | (u32(c.g) << 16) | (u32(c.b) << 8) | u32(c.a)
}

@(require_results)
getColorFromName :: proc(colorName: ColorName) -> (color: sdl3.Color) {
	switch colorName {
	case .WHITE:
		color = {255, 255, 255, 255}
	case .WHITE_ALPHA_20:
		color = {255, 255, 255, 255 * .2}
	case .WHITE_ALPHA_60:
		color = {255, 255, 255, 255 * .6}
	case .RED:
		color = {255, 32, 32, 255}
	case .RED_ALPHA_20:
		color = {255, 32, 32, 255 * .2}
	case .GREEN:
		color = {32, 255, 32, 255}
	case .GREEN_ALPHA_20:
		color = {32, 255, 32, 255 * .2}
	case .BLUE:
		color = {32, 32, 255, 255}
	case .BLUE_ALPHA_20:
		color = {32, 32, 255, 255 * .2}
	case .BLACK:
		color = {0, 0, 0, 255}
	case .BLACK_ALPHA_20:
		color = {0, 0, 0, 255 * .2}
	case .BLACK_ALPHA_80:
		color = {0, 0, 0, 255 * .8}
	case .BLACK_ALPHA_60:
		color = {0, 0, 0, 255 * .6}
	case .GREY_BROWN:
		color = {55, 50, 47, 255}
	case .GREY_BROWN_ALPHA_20:
		color = {55, 50, 47, 255 * .2}
	case .GREY_BROWN_LIGHT:
		color = {100, 100, 100, 255}
	case .GREY_BROWN_LIGHT_ALPHA_20:
		color = {100, 100, 100, 255 * .2}
	case .YELLOW:
		color = {189, 155, 25, 255}
	case .YELLOW_ALPHA_20:
		color = {189, 155, 25, 255 * .2}
	case .ORANGE:
		color = {255, 165, 0, 255}
	case .PINK:
		color = {255, 192, 203, 255}
	case .GRAY:
		color = {128, 128, 128, 255}
	case .DARK_GRAY:
		color = {64, 64, 64, 255}
	case .TRANSPARENT:
		color = {0, 0, 0, 0}
	case .LIGHT_GRAY:
		color = {192, 192, 192, 255}
	case .INVALID:
		fallthrough
	case:
		color = {255, 255, 255, 255}
	}
	return
}
