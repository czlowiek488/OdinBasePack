package BasePack

import "base:runtime"
import "core:fmt"
import "core:log"

Allocator :: runtime.Allocator

AllocatorError :: runtime.Allocator_Error

handleError :: proc(
	error: Error,
	templateMessage := "",
	toEnter: ..any,
	location := #caller_location,
) {
	if error == .NONE {
		return
	}
	if templateMessage == "" {
		log.warnf("#{}", error, location = location)
		return
	}
	log.warnf(
		"#{} >> {}",
		error,
		fmt.aprintf(templateMessage, args = toEnter, allocator = context.temp_allocator),
		location = location,
	)
	return
}


Error :: enum {
	NONE,
	ALLOCATOR_INVALID_ARGUMENT,
	ALLOCATOR_INVALID_POINTER,
	ALLOCATOR_MODE_NOT_IMPLEMENTED,
	ALLOCATOR_OUT_OF_MEMORY,
	INVALID_ENUM_VALUE,
	// timer
	TIMER_MUST_BE_CREATED,
	TIMER_CURRENT_DURATION_CANNOT_BE_LESS_THAN_0,
	TIMER_DURATION_CANNOT_BE_LESS_THAN_0,
	TIMER_DURATION_CANNOT_BE_EQUAL_0,
	// event loop
	EVENT_LOOP_UNRECOGNIZED_SCHEDULED_TASK_ID,
	EVENT_LOOP_INTERVAL_TASK_MUST_HAVE_MINIMAL_DURATION_EQUAL_TO_1,
	EVENT_LOOP_TASK_ERROR,
	EVENT_LOOP_CANNOT_BE_USED_OUTSIDE_OF_TASK_CONTEXT,
	// sparse set
	SPARSE_SET_NOT_CREATED,
	SPARSE_SET_ID_MUST_BE_GREATER_THAN_0,
	SPARSE_SET_DATA_NOT_PRESENT,
	SPARSE_SET_INVALID_ID,
	SPARSE_SET_ALREADY_REMOVED,
	SPARSE_SET_DENSE_LIST_EMPTY,
	// auto set
	AUTO_SET_IS_NOT_CREATED,
	// id picker
	HIT_BOX_FREE_ID_LIST_ALREADY_INITIALIZED,
	STRUCTURE_ID_PICKER_IS_NOT_STARTED,
	// priority queue
	PRIORITY_QUEUE_UNEXPECTED_MISS,
	PRIORITY_QUEUE_CANNOT_NOT_EXISTING_INDEX,
	// queue
	QUEUE_PUSH_ERROR,
	// spsc queue
	SPCS_QUEUE_OVERFLOW,
	//
	DICTIONARY_KEY_MISSING_WHEN_REQUIRED,
	// spatial grid
	SPATIAL_GRID_CANNOT_BE_DESTROYED_WITH_ENTRIES_PRESENT,
	SPATIAL_GRID_CELLS_ARE_EXPECTED_TO_BE_EMPTY,
}

parseAllocatorError :: proc(err: runtime.Allocator_Error) -> (error: Error) {
	defer handleError(error)
	switch err {
	case .None:
		return .NONE
	case .Invalid_Argument:
		return .ALLOCATOR_INVALID_ARGUMENT
	case .Invalid_Pointer:
		return .ALLOCATOR_INVALID_POINTER
	case .Mode_Not_Implemented:
		return .ALLOCATOR_MODE_NOT_IMPLEMENTED
	case .Out_Of_Memory:
		return .ALLOCATOR_OUT_OF_MEMORY
	}
	return .INVALID_ENUM_VALUE
}
