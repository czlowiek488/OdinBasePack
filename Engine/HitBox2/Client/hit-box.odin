package HitBox3Client2

import "../../../../OdinBasePack"
import "../../../Math"
import "../../../Memory/Dictionary"
import "../../../Memory/IdPicker"
import "../../../Memory/List"
import "../../../Memory/SparseSet"
import "../../../Memory/SpatialGrid"
import HitBox "../../HitBox2"
import "core:log"

@(private = "file")
@(require_results)
create :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
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
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
	hitBox: Math.Geometry,
	type: TEntityHitBoxType,
	position: Math.Vector,
	offset: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	if entityId == -1 {
		error = OdinBasePack.Error.ENTITY_ID_MUST_NOT_BE_LOWER_THAN_0
		return
	}
	hitBoxEntryId: HitBox.HitBoxId
	hitBoxEntryId = IdPicker.get(module.hitBoxIdPicker) or_return
	hitBoxEntry := HitBox.HitBoxEntry(TEntityHitBoxType) {
		hitBoxEntryId,
		entityId,
		hitBox,
		position,
		offset,
		type,
	}
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType)
	present: bool
	entityHitBox, present = getEntityHitBox(module, entityId, false) or_return
	if present {
		List.push(&entityHitBox.hitBoxList[type].hitBoxEntryList, hitBoxEntry) or_return
		insertHitBoxToGrid(module, &module.gridTypeSlice[type], &hitBoxEntry) or_return
		return
	}
	newEntityHitBox := create(module, entityId)
	List.push(&newEntityHitBox.hitBoxList[type].hitBoxEntryList, hitBoxEntry) or_return
	SparseSet.set(module.entityHitBoxSS, entityId, newEntityHitBox) or_return
	insertHitBoxToGrid(module, &module.gridTypeSlice[type], &hitBoxEntry) or_return
	return
}

// @(private)
@(require_results)
getEntityHitBox :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
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
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
	required: bool = true,
) -> (
	error: OdinBasePack.Error,
) {
	entityHitBox, ok := getEntityHitBox(module, entityId, required) or_return
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
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
	change: Math.Vector,
) -> (
	error: OdinBasePack.Error,
) {
	entityHitBox, entityHitBoxPresent := getEntityHitBox(module, entityId, false) or_return
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
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
) -> (
	present: bool,
	error: OdinBasePack.Error,
) {
	entity: ^HitBox.EntityHitBox(TEntityHitBoxType)
	entity, present = getEntityHitBox(module, entityId, false) or_return
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
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	entityId: HitBox.EntityId,
	type: TEntityHitBoxType,
	required: bool,
) -> (
	center: Math.Vector,
	present: bool,
	error: OdinBasePack.Error,
) {
	entityHitBox: ^HitBox.EntityHitBox(TEntityHitBoxType)
	entityHitBox, present = getEntityHitBox(module, entityId, required) or_return
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
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	grid: ^SpatialGrid.Grid(
		HitBox.HitBoxId,
		HitBox.HitBoxEntry(TEntityHitBoxType),
		HitBox.HitBoxCellMeta,
	),
	hitBoxEntry: ^HitBox.HitBoxEntry(TEntityHitBoxType),
) -> (
	error: OdinBasePack.Error,
) {
	geometry := getAbsoluteHitBox(hitBoxEntry)
	newCellList := SpatialGrid.insertEntry(
		grid,
		geometry,
		hitBoxEntry.id,
		hitBoxEntry^,
		context.temp_allocator,
	) or_return
	module.eventLoop->microTask(
		HitBox.HitBoxEvent(TEntityHitBoxType)(
		HitBox.HitBoxCreatedEvent(TEntityHitBoxType){hitBoxEntry.id, hitBoxEntry.type, geometry},
		),
	) or_return
	return
}


@(private)
@(require_results)
removeHitBoxFromGrid :: proc(
	module: ^Module($TEventLoopTask, $TEventLoopResult, $TEntityHitBoxType),
	grid: ^SpatialGrid.Grid(
		HitBox.HitBoxId,
		HitBox.HitBoxEntry(TEntityHitBoxType),
		HitBox.HitBoxCellMeta,
	),
	hitBoxEntry: ^HitBox.HitBoxEntry(TEntityHitBoxType),
) -> (
	error: OdinBasePack.Error,
) {
	_, _ = SpatialGrid.removeFromGrid(grid, hitBoxEntry.id, context.temp_allocator) or_return
	module.eventLoop->microTask(
		HitBox.HitBoxEvent(TEntityHitBoxType)(HitBox.HitBoxRemovedEvent{hitBoxEntry.id}),
	) or_return
	return
}
