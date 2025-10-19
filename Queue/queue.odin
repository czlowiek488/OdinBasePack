package QueueV2

import BasePack "../"
import "../Heap"
import "core:container/queue"
import "core:sync"


Queue :: struct($TEvent: typeid, $TThreadSafe: bool) {
	queue: queue.Queue(TEvent),
	lock:  ^sync.Mutex,
}

@(require_results)
create :: proc(
	$TEvent: typeid,
	$TThreadSafe: bool,
	startingCapacity: int,
	allocator: BasePack.Allocator,
) -> (
	q: ^Queue(TEvent, TThreadSafe),
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	q = Heap.allocate(Queue(TEvent, TThreadSafe), allocator) or_return
	when TThreadSafe == true {
		q.lock = Heap.allocate(sync.Mutex, allocator) or_return
	}
	err := queue.init(&q.queue, startingCapacity, allocator)
	BasePack.parseAllocatorError(err) or_return
	return
}

@(require_results)
destroy :: proc(
	q: ^Queue($TEvent, $TThreadSafe),
	allocator: BasePack.Allocator,
) -> (
	error: BasePack.Error,
) {
	queue.destroy(&q.queue)
	when TThreadSafe == true {
		Heap.deAllocate(q.lock, allocator) or_return
	}
	Heap.deAllocate(q, allocator) or_return
	return
}

@(require_results)
push :: proc(q: ^Queue($TEvent, $TThreadSafe), event: TEvent) -> (error: BasePack.Error) {
	defer BasePack.handleError(error)
	when TThreadSafe == true {
		sync.mutex_lock(q.lock)
	}
	defer when TThreadSafe == true {
		sync.mutex_unlock(q.lock)
	}
	succeed, err := queue.push_back(&q.queue, element)
	BasePack.parseAllocatorError(err) or_return
	if !succeed {
		error = .QUEUE_PUSH_ERROR
	}
	return
}

@(require_results)
pushMany :: proc(q: ^Queue($TEvent, $TThreadSafe), events: ..TEvent) -> (error: BasePack.Error) {
	defer BasePack.handleError(error)
	when TThreadSafe == true {
		sync.mutex_lock(q.lock)
	}
	defer when TThreadSafe == true {
		sync.mutex_unlock(q.lock)
	}
	succeed, err := queue.push_back_elems(&q.queue, elems = events)
	BasePack.parseAllocatorError(err) or_return
	if !succeed {
		error = .QUEUE_PUSH_ERROR
	}
	return
}


@(require_results)
pop :: proc(
	q: ^Queue($TEvent, $TThreadSafe),
) -> (
	event: TEvent,
	found: bool,
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	when TThreadSafe == true {
		sync.mutex_lock(q.lock)
	}
	defer when TThreadSafe == true {
		sync.mutex_unlock(q.lock)
	}
	event, found = queue.pop_front_safe(&q.queue)
	return
}
