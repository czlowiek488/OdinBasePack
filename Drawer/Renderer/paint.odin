package Renderer

import "../../../OdinBasePack"
import "../../Math"
import "base:intrinsics"
import "vendor:sdl3"

Color :: sdl3.Color

Camera :: struct {
	bounds: Math.Rectangle,
}

PaintId :: distinct int

ZIndex :: distinct int

MetaConfig :: struct #all_or_none {
	layer:            LayerId,
	zIndex:           ZIndex,
	attachedEntityId: Maybe(int),
	positionType:     PositionType,
	color:            ColorDefinition,
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
	RED,
	GREEN,
	BLUE,
	BLACK,
	GREY_BROWN,
	GREY_BROWN_LIGHT,
	YELLOW,
	ORANGE,
	PINK,
	DARK_GRAY,
	LIGHT_GRAY,
	GRAY,
}
ColorDefinition :: struct {
	colorName:  ColorName,
	brightness: f32,
	alpha:      f32,
}

@(require_results)
getColor :: proc(colorDefinition: ColorDefinition) -> (color: sdl3.Color) {
	switch colorDefinition.colorName {
	case .WHITE:
		color = {255, 255, 255, 255}
	case .RED:
		color = {255, 32, 32, 255}
	case .GREEN:
		color = {32, 255, 32, 255}
	case .BLUE:
		color = {32, 32, 255, 255}
	case .BLACK:
		color = {0, 0, 0, 255}
	case .GREY_BROWN:
		color = {55, 50, 47, 255}
	case .GREY_BROWN_LIGHT:
		color = {100, 100, 100, 255}
	case .YELLOW:
		color = {189, 155, 25, 255}
	case .ORANGE:
		color = {255, 165, 0, 255}
	case .PINK:
		color = {255, 192, 203, 255}
	case .GRAY:
		color = {128, 128, 128, 255}
	case .DARK_GRAY:
		color = {64, 64, 64, 255}
	case .LIGHT_GRAY:
		color = {192, 192, 192, 255}
	case .INVALID:
		fallthrough
	case:
		color = {255, 255, 255, 255}
	}
	color.a = u8(f32(color.a) * colorDefinition.alpha)
	color.r = u8(f32(color.r) * colorDefinition.brightness)
	color.g = u8(f32(color.g) * colorDefinition.brightness)
	color.b = u8(f32(color.b) * colorDefinition.brightness)
	return
}
