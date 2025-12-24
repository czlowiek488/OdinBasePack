package IdPicker

import "../../../OdinBasePack"
import "../List"
import "base:intrinsics"


IdPicker :: struct($TId: typeid) {
	highestId:  TId,
	freeIdList: [dynamic]TId,
	started:    bool,
}

@(require_results)
create :: proc(
	idPicker: ^IdPicker($TId),
	allocator: OdinBasePack.Allocator,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	when !intrinsics.type_is_integer(
		TId,
	) && !intrinsics.type_is_integer(intrinsics.type_core_type(TId)) && !intrinsics.type_is_integer(intrinsics.type_base_type(TId)) {

		#panic("id picker must be attached with integer type")
	}
	if idPicker.freeIdList != nil {
		error = .HIT_BOX_FREE_ID_LIST_ALREADY_INITIALIZED
		return
	}
	idPicker.started = true
	idPicker.freeIdList = List.create(TId, allocator) or_return
	return
}

@(require_results)
get :: proc(idPicker: ^IdPicker($TId)) -> (id: TId, error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error)
	if !idPicker.started {
		error = .STRUCTURE_ID_PICKER_IS_NOT_STARTED
		return
	}
	if len(idPicker.freeIdList) > 0 {
		id = pop(&idPicker.freeIdList)
		return
	}
	idPicker.highestId += 1
	id = idPicker.highestId
	return
}

@(require_results)
freeId :: proc(idPicker: ^IdPicker($TId), idToFree: TId) -> (error: OdinBasePack.Error) {
	defer OdinBasePack.handleError(error)
	if !idPicker.started {
		error = .STRUCTURE_ID_PICKER_IS_NOT_STARTED
		return
	}
	List.push(&idPicker.freeIdList, idToFree) or_return
	return
}

@(require_results)
destroy :: proc(
	idPicker: ^IdPicker($TId),
	allocator: OdinBasePack.Allocator,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	if !idPicker.started {
		error = .STRUCTURE_ID_PICKER_IS_NOT_STARTED
		return
	}
	err := delete(idPicker.freeIdList)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}
