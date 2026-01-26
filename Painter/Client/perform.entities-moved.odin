package PainterClient

import "../../../OdinBasePack"
import "../../Math"
import "../../Memory/List"
import "../../Memory/SparseSet"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
moveEntity :: proc(
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

@(require_results)
entitiesMovedPerform :: proc(
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
	input: Painter.EntitiesMovedEvent,
) -> (
	error: TError,
) {
	paint: ^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName)
	for index in 0 ..< input.count {
		err := moveEntity(module, input.list[index].entityId, input.list[index].newPosition)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
		}
	}
	return
}
