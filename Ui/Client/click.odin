package UiClient

import "../../../OdinBasePack"
import "../../HitBox"
import "../../Memory/AutoSet"
import "../../Memory/SparseSet"
import "../../Steer"
import "../../Ui"

@(require_results)
mouseButtonUp :: proc(
	module: ^Module(
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
	if _, ok := module.click.button.?; !ok {
		return
	}
	module.click.button = nil
	if id, ok := module.click.id.?; ok {
		module.click.id = nil
		switch value in id {
		case Ui.TileId:
			tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)
			tileOk: bool
			tile, tileOk, err = AutoSet.get(module.tileAS, value, false)
			if err != .NONE {
				error = module.eventLoop.mapper(err)
				return
			}
			if !tileOk {
				return
			}
			scheduleCameraCallback(module, tile, Ui.TileClick{false}) or_return
		case HitBox.EntityId:
			tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
			tileOk: bool
			tile, tileOk, err = SparseSet.get(module.tileSS, value, false)
			if err != .NONE {
				error = module.eventLoop.mapper(err)
				return
			}
			if !tileOk {
				return
			}
			scheduleMapCallback(module, tile, Ui.TileClick{false}) or_return
		}
	}
	return
}

@(require_results)
mouseButtonDown :: proc(
	module: ^Module(
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
	if _, ok := module.click.button.?; ok {
		return
	}
	module.click.button = button
	if hoveredTile, ok := module.hoveredTile.?; ok {
		module.click.id = hoveredTile.tileId
		tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName)
		tile, _, err = AutoSet.get(module.tileAS, hoveredTile.tileId, true)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		scheduleCameraCallback(module, tile, Ui.TileClick{true}) or_return
		return
	}
	if entityId, ok := module.hoveredEntityId.?; ok {
		module.click.id = entityId
		tile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
		tile, _, err = SparseSet.get(module.tileSS, entityId, true)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		scheduleMapCallback(module, tile, Ui.TileClick{true}) or_return
		return
	}
	return
}
