package Renderer

import "../../../OdinBasePack"
import "../../Math"
import "base:intrinsics"
import "vendor:sdl3"

Camera :: struct {
	bounds: Math.Rectangle,
}

PaintId :: distinct int

MetaConfig :: struct #all_or_none {
	layer:            LayerId,
	attachedEntityId: Maybe(int),
	positionType:     PositionType,
	color:            sdl3.Color,
}

PaintData :: union($TShapeName: typeid) {
	Texture(TShapeName),
	PieMask,
	String,
	Rectangle,
	Circle,
	Line,
	Triangle,
}
PaintIdUnion :: union {
	TextureId,
	PieMaskId,
	StringId,
	RectangleId,
	CircleId,
	LineId,
	TriangleId,
}

PaintUnion :: union($TShapeName: typeid) {
	Paint(Texture(TShapeName), TShapeName),
	Paint(PieMask, TShapeName),
	Paint(String, TShapeName),
	Paint(Rectangle, TShapeName),
	Paint(Circle, TShapeName),
	Paint(Line, TShapeName),
	Paint(Triangle, TShapeName),
}

Paint :: struct(
	$TData: typeid,
	$TShapeName: typeid,
) #all_or_none where intrinsics.type_is_variant_of(PaintData(TShapeName), TData) ||
	TData == PaintData(TShapeName)
{
	config:  MetaConfig,
	paintId: PaintId,
	offset:  Math.Vector,
	element: TData,
}

LayerId :: enum {
	BACKGROUND_1,
	BACKGROUND,
	PANEL_BACK_0,
	ENTITY_BACK_0,
	ENTITY_BACK_3,
	ENTITY_BACK_2,
	ENTITY_BACK_1,
	ENTITY,
	ENTITY_FRONT_1,
	ENTITY_FRONT_2,
	ENTITY_FRONT_3,
	ENTITY_FRONT_4,
	ENTITY_FRONT_5,
	ENTITY_FRONT_6,
	ENTITY_FRONT_0,
	PANEL_0,
	PANEL_1,
	PANEL_2,
	PANEL_3,
	PANEL_4,
	PANEL_5,
	PANEL_6,
	PANEL_7,
	PANEL_8,
	PANEL_9,
	PANEL_10,
	PANEL_11,
	PANEL_12,
	PANEL_13,
	PANEL_14,
	PANEL_15,
	PANEL_16,
	PANEL_17,
	ITEM_PANEL_0,
	ITEM_PANEL_1,
	ITEM_PANEL_2,
	ITEM_PANEL_3,
}

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
	GRAY,
}

@(require_results)
getColorFromName :: proc(colorName: ColorName) -> (color: sdl3.Color, error: OdinBasePack.Error) {
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
	case .INVALID:
		fallthrough
	case:
		error = .INVALID_ENUM_VALUE
	}
	return
}
