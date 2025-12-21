package RendererClient

import "../../../../OdinBasePack"
import "../../../AutoSet"
import "../../../SparseSet"
import "../../Renderer"
import "base:intrinsics"

@(require_results)
getPaint :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	paintId: $TPaintId,
	$TElement: typeid,
	required: bool,
) -> (
	meta: ^Renderer.Paint(TElement, TShapeName, TAnimationName),
	ok: bool,
	error: OdinBasePack.Error,
) where (TElement == Renderer.PaintData(TShapeName, TAnimationName) ||
		intrinsics.type_is_variant_of(Renderer.PaintData(TShapeName, TAnimationName), TElement)) &&
	(intrinsics.type_is_variant_of(Renderer.PaintIdUnion, TPaintId) ||
			TPaintId == Renderer.PaintId) {
	defer OdinBasePack.handleError(error)
	metaUnion: ^Renderer.Paint(
		Renderer.PaintData(TShapeName, TAnimationName),
		TShapeName,
		TAnimationName,
	)
	metaUnion, ok = AutoSet.get(manager.paintAS, Renderer.PaintId(paintId), required) or_return
	meta = cast(^Renderer.Paint(TElement, TShapeName, TAnimationName))metaUnion
	return
}

@(private)
@(require_results)
createPaint :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	config: Renderer.MetaConfig,
	element: $TElement,
) -> (
	paintId: Renderer.PaintId,
	paint: ^Renderer.Paint(TElement, TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) where intrinsics.type_is_variant_of(Renderer.PaintData(TShapeName, TAnimationName), TElement) {
	defer OdinBasePack.handleError(error)
	metaUnion: ^Renderer.Paint(
		Renderer.PaintData(TShapeName, TAnimationName),
		TShapeName,
		TAnimationName,
	)
	paintId, metaUnion = AutoSet.set(
		manager.paintAS,
		Renderer.Paint(
			Renderer.PaintData(TShapeName, TAnimationName),
			TShapeName,
			TAnimationName,
		){config, 0, {0, 0}, Renderer.PaintData(TShapeName, TAnimationName)(element)},
	) or_return
	paint = cast(^Renderer.Paint(TElement, TShapeName, TAnimationName))metaUnion
	SparseSet.set(manager.renderOrder[paint.config.layer], paintId, RenderOrder{paintId}) or_return
	paint.paintId = paintId
	switch &v in &metaUnion.element {
	case Renderer.Animation(TShapeName, TAnimationName):
		v.animationId = Renderer.AnimationId(paintId)
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
	}
	return
}

@(private)
@(require_results)
removePaint :: proc(
	manager: ^Manager($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	paintUnionId: $TPaintId,
	$TElement: typeid,
) -> (
	paintCopy: Renderer.Paint(TElement, TShapeName, TAnimationName),
	error: OdinBasePack.Error,
) where (TElement == Renderer.PaintData(TShapeName, TAnimationName) ||
		intrinsics.type_is_variant_of(Renderer.PaintData(TShapeName, TAnimationName), TElement)) &&
	intrinsics.type_is_variant_of(Renderer.PaintIdUnion, TPaintId) {
	defer OdinBasePack.handleError(error)
	paintId := Renderer.PaintId(paintUnionId)
	paint, _ := getPaint(manager, paintId, TElement, true) or_return
	paintCopy = paint^
	SparseSet.remove(manager.renderOrder[paint.config.layer], paintId) or_return
	AutoSet.remove(manager.paintAS, paintId) or_return
	return
}
