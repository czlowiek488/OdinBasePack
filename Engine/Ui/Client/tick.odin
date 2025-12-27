package UiClient

import "../../../../OdinBasePack"
import "../../../Drawer/Painter"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../Drawer/Renderer"
import "../../../Math"
import "../../../Memory/Dictionary"
import "../../../Memory/List"
import "../../../Memory/SparseSet"
import "../../../Memory/SpatialGrid"
import "../../HitBox"
import HitBoxClient "../../HitBox/Client"
import SteerClient "../../Steer/Client"
import "../../Ui"


@(private)
@(require_results)
getCurrentTileColor :: proc(
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
	tile: ^Ui.CameraTile(TEventLoopTask, TEventLoopResult, TError, TAnimationName),
) -> (
	color: Ui.Color,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	switch v in tile.config.renderConfig {
	case Painter.AnimationConfig:
		animation, _ := PainterClient.getAnimation(
			module.painterModule,
			Painter.AnimationId(tile.painterRenderId),
			true,
		) or_return
		color = animation.config.metaConfig.color
	case Painter.RectangleConfig:
		meta, _ := PainterClient.getRectangle(
			module.painterModule,
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
			module.painterModule,
			Painter.AnimationId(tile.painterRenderId),
			true,
		) or_return
		copied := animation^
		PainterClient.removeAnimation(
			module.painterModule,
			Painter.AnimationId(tile.painterRenderId),
		) or_return
		copied.config.metaConfig.color = color
		tile.painterRenderId = Ui.PainterRenderId(
			PainterClient.setAnimation(module.painterModule, copied.config) or_return,
		)
	case Renderer.RectangleConfig:
		meta, _ := PainterClient.getRectangle(
			module.painterModule,
			Painter.RectangleId(tile.painterRenderId),
			true,
		) or_return
		meta.config.color = color
	}
	return
}

@(require_results)
tick :: proc(
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
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	mousePositionOnScreen := SteerClient.getMousePositionOnScreen(module.steerModule) or_return
	cameraEntries: map[Ui.TileId]Ui.TileGridEntry
	cameraEntries, err = SpatialGrid.query(
		&module.tileGrid,
		Math.Circle{mousePositionOnScreen, .5},
		context.temp_allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if len(cameraEntries) == 0 {
		endCameraHover(module) or_return
	} else {
		highestZIndex: Renderer.ZIndex = -1
		highestTileId: Ui.TileId
		for tileId, entry in cameraEntries {
			if entry.zIndex == highestZIndex {
				error = .UI_TILES_MUST_NOT_OVERLAP
				return
			}
			if entry.zIndex < highestZIndex {
				continue
			}
			highestZIndex = entry.zIndex
			highestTileId = tileId
		}
		startCameraHover(module, highestTileId) or_return
	}
	if hoveredTileId, ok := module.hoveredTile.?; ok {
		return
	}
	hoveredEntityId := getCurrentHoveredEntityId(module) or_return
	if entityId, ok := hoveredEntityId.?; ok {
		startMapHover(module, entityId) or_return
		return
	}
	endMapHover(module) or_return
	return
}


@(private = "file")
@(require_results)
getCurrentHoveredEntityId :: proc(
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
) -> (
	entityId: Maybe(HitBox.EntityId),
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	hoveredEntityList: [dynamic]HitBox.EntityId
	hoveredEntityList, err = List.create(HitBox.EntityId, context.temp_allocator)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	mousePositionOnMap := SteerClient.getMousePositionOnMap(module.steerModule) or_return
	uiMapTile: ^Ui.MapTile(TEventLoopTask, TEventLoopResult, TError, TEntityHitBoxType)
	ok: bool
	for hitBoxType in module.hitBoxes {
		mapEntries := HitBoxClient.queryEntitiesInRange(
			module.hitBoxModule,
			hitBoxType,
			mousePositionOnMap,
			1,
		) or_return
		for entry in mapEntries {
			uiMapTile, ok, err = SparseSet.get(module.tileSS, entry.entityId, false)
			if err != .NONE {
				error = module.eventLoop.mapper(err)
				return
			}
			if ok {
				if module.hoveredEntityId == entry.entityId {
					entityId = entry.entityId
					return
				}
				err = List.push(&hoveredEntityList, entry.entityId)
				if err != .NONE {
					error = module.eventLoop.mapper(err)
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
