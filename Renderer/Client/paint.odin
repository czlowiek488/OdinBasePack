package RendererClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Memory/AutoSet"
import "../../Memory/List"
import "../../Memory/SparseSet"
import "../../Renderer"
import "base:intrinsics"
import "core:math"
import "vendor:sdl3"

@(require_results)
getPaint :: proc(
	module: ^Module($TImageName, $TBitmapName),
	paintId: $TPaintId,
	$TElement: typeid,
	required: bool,
) -> (
	meta: ^Renderer.Paint(TElement),
	ok: bool,
	error: OdinBasePack.Error,
) where (TElement == Renderer.PaintData ||
		intrinsics.type_is_variant_of(Renderer.PaintData, TElement)) &&
	(intrinsics.type_is_variant_of(Renderer.PaintIdUnion, TPaintId) ||
			TPaintId == Renderer.PaintId) {
	defer OdinBasePack.handleError(error)
	metaUnion: ^Renderer.Paint(Renderer.PaintData)
	metaUnion, ok = AutoSet.get(module.paintAS, Renderer.PaintId(paintId), required) or_return
	meta = cast(^Renderer.Paint(TElement))metaUnion
	return
}

@(private)
@(require_results)
createPaint :: proc(
	module: ^Module($TImageName, $TBitmapName),
	config: Renderer.MetaConfig,
	element: $TElement,
) -> (
	paintId: Renderer.PaintId,
	paint: ^Renderer.Paint(TElement),
	error: OdinBasePack.Error,
) where intrinsics.type_is_variant_of(Renderer.PaintData, TElement) {
	defer OdinBasePack.handleError(error)
	metaUnion: ^Renderer.Paint(Renderer.PaintData)
	paintId, metaUnion = AutoSet.set(
		module.paintAS,
		Renderer.Paint(Renderer.PaintData){config, 0, {0, 0}, Renderer.PaintData(element)},
	) or_return
	paint = cast(^Renderer.Paint(TElement))metaUnion
	renderOrder: RenderOrder = {paintId, nil, config.zIndex, 0}
	renderOrder.position = calculateRenderOrder(0, renderOrder.zIndex, renderOrder.paintId)
	SparseSet.set(module.renderOrder[paint.config.layer], paintId, renderOrder) or_return
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
	case Renderer.Texture:
		v.textureId = Renderer.TextureId(paintId)
	}
	return
}

@(private)
@(require_results)
removePaint :: proc(
	module: ^Module($TImageName, $TBitmapName),
	paintUnionId: $TPaintId,
	$TElement: typeid,
) -> (
	paintCopy: Renderer.Paint(TElement),
	error: OdinBasePack.Error,
) where (TElement == Renderer.PaintData ||
		intrinsics.type_is_variant_of(Renderer.PaintData, TElement)) &&
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
updateRenderOrderPosition :: proc(
	module: ^Module($TImageName, $TBitmapName),
	paintUnionId: $TPaintId,
	onMapPosition: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	paint, _ := AutoSet.get(module.paintAS, paintUnionId, true) or_return
	order, _ := SparseSet.get(module.renderOrder[paint.config.layer], paintUnionId, true) or_return
	if paint.config.layer != .ENTITY {
		order.position = calculateRenderOrder(0, paint.config.zIndex, paintUnionId)
		return
	}
	order.position = calculateRenderOrder(onMapPosition.y, paint.config.zIndex, paintUnionId)
	// bounds: sdl3.FRect = {onMapPosition.x - 2, onMapPosition.y - 2, 4, 4}
	// sdl3.RenderRect(module.renderer, &bounds)
	return
}

@(require_results)
updateAllRenderOrder :: proc(
	module: ^Module($TImageName, $TBitmapName),
) -> (
	error: OdinBasePack.Error,
) {
	for &paint in AutoSet.getAll(module.paintAS) or_return {
		updateAllRenderOrderElement(module, &paint) or_return
	}
	return
}

@(private = "file")
@(require_results)
updateAllRenderOrderElement :: proc(
	module: ^Module($TImageName, $TBitmapName),
	paint: ^Renderer.Paint(Renderer.PaintData),
) -> (
	error: OdinBasePack.Error,
) {
	switch v in paint.element {
	case Renderer.PieMask:
		switch paint.config.positionType {
		case .CAMERA:
			updateRenderOrderPosition(
				module,
				paint.paintId,
				v.config.bounds.position + paint.offset,
			) or_return
		case .MAP:
			updateRenderOrderPosition(
				module,
				paint.paintId,
				v.config.bounds.position + paint.offset - module.camera.bounds.position,
			) or_return
		}
	case Renderer.String:
		destination: Math.Vector
		switch paint.config.positionType {
		case .CAMERA:
			destination = v.config.bounds.position + paint.offset
		case .MAP:
			destination = v.config.bounds.position + paint.offset - module.camera.bounds.position
		}
		updateRenderOrderPosition(module, paint.paintId, destination) or_return
	case Renderer.Rectangle:
		destination: Math.Vector
		switch paint.config.positionType {
		case .CAMERA:
			destination = v.config.bounds.position + paint.offset
		case .MAP:
			destination = v.config.bounds.position + paint.offset - module.camera.bounds.position
		}
		updateRenderOrderPosition(module, paint.paintId, destination) or_return
	case Renderer.Circle:
		destination: Math.Vector
		switch paint.config.positionType {
		case .CAMERA:
			destination = v.config.circle.position + paint.offset
		case .MAP:
			destination = v.config.circle.position + paint.offset - module.camera.bounds.position
		}
		updateRenderOrderPosition(
			module,
			paint.paintId,
			destination - v.config.circle.radius,
		) or_return
	case Renderer.Line:
		start, end: Math.Vector
		switch paint.config.positionType {
		case .CAMERA:
			start = v.config.start
			end = v.config.end
		case .MAP:
			start = v.config.start - module.camera.bounds.position
			end = v.config.end - module.camera.bounds.position
		}
		if start.y < end.y {
			updateRenderOrderPosition(module, paint.paintId, start) or_return
		} else if start.y > end.y {
			updateRenderOrderPosition(module, paint.paintId, end) or_return
		} else if start.x < end.x {
			updateRenderOrderPosition(module, paint.paintId, start) or_return
		} else {
			updateRenderOrderPosition(module, paint.paintId, end) or_return
		}
	case Renderer.Triangle:
		a, b, c: Math.Vector
		switch paint.config.positionType {
		case .CAMERA:
			a = v.config.triangle.a + paint.offset
			b = v.config.triangle.b + paint.offset
			c = v.config.triangle.c + paint.offset
		case .MAP:
			a = v.config.triangle.a + paint.offset - module.camera.bounds.position
			b = v.config.triangle.b + paint.offset - module.camera.bounds.position
			c = v.config.triangle.c + paint.offset - module.camera.bounds.position
		}
		leftTopCorner := a
		if b.y < leftTopCorner.y || (b.y == leftTopCorner.y && b.x < leftTopCorner.x) {
			leftTopCorner = b
		}
		if c.y < leftTopCorner.y || (c.y == leftTopCorner.y && c.x < leftTopCorner.x) {
			leftTopCorner = c
		}
		updateRenderOrderPosition(module, paint.paintId, leftTopCorner) or_return
	case Renderer.Texture:
		switch paint.config.positionType {
		case Renderer.PositionType.CAMERA:
			destination := v.config.bounds.position + paint.offset
			updateRenderOrderPosition(module, paint.paintId, destination) or_return
		case Renderer.PositionType.MAP:
			updateRenderOrderPosition(
				module,
				paint.paintId,
				v.config.staticShift +
				paint.offset -
				module.camera.bounds.position +
				(v.config.bounds.size / 2),
			) or_return
		}
	}
	return
}

@(require_results)
trackEntity :: proc(
	module: ^Module($TImageName, $TBitmapName),
	paint: ^Renderer.Paint(Renderer.PaintData),
) -> (
	error: OdinBasePack.Error,
) {
	entityId, ok := paint.config.attachedEntityId.?
	if !ok {
		return
	}
	if tracker, tracked := SparseSet.get(module.trackedEntities, entityId, false) or_return;
	   tracked {
		paint.offset = tracker.position
		List.push(&tracker.hooks, paint.paintId) or_return
	} else {
		list := List.create(Renderer.PaintId, module.allocator) or_return
		List.push(&list, paint.paintId) or_return
		SparseSet.set(module.trackedEntities, entityId, Tracker{{0, 0}, list}) or_return
	}
	return
}

@(require_results)
unTrackEntity :: proc(
	module: ^Module($TImageName, $TBitmapName),
	paint: ^Renderer.Paint($Element),
) -> (
	error: OdinBasePack.Error,
) {
	entityId, ok := paint.config.attachedEntityId.?
	if !ok {
		return
	}
	tracker, tracked := SparseSet.get(module.trackedEntities, entityId, false) or_return
	if !tracked {
		error = .PAINTER_TRACKER_WAS_NOT_DEFINED
		return
	}
	#reverse for hookId, index in tracker.hooks {
		if hookId == paint.paintId {
			List.removeAt(&tracker.hooks, index, false) or_return
		}
	}
	return
}


@(require_results)
upsertTracker :: proc(
	module: ^Module($TImageName, $TBitmapName),
	entityId: int,
	newPosition: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	tracker, ok := SparseSet.get(module.trackedEntities, entityId, false) or_return
	if ok {
		tracker.position = newPosition
		for paintId in tracker.hooks {
			paint, _ := getPaint(module, paintId, Renderer.PaintData, true) or_return
			paint.offset = tracker.position
		}
		return
	}
	list := List.create(Renderer.PaintId, module.allocator) or_return
	SparseSet.set(module.trackedEntities, entityId, Tracker{newPosition, list}) or_return
	return
}
