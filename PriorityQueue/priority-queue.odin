package PriorityQueue

import BasePack "../"
import "../Dictionary"
import "../Heap"
import "../List"
import "core:container/priority_queue"

Priority :: distinct int

ReferenceId :: distinct int

PriorityEvent :: struct($TData: typeid) {
	id:         ReferenceId,
	priority:   Priority,
	data:       TData,
	references: ^map[ReferenceId]int,
}

Queue :: struct($TData: typeid) {
	queue:      ^priority_queue.Priority_Queue(PriorityEvent(TData)),
	references: map[ReferenceId]int,
}

@(require_results)
create :: proc(
	$TData: typeid,
	allocator: BasePack.Allocator,
) -> (
	queue: ^Queue(TData),
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	queue = Heap.allocate(Queue(TData), allocator) or_return
	queue.queue = Heap.allocate(
		priority_queue.Priority_Queue(PriorityEvent(TData)),
		allocator,
	) or_return
	err: BasePack.AllocatorError
	queue.queue.queue = List.create(PriorityEvent(TData), allocator) or_return
	err = priority_queue.init(queue.queue, proc(a, b: PriorityEvent(TData)) -> bool {
			return a.priority < b.priority
		}, proc(q: []PriorityEvent(TData), i, j: int) {
			q[i], q[j] = q[j], q[i]
			references := q[i].references
			references[q[i].id] = i
			references[q[j].id] = j
		}, 16, allocator)
	BasePack.parseAllocatorError(err) or_return
	queue.references = Dictionary.create(ReferenceId, int, allocator) or_return
	return
}

@(require_results)
destroy :: proc(queue: ^Queue($TData), allocator: BasePack.Allocator) -> (error: BasePack.Error) {
	defer BasePack.handleError(error)
	priority_queue.destroy(queue.queue)
	Heap.deAllocate(queue.queue, allocator) or_return
	Dictionary.destroy(queue.references, allocator) or_return
	Heap.deAllocate(queue, allocator) or_return
	return
}

@(require_results)
push :: proc(
	queue: ^Queue($TData),
	id: ReferenceId,
	priority: Priority,
	event: TData,
) -> (
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	queue.references[id] = priority_queue.len(queue.queue^)
	err := priority_queue.push(
		queue.queue,
		PriorityEvent(TData){id, priority, event, &queue.references},
	)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
length :: proc(queue: ^Queue($TData)) -> (length: int, error: BasePack.Error) {
	defer BasePack.handleError(error)
	length = priority_queue.len(queue.queue^)
	return
}

@(require_results)
pop :: proc(
	queue: ^Queue($TData),
	priority: Priority,
) -> (
	event: PriorityEvent(TData),
	found: bool,
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	event, found = priority_queue.peek_safe(queue.queue^)
	if !found {
		return
	}
	if priority >= 0 {
		found = event.priority <= priority
		if !found {
			return
		}
	}
	event, found = priority_queue.pop_safe(queue.queue)
	if !found {
		error = .PRIORITY_QUEUE_UNEXPECTED_MISS
		return
	}
	Dictionary.unset(&queue.references, event.id) or_return
	return
}

@(require_results)
remove :: proc(queue: ^Queue($TData), id: ReferenceId) -> (found: bool, error: BasePack.Error) {
	defer BasePack.handleError(error)
	index: int
	index, found = queue.references[id]
	if !found {
		return
	}
	_, found = priority_queue.remove(queue.queue, index)
	if !found {
		error = .PRIORITY_QUEUE_CANNOT_NOT_EXISTING_INDEX
		return
	}
	Dictionary.unset(&queue.references, id) or_return
	return
}
