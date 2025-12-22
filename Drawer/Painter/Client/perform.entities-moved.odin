package PainterClient

import "../../../../OdinBasePack"
import "../../../List"
import "../../../SparseSet"
import "../../Painter"
import "../../Renderer"
import RendererClient "../../Renderer/Client"

@(require_results)
entitiesMovedPerform :: proc(
	manager: ^Manager(
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
	err: OdinBasePack.Error
	paint: ^Renderer.Paint(Renderer.PaintData(TShapeName), TShapeName)
	tracker: ^Tracker
	ok: bool
	for index in 0 ..< input.count {
		tracker, ok, err = SparseSet.get(
			manager.trackedEntities,
			input.list[index].entityId,
			false,
		)
		if err != .NONE {
			error = manager.eventLoop.mapper(err)
			return
		}
		if ok {
			tracker.position = input.list[index].newPosition
			for paintId in tracker.hooks {
				paint, _, err = RendererClient.getPaint(
					manager.rendererManager,
					paintId,
					Renderer.PaintData(TShapeName),
					true,
				)
				if err != .NONE {
					error = manager.eventLoop.mapper(err)
					return
				}
				paint.offset = tracker.position
			}
			continue
		}
		list: [dynamic]Renderer.PaintId
		list, err = List.create(Renderer.PaintId, manager.allocator)
		if err != .NONE {
			error = manager.eventLoop.mapper(err)
			return
		}
		err = SparseSet.set(
			manager.trackedEntities,
			input.list[index].entityId,
			Tracker{input.list[index].newPosition, list},
		)
		if err != .NONE {
			error = manager.eventLoop.mapper(err)
			return
		}
	}
	return
}
