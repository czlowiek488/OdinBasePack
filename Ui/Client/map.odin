package UiClient

import "../../../OdinBasePack"
import "../../Dictionary"
import "../../HitBox"
import "../../SparseSet"
import "../../Ui"


@(require_results)
createMapTile :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	config: Ui.MapTileConfig(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType),
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	err = Dictionary.set(&manager.hitBoxes, config.hitBox, HitBoxE{})
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	err = SparseSet.set(
		manager.tileSS,
		config.entityId,
		Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType){config},
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(require_results)
removeMapTile :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	entityId: HitBox.EntityId,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
	tile, _, err = SparseSet.get(manager.tileSS, entityId, true)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	if entityId == manager.hoveredEntityId {
		endMapHover(manager) or_return
	}
	err = SparseSet.remove(manager.tileSS, entityId)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	return
}

@(private)
@(require_results)
endMapHover :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	hoveredEntityId, hovered := manager.hoveredEntityId.?
	if !hovered {
		return
	}
	manager.hoveredEntityId = nil
	tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
	tile, _, err = SparseSet.get(manager.tileSS, hoveredEntityId, true)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	scheduleMapCallback(manager, tile, Ui.TileHover{false}) or_return
	return
}

@(private)
@(require_results)
startMapHover :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	entityId: HitBox.EntityId,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	if hoveredEntityId, ok := manager.hoveredEntityId.?; ok {
		if entityId == hoveredEntityId {
			return
		}
		endMapHover(manager) or_return
	}
	manager.hoveredEntityId = entityId
	tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
	tile, _, err = SparseSet.get(manager.tileSS, entityId, true)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	scheduleMapCallback(manager, tile, Ui.TileHover{true}) or_return
	return
}

@(private)
@(require_results)
scheduleMapCallback :: proc(
	manager: ^Manager(
		$TEventLoopTask,
		$TEventLoopResult,
		$TError,
		$TFileImageName,
		$TBitmapName,
		$TMarkerName,
		$TShapeName,
		$TAnimationName,
		$TEntityHitBoxType,
	),
	tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType),
	event: Ui.TileEvent,
) -> (
	error: TError,
) {
	if tile.config.onEvent == nil {
		return
	}
	tile.config.onEvent(manager.eventLoop, tile^, event) or_return
	return
}
