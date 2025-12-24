package HitBoxClient

import "../../../../OdinBasePack"
import "../../../Drawer/Painter"
import PainterClient "../../../Drawer/Painter/Client"
import "../../../Math"
import "../../../Memory/Dictionary"
import "../../../Memory/IdPicker"
import "../../../Memory/List"
import "../../../Memory/SparseSet"
import "../../../Memory/SpatialGrid"
import "../../HitBox"

@(private = "file")
@(require_results)
create :: proc(
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
	entityId: HitBox.EntityId,
) -> (
	entityHitBox: HitBox.EntityHitBox(TEntityHitBoxType),
) {
	for _, type in entityHitBox.hitBoxList {
		entityHitBox.hitBoxList[type] = {}
	}
	entityHitBox.entityId = entityId
	return
}


@(require_results)
add :: proc(
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
	entityId: HitBox.EntityId,
	hitBox: Math.Geometry,
	type: TEntityHitBoxType,
	position: Math.Vector,
	offset: Math.Vector,
) -> (
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	if entityId == -1 {
		error = .ENTITY_ID_MUST_NOT_BE_LOWER_THAN_0
		return
	}
	hitBoxEntryId: HitBox.HitBoxId
	hitBoxEntryId, err = IdPicker.get(&module.hitBoxIdPicker)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	hitBoxEntry := HitBox.HitBoxEntry(TEntityHitBoxType) {
		hitBoxEntryId,
		entityId,
		hitBox,
		position,
		offset,
		type,
		nil,
		0,
	}
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType)
	present: bool
	entityHitBox, present, err = getEntityHitBox(module, entityId, false)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if present {
		err = List.push(&entityHitBox.hitBoxList[type].hitBoxEntryList, hitBoxEntry)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		insertHitBoxToGrid(module, &module.gridTypeSlice[type], &hitBoxEntry) or_return
		return
	}
	newEntityHitBox := create(module, entityId)
	err = List.push(&newEntityHitBox.hitBoxList[type].hitBoxEntryList, hitBoxEntry)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	err = SparseSet.set(module.entityHitBoxSS, entityId, newEntityHitBox)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	insertHitBoxToGrid(module, &module.gridTypeSlice[type], &hitBoxEntry) or_return
	return
}

// @(private)
@(require_results)
getEntityHitBox :: proc(
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
	entityId: HitBox.EntityId,
	required: bool,
) -> (
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType),
	entityHitBoxPresent: bool,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error, "entityId = {} - required = {}", entityId, required)
	entityHitBox, entityHitBoxPresent = SparseSet.get(
		module.entityHitBoxSS,
		entityId,
		required,
	) or_return
	return
}

@(require_results)
remove :: proc(
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
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
	required: bool = true,
) -> (
	error: TError,
) {
	entityHitBox, ok, err := getEntityHitBox(module, entityId, required)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if !ok {
		return
	}
	hitBoxEntryList := &entityHitBox.hitBoxList[type]
	removeHitBoxEntryList(module, hitBoxEntryList) or_return
	clear(&hitBoxEntryList.hitBoxEntryList)
	return
}

@(require_results)
move :: proc(
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
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
	change: Math.Vector,
) -> (
	error: TError,
) {
	entityHitBox, entityHitBoxPresent, err := getEntityHitBox(module, entityId, false)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if !entityHitBoxPresent {
		return
	}
	for &hitBoxEntry in &entityHitBox.hitBoxList[type].hitBoxEntryList {
		removeHitBoxFromGrid(module, &module.gridTypeSlice[type], &hitBoxEntry) or_return
		hitBoxEntry.position += change
		insertHitBoxToGrid(module, &module.gridTypeSlice[type], &hitBoxEntry) or_return
	}
	return
}

@(require_results)
isEntryPresent :: proc(
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
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
) -> (
	present: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	entity: ^HitBox.EntityHitBox(TEntityHitBoxType)
	entity, present, err = getEntityHitBox(module, entityId, false)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if !present {
		return
	}
	if len(entity.hitBoxList[type].hitBoxEntryList) == 0 {
		present = false
	}
	return
}

@(require_results)
getCenter :: proc(
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
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
	required: bool,
) -> (
	center: Math.Vector,
	present: bool,
	error: TError,
) {
	err: OdinBasePack.Error
	defer OdinBasePack.handleError(err)
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType)
	entityHitBox, present, err = getEntityHitBox(module, entityId, required)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if !present {
		return
	}
	hitBoxEntryList := &entityHitBox.hitBoxList[type]
	if len(hitBoxEntryList.hitBoxEntryList) == 0 {
		if required {
			error = .HIT_BOX_MUST_HAVE_AT_LEAST_ONE_ENTRY
		}
		return
	}
	absFirstHitBox := getAbsoluteHitBox(&hitBoxEntryList.hitBoxEntryList[0])
	min, max := Math.getGeometryAABB(absFirstHitBox)
	if len(hitBoxEntryList.hitBoxEntryList) == 1 {
		center = min + ((max - min) / 2)
		return
	}
	for &hitBoxEntry, index in hitBoxEntryList.hitBoxEntryList {
		if index == 0 {
			continue
		}
		absHitBox := getAbsoluteHitBox(&hitBoxEntry)
		localMin, localMax := Math.getGeometryAABB(absHitBox)
		if localMin.x < min.x {min.x = localMin.x}
		if localMin.y < min.y {min.y = localMin.y}
		if localMax.x > max.x {max.x = localMax.x}
		if localMax.y > max.y {max.y = localMax.y}
	}
	center = min + ((max - min) / 2)
	return
}

@(private)
@(require_results)
insertHitBoxToGrid :: proc(
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
	grid: ^SpatialGrid.Grid(
		HitBox.HitBoxId,
		HitBox.HitBoxEntry(TEntityHitBoxType),
		HitBox.HitBoxCellMeta,
	),
	hitBoxEntry: ^HitBox.HitBoxEntry(TEntityHitBoxType),
) -> (
	error: TError,
) {
	geometry := getAbsoluteHitBox(hitBoxEntry)
	config := &module.hitBoxGridDraw[hitBoxEntry.type]
	newCellList, err := SpatialGrid.insertEntry(
		grid,
		geometry,
		hitBoxEntry.id,
		hitBoxEntry^,
		context.temp_allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	if !config.enabled {
		return
	}
	for cell in newCellList {
		entry, _, err := Dictionary.get(cell.entries, hitBoxEntry.id, true)
		if err != .NONE {
			error = module.eventLoop.mapper(err)
			return
		}
		if config.gridCell {
			if _, ok := cell.meta.rectangleId.?; !ok {
				cell.meta.rectangleId = PainterClient.createRectangle(
					module.painterModule,
					{.PANEL_0, nil, .MAP, Painter.getColorFromName(config.color)},
					{
						.BORDER,
						{cell.position, {f32(grid.config.cellSize), f32(grid.config.cellSize)}},
					},
				) or_return
			}
		}
		if config.hitBox {
			switch value in geometry {
			case Math.Circle:
				entry.geometryId = PainterClient.createCircle(
					module.painterModule,
					{.PANEL_0, nil, .MAP, Painter.getColorFromName(config.color)},
					{value, 0, 0},
				) or_return
			case Math.Rectangle:
				entry.geometryId = PainterClient.createRectangle(
					module.painterModule,
					{.PANEL_0, nil, .MAP, Painter.getColorFromName(config.color)},
					{.BORDER, value},
				) or_return
			case Math.Triangle:
				entry.geometryId = PainterClient.createTriangle(
					module.painterModule,
					{.PANEL_0, nil, .MAP, Painter.getColorFromName(config.color)},
					{value},
				) or_return
			}
		}
		if config.gridCellConnection {
			min, _ := Math.getGeometryAABB(geometry)
			entry.lineId = PainterClient.createLine(
				module.painterModule,
				{.PANEL_0, nil, .MAP, Painter.getColorFromName(config.color)},
				{cell.position, min},
			) or_return
		}
	}

	return
}


@(private)
@(require_results)
removeHitBoxFromGrid :: proc(
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
	grid: ^SpatialGrid.Grid(
		HitBox.HitBoxId,
		HitBox.HitBoxEntry(TEntityHitBoxType),
		HitBox.HitBoxCellMeta,
	),
	hitBoxEntry: ^HitBox.HitBoxEntry(TEntityHitBoxType),
) -> (
	error: TError,
) {
	removedEntries, removedCells, err := SpatialGrid.removeFromGrid(
		grid,
		hitBoxEntry.id,
		context.temp_allocator,
	)
	if err != .NONE {
		error = module.eventLoop.mapper(err)
		return
	}
	for entry in removedEntries {
		switch value in entry.geometryId {
		case Painter.CircleId:
			if value == 0 {
				continue
			}
			PainterClient.removeCircle(module.painterModule, value) or_return
		case Painter.RectangleId:
			if value == 0 {
				continue
			}
			PainterClient.removeRectangle(module.painterModule, value) or_return
		case Painter.TriangleId:
			if value == 0 {
				continue
			}
			PainterClient.removeTriangle(module.painterModule, value) or_return
		}
		if entry.lineId == 0 {
			continue
		}
		PainterClient.removeLine(module.painterModule, entry.lineId) or_return
	}
	for meta in removedCells {
		if rectangleId, present := meta.rectangleId.?; present {
			PainterClient.removeRectangle(module.painterModule, rectangleId) or_return
		}
	}
	return
}
