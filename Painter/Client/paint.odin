package PainterClient

import "../../../OdinBasePack"
import "../../Memory/List"
import "../../Memory/SparseSet"
import "../../Renderer"

@(require_results)
trackEntity :: proc(
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
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
	module: ^Module(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
	),
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
