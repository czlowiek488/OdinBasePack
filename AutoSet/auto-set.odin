package AutoSet

import BasePack "../"
import "../Heap"
import "../IdPicker"
import "../SparseSet"

AutoSet :: struct($TId: typeid, $TData: typeid) {
	created:  bool,
	idPicker: IdPicker.IdPicker(TId),
	ssAuto:   ^SparseSet.SparseSet(TId, TData),
}


@(require_results)
create :: proc(
	$TId: typeid,
	$TData: typeid,
	allocator: BasePack.Allocator,
) -> (
	autoSet: ^AutoSet(TId, TData),
	error: BasePack.Error,
) {
	defer BasePack.handleError(error, "TId = {} - TData = {}", typeid_of(TId), typeid_of(TData))
	autoSet = Heap.allocate(AutoSet(TId, TData), allocator) or_return
	autoSet.created = true
	autoSet.ssAuto = SparseSet.create(TId, TData, allocator) or_return
	IdPicker.create(&autoSet.idPicker, allocator) or_return
	return
}

@(require_results)
set :: proc(
	autoSet: ^AutoSet($TId, $TData),
	autoData: TData,
) -> (
	autoId: TId,
	result: ^TData,
	error: BasePack.Error,
) {
	defer BasePack.handleError(error, "autoData = {}", autoData)
	if !autoSet.created {
		error = .AUTO_SET_IS_NOT_CREATED
		return
	}
	autoId = IdPicker.get(&autoSet.idPicker) or_return
	SparseSet.set(autoSet.ssAuto, autoId, autoData) or_return
	result, _ = SparseSet.get(autoSet.ssAuto, autoId, true) or_return
	return
}

@(require_results)
remove :: proc(autoSet: ^AutoSet($TId, $TData), autoId: TId) -> (error: BasePack.Error) {
	defer BasePack.handleError(error, "autoId = {}", autoId)
	if !autoSet.created {
		error = .AUTO_SET_IS_NOT_CREATED
		return
	}
	IdPicker.freeId(&autoSet.idPicker, autoId) or_return
	SparseSet.unset(autoSet.ssAuto, autoId) or_return
	return
}

@(require_results)
get :: proc(
	autoSet: ^AutoSet($TId, $TData),
	autoId: TId,
	required: bool,
) -> (
	autoData: ^TData,
	autoDataPresent: bool,
	error: BasePack.Error,
) {
	defer BasePack.handleError(
		error,
		"autoId = {} - required = {} - type = {}",
		autoId,
		required,
		typeid_of(TData),
	)
	if !autoSet.created {
		error = .AUTO_SET_IS_NOT_CREATED
		return
	}
	autoData, autoDataPresent = SparseSet.get(autoSet.ssAuto, autoId, required) or_return
	return

}

@(require_results)
getAll :: proc(
	autoSet: ^AutoSet($TId, $TData),
) -> (
	autoDataList: ^[dynamic]TData,
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	if !autoSet.created {
		error = .AUTO_SET_IS_NOT_CREATED
		return
	}
	autoDataList = SparseSet.list(autoSet.ssAuto) or_return
	return
}

@(require_results)
destroy :: proc(
	autoSet: ^AutoSet($TId, $TData),
	allocator: BasePack.Allocator,
) -> (
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	if !autoSet.created {
		error = .AUTO_SET_IS_NOT_CREATED
		return
	}
	SparseSet.destroy(autoSet.ssAuto, allocator) or_return
	IdPicker.destroy(&autoSet.idPicker, allocator) or_return
	Heap.deAllocate(autoSet, allocator) or_return
	return
}
