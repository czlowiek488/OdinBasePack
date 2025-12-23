package UiClient

import "../../../OdinBasePack"
import "../../AutoSet"
import "../../HitBox"
import "../../SparseSet"
import "../../Steer"
import "../../Ui"

@(require_results)
mouseButtonUp :: proc(
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
	button: Steer.MouseButtonName,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	if _, ok := manager.click.button.?; !ok {
		return
	}
	manager.click.button = nil
	if id, ok := manager.click.id.?; ok {
		manager.click.id = nil
		switch value in id {
		case Ui.TileId:
			tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)
			tileOk: bool
			tile, tileOk, err = AutoSet.get(manager.tileAS, value, false)
			if err != .NONE {
				error = manager.eventLoop.mapper(err)
				return
			}
			if !tileOk {
				return
			}
			scheduleCameraCallback(manager, tile, Ui.TileClick{false}) or_return
		case HitBox.EntityId:
			tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
			tileOk: bool
			tile, tileOk, err = SparseSet.get(manager.tileSS, value, false)
			if err != .NONE {
				error = manager.eventLoop.mapper(err)
				return
			}
			if !tileOk {
				return
			}
			scheduleMapCallback(manager, tile, Ui.TileClick{false}) or_return
		}
	}
	return
}

@(require_results)
mouseButtonDown :: proc(
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
	button: Steer.MouseButtonName,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	if _, ok := manager.click.button.?; ok {
		return
	}
	manager.click.button = button
	if hoveredTile, ok := manager.hoveredTile.?; ok {
		manager.click.id = hoveredTile.tileId
		tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)
		tile, _, err = AutoSet.get(manager.tileAS, hoveredTile.tileId, true)
		if err != .NONE {
			error = manager.eventLoop.mapper(err)
			return
		}
		scheduleCameraCallback(manager, tile, Ui.TileClick{true}) or_return
		return
	}
	if entityId, ok := manager.hoveredEntityId.?; ok {
		manager.click.id = entityId
		tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
		tile, _, err = SparseSet.get(manager.tileSS, entityId, true)
		if err != .NONE {
			error = manager.eventLoop.mapper(err)
			return
		}
		scheduleMapCallback(manager, tile, Ui.TileClick{true}) or_return
		return
	}
	return
}
