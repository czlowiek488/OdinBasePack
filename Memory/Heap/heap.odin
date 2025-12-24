package Heap

import "../../../OdinBasePack"

@(require_results)
allocate :: proc(
	$T: typeid,
	allocator: OdinBasePack.Allocator,
	location := #caller_location,
) -> (
	result: ^T,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	err: OdinBasePack.AllocatorError
	result, err = new(T, allocator, location)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
deAllocate :: proc(
	data: rawptr,
	allocator: OdinBasePack.Allocator,
	location := #caller_location,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	err := free(data, allocator, location)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}
