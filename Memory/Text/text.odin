package Text

import "../../../OdinBasePack"
import "core:strings"

@(require_results)
fromBytes :: proc(
	bytes: []byte,
	allocator: OdinBasePack.Allocator,
) -> (
	result: string,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	err: OdinBasePack.AllocatorError
	result, err = strings.clone_from_bytes(bytes)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
leftJustify :: proc(
	text: string,
	length: int,
	pad: string,
	allocator: OdinBasePack.Allocator,
) -> (
	result: string,
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	err: OdinBasePack.AllocatorError
	result, err = strings.left_justify(text, length, pad, allocator)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
destroy :: proc(
	text: string,
	allocator: OdinBasePack.Allocator,
	location := #caller_location,
) -> (
	error: OdinBasePack.Error,
) {
	defer OdinBasePack.handleError(error)
	err := delete(text, allocator, location)
	OdinBasePack.parseAllocatorError(err) or_return
	return
}
