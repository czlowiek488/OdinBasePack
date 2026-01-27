package PainterClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Memory/List"
import "../../Memory/SparseSet"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
trackEntity :: proc(
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	paint: ^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName),
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
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	paint: ^Renderer.Paint($Element, TShapeName),
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
	module: ^Module($TFileImageName, $TBitmapName, $TMarkerName, $TShapeName, $TAnimationName),
	entityId: int,
	newPosition: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	tracker, ok := SparseSet.get(module.trackedEntities, entityId, false) or_return
	if ok {
		tracker.position = newPosition
		for paintId in tracker.hooks {
			paint, _ := RendererClient.getPaint(
				module.rendererModule,
				paintId,
				Renderer.PaintData(TShapeName),
				true,
			) or_return
			paint.offset = tracker.position
		}
		return
	}
	list := List.create(Renderer.PaintId, module.allocator) or_return
	SparseSet.set(module.trackedEntities, entityId, Tracker{newPosition, list}) or_return
	return
}
