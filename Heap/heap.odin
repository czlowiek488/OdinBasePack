package Heap

import BasePack "../"

@(require_results)
allocate :: proc(
	$T: typeid,
	allocator: BasePack.Allocator,
	location := #caller_location,
) -> (
	result: ^T,
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	err: BasePack.AllocatorError
	result, err = new(T, allocator, location)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
deAllocate :: proc(
	data: rawptr,
	allocator: BasePack.Allocator,
	location := #caller_location,
) -> (
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	err := free(data, allocator, location)
	BasePack.parseAllocatorError(err) or_return
	return
}
