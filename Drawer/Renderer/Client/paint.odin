package RendererClient

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory/AutoSet"
import "../../../Memory/SparseSet"
import "../../Renderer"
import "base:intrinsics"

@(require_results)
getPaint :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	paintId: $TPaintId,
	$TElement: typeid,
	required: bool,
) -> (
	meta: ^Renderer.Paint(TElement, TShapeName),
	ok: bool,
	error: OdinBasePack.Error,
) where (TElement == Renderer.PaintData(TShapeName) ||
		intrinsics.type_is_variant_of(Renderer.PaintData(TShapeName), TElement)) &&
	(intrinsics.type_is_variant_of(Renderer.PaintIdUnion, TPaintId) ||
			TPaintId == Renderer.PaintId) {
	defer OdinBasePack.handleError(error)
	metaUnion: ^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName)
	metaUnion, ok = AutoSet.get(module.paintAS, Renderer.PaintId(paintId), required) or_return
	meta = cast(^Renderer.Paint(TElement, TShapeName))metaUnion
	return
}

@(private)
@(require_results)
createPaint :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	config: Renderer.MetaConfig,
	element: $TElement,
) -> (
	paintId: Renderer.PaintId,
	paint: ^Renderer.Paint(TElement, TShapeName),
	error: OdinBasePack.Error,
) where intrinsics.type_is_variant_of(Renderer.PaintData(TShapeName), TElement) {
	defer OdinBasePack.handleError(error)
	metaUnion: ^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName)
	paintId, metaUnion = AutoSet.set(
		module.paintAS,
		Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName) {
			config,
			0,
			{0, 0},
			Renderer.PaintData(TShapeName)(element),
		},
	) or_return
	paint = cast(^Renderer.Paint(TElement, TShapeName))metaUnion
	SparseSet.set(
		module.renderOrder[paint.config.layer],
		paintId,
		RenderOrder{paintId, {0, 0}, 0},
	) or_return
	paint.paintId = paintId
	switch &v in &metaUnion.element {
	case Renderer.PieMask:
		v.pieMaskId = Renderer.PieMaskId(paintId)
	case Renderer.String:
		v.stringId = Renderer.StringId(paintId)
	case Renderer.Rectangle:
		v.rectangleId = Renderer.RectangleId(paintId)
	case Renderer.Circle:
		v.circleId = Renderer.CircleId(paintId)
	case Renderer.Line:
		v.lineId = Renderer.LineId(paintId)
	case Renderer.Triangle:
		v.triangleId = Renderer.TriangleId(paintId)
	case Renderer.Texture(TShapeName):
		v.textureId = Renderer.TextureId(paintId)
	}
	return
}

@(private)
@(require_results)
removePaint :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	paintUnionId: $TPaintId,
	$TElement: typeid,
) -> (
	paintCopy: Renderer.Paint(TElement, TShapeName),
	error: OdinBasePack.Error,
) where (TElement == Renderer.PaintData(TShapeName) ||
		intrinsics.type_is_variant_of(Renderer.PaintData(TShapeName), TElement)) &&
	intrinsics.type_is_variant_of(Renderer.PaintIdUnion, TPaintId) {
	defer OdinBasePack.handleError(error, "{} > #{}", typeid_of(TElement), paintUnionId)
	paintId := Renderer.PaintId(paintUnionId)
	paint, _ := getPaint(module, paintId, TElement, true) or_return
	paintCopy = paint^
	SparseSet.remove(module.renderOrder[paint.config.layer], paintId) or_return
	AutoSet.remove(module.paintAS, paintId) or_return
	return
}

@(private)
@(require_results)
setTopLeftCorner :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName),
	paintUnionId: $TPaintId,
	layer: Renderer.LayerId,
	topLeftCorner: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	order, _ := SparseSet.get(module.renderOrder[layer], paintUnionId, true) or_return
	order.topLeftCorner = topLeftCorner
	return
}
