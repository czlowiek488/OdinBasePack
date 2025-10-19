package Text

import BasePack "../"
import "core:strings"

@(require_results)
fromBytes :: proc(
	bytes: []byte,
	allocator: BasePack.Allocator,
) -> (
	result: string,
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	err: BasePack.AllocatorError
	result, err = strings.clone_from_bytes(bytes)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
leftJustify :: proc(
	text: string,
	length: int,
	pad: string,
	allocator: BasePack.Allocator,
) -> (
	result: string,
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	err: BasePack.AllocatorError
	result, err = strings.left_justify(text, length, pad, allocator)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
destroy :: proc(text: string, allocator: BasePack.Allocator) -> (error: BasePack.Error) {
	defer BasePack.handleError(error)
	err := delete(text, allocator)
	BasePack.parseAllocatorError(err) or_return
	return
}
