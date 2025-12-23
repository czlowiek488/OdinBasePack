package UiClient

import "../../../OdinBasePack"
import "../../Dictionary"
import "../../Drawer/Painter"
import PainterClient "../../Drawer/Painter/Client"
import "../../Drawer/Renderer"
import "../../HitBox"
import HitBoxClient "../../HitBox/Client"
import "../../List"
import "../../Math"
import "../../SparseSet"
import "../../SpatialGrid"
import SteerClient "../../Steer/Client"
import "../../Ui"


@(private)
@(require_results)
getCurrentTileColor :: proc(
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
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
) -> (
	color: Ui.Color,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	switch v in tile.config.renderConfig {
	case Painter.AnimationConfig:
		animation, _ := PainterClient.getAnimation(
			manager.painterManager,
			Painter.AnimationId(tile.painterRenderId),
			true,
		) or_return
		color = animation.config.metaConfig.color
	case Painter.RectangleConfig:
		meta, _ := PainterClient.getRectangle(
			manager.painterManager,
			Painter.RectangleId(tile.painterRenderId),
			true,
		) or_return
		color = meta.config.color
	}
	return
}


@(private)
@(require_results)
setCurrentTileColor :: proc(
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
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
	color: Renderer.Color,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	switch v in tile.config.renderConfig {
	case Painter.AnimationConfig(TAnimationName):
		animation, _ := PainterClient.getAnimation(
			manager.painterManager,
			Painter.AnimationId(tile.painterRenderId),
			true,
		) or_return
		copied := animation^
		PainterClient.removeAnimation(
			manager.painterManager,
			Painter.AnimationId(tile.painterRenderId),
		) or_return
		copied.config.metaConfig.color = color
		tile.painterRenderId = Ui.PainterRenderId(
			PainterClient.setAnimation(manager.painterManager, copied.config) or_return,
		)
	case Renderer.RectangleConfig:
		meta, _ := PainterClient.getRectangle(
			manager.painterManager,
			Painter.RectangleId(tile.painterRenderId),
			true,
		) or_return
		meta.config.color = color
	}
	return
}

@(require_results)
tick :: proc(
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
	mousePositionOnScreen := SteerClient.getMousePositionOnScreen(manager.steerManager) or_return
	cameraEntries: map[Ui.TileId]Ui.TileGridEntry
	cameraEntries, err = SpatialGrid.query(
		&manager.tileGrid,
		Math.Circle{mousePositionOnScreen, .5},
		context.temp_allocator,
	)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	switch len(cameraEntries) {
	case 0:
		endCameraHover(manager) or_return
	case 1:
		ids: []Ui.TileId
		ids, err = Dictionary.getKeys(cameraEntries, context.temp_allocator)
		if err != .NONE {
			error = manager.eventLoop.mapper(err)
			return
		}
		startCameraHover(manager, ids[0]) or_return
	case:
		error = .UI_TILES_MUST_NOT_OVERLAP
	}
	if hoveredTileId, ok := manager.hoveredTile.?; ok {
		return
	}
	hoveredEntityId := getCurrentHoveredEntityId(manager) or_return
	if entityId, ok := hoveredEntityId.?; ok {
		startMapHover(manager, entityId) or_return
		return
	}
	endMapHover(manager) or_return
	return
}


@(private = "file")
@(require_results)
getCurrentHoveredEntityId :: proc(
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
	entityId: Maybe(HitBox.EntityId),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	hoveredEntityList: [dynamic]HitBox.EntityId
	hoveredEntityList, err = List.create(HitBox.EntityId, context.temp_allocator)
	if err != .NONE {
		error = manager.eventLoop.mapper(err)
		return
	}
	mousePositionOnMap := SteerClient.getMousePositionOnMap(manager.steerManager) or_return
	uiMapTile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
	ok: bool
	for hitBoxType in manager.hitBoxes {
		mapEntries := HitBoxClient.queryEntitiesInRange(
			manager.hitBoxManager,
			hitBoxType,
			mousePositionOnMap,
			1,
		) or_return
		for entry in mapEntries {
			uiMapTile, ok, err = SparseSet.get(manager.tileSS, entry.entityId, false)
			if err != .NONE {
				error = manager.eventLoop.mapper(err)
				return
			}
			if ok {
				if manager.hoveredEntityId == entry.entityId {
					entityId = entry.entityId
					return
				}
				err = List.push(&hoveredEntityList, entry.entityId)
				if err != .NONE {
					error = manager.eventLoop.mapper(err)
					return
				}
			}
		}
	}
	if len(hoveredEntityList) > 0 {
		entityId = hoveredEntityList[0]
	}
	return
}
