package SPSCQueue

import BasePack "../"
import "../Heap"
import "../sds"

Queue :: struct($TCapacity: u64, $TData: typeid) {
	queue: ^sds.SPSC(TCapacity, TData),
}

@(require_results)
create :: proc(
	$TCapacity: u64,
	$TData: typeid,
	allocator: BasePack.Allocator,
) -> (
	queue: Queue(TCapacity, TData),
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	queue.queue = Heap.allocate(sds.SPSC(TCapacity, TData), allocator) or_return
	return
}

@(require_results)
destroy :: proc(
	queue: Queue($TSize, $TData),
	allocator: BasePack.Allocator,
) -> (
	error: BasePack.Error,
) {
	Heap.deAllocate(queue.queue, allocator) or_return
	return
}

@(require_results)
push :: proc(queue: Queue($TSize, $TData), items: ..TData) -> (error: BasePack.Error) {
	defer BasePack.handleError(error)
	count := sds.spsc_push_elems(queue.queue, vals = items)
	if count != len(items) {
		error = .SPCS_QUEUE_OVERFLOW
	}
	return
}

@(require_results)
pop :: proc(
	queue: Queue($TSize, $TData),
	$TLimit: u64,
	allocator: BasePack.Allocator,
) -> (
	items: []TData,
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	when TLimit > TSize {
		#panic("limit exceeds size, use 0 instead")
	}
	localLimit := TLimit
	if TLimit == 0 {
		localLimit = TSize
	}
	err: BasePack.AllocatorError
	items, err = make([]TData, localLimit, allocator)
	BasePack.parseAllocatorError(err) or_return
	sds.spsc_pop_elems(queue.queue, items)
	return
}
