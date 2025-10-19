package EventLoop

import BasePack "../"
import "../Heap"
import "../IdPicker"
import "../List"
import "../PriorityQueue"
import "../Queue"
import "../SPSCQueue"
import "../Timer"

ScheduledTaskType :: enum {
	TIMEOUT,
	INTERVAL,
}

ReferenceId :: PriorityQueue.ReferenceId

ScheduledTask :: struct($TData: typeid) {
	id:          ReferenceId,
	scheduledAt: PriorityQueue.Priority,
	duration:    Timer.Time,
	data:        TData,
	type:        ScheduledTaskType,
}

TaskResult :: struct($TTask: typeid, $TMicroTask: typeid, $TResult: typeid) {
	microTaskList:      [dynamic]TMicroTask,
	resultList:         [dynamic]TResult,
	scheduledTaskList:  [dynamic]ScheduledTask(TTask),
	unScheduleTaskList: [dynamic]ReferenceId,
}

QueueType :: enum {
	SPSC_LOCK_FREE,
	SPSC_MUTEX,
}

EventLoop :: struct(
	$TaskQueueCapacity: u64,
	$TaskQueueType: QueueType,
	$TTask: typeid,
	$TMicroTask: typeid,
	$ResultQueueCapacity: u64,
	$ResultQueueType: QueueType,
	$TResult: typeid,
	$TData: typeid,
)
{
	currentTime:           Timer.Time,
	taskQueueLockFree:     ^SPSCQueue.Queue(TaskQueueCapacity, TTask),
	taskQueue:             ^Queue.Queue(TTask, true),
	microTaskQueue:        ^Queue.Queue(TMicroTask, false),
	resultQueue:           ^Queue.Queue(TResult, true),
	resultQueueLockFree:   ^SPSCQueue.Queue(ResultQueueCapacity, TResult),
	scheduledTaskIdPicker: IdPicker.IdPicker(ReferenceId),
	scheduledTaskQueue:    ^PriorityQueue.Queue(ScheduledTask(TTask)),
	data:                  ^TData,
	taskResult:            TaskResult(TTask, TMicroTask, TResult),
	taskExecutor:          proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		task: TTask,
	) -> (
		error: BasePack.Error
	),
	microTaskExecutor:     proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		task: TTask,
	) -> (
		error: BasePack.Error
	),
	microTask:             proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		microTask: ..TMicroTask,
	) -> (
		error: BasePack.Error
	),
	result:                proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		resultList: ..TResult,
	) -> (
		error: BasePack.Error
	),
	task:                  proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		type: ScheduledTaskType,
		scheduledAt: Timer.Time,
		task: TTask,
	) -> (
		scheduledTaskId: ReferenceId,
		error: BasePack.Error,
	),
	unSchedule:            proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		scheduledTaskId: ReferenceId,
	) -> (
		error: BasePack.Error
	),
}

@(require_results)
create :: proc(
	data: ^$TData,
	eventLoop: ^EventLoop(
		$TaskQueueCapacity,
		$TaskQueueType,
		$TTask,
		$TMicroTask,
		$ResultQueueCapacity,
		$ResultQueueType,
		$TResult,
		TData,
	),
	taskExecutor: proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		task: TTask,
	) -> (
		error: BasePack.Error
	),
	microTaskExecutor: proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		task: TTask,
	) -> (
		error: BasePack.Error
	),
	allocator: BasePack.Allocator,
) -> (
	error: BasePack.Error,
) {

	defer BasePack.handleError(error)
	eventLoop.data = data
	eventLoop.microTaskExecutor = microTaskExecutor
	eventLoop.taskExecutor = taskExecutor

	when TaskQueueType == .SPSC_LOCK_FREE {
		eventLoop.taskQueueLockFree = SPSCQueue.create(
			TaskQueueCapacity,
			TTask,
			allocator,
		) or_return
	} else when TaskQueueType == .SPSC_MUTEX {
		eventLoop.taskQueue = Queue.create(
			TTask,
			true,
			int(TaskQueueCapacity),
			allocator,
		) or_return
	}
	when ResultQueueType == .SPSC_LOCK_FREE {
		eventLoop.resultQueueLockFree = SPSCQueue.create(
			ResultQueueCapacity,
			TResult,
			allocator,
		) or_return
	} else when ResultQueueType == .SPSC_MUTEX {
		eventLoop.resultQueue = Queue.create(
			TResult,
			true,
			int(ResultQueueCapacity),
			allocator,
		) or_return
	}
	eventLoop.microTaskQueue = Queue.create(TTask, false, 16, allocator) or_return
	eventLoop.scheduledTaskQueue = PriorityQueue.create(ScheduledTask(TTask), allocator) or_return
	IdPicker.create(&eventLoop.scheduledTaskIdPicker, allocator) or_return
	eventLoop.taskResult = {
		List.create(TMicroTask, allocator) or_return,
		List.create(TResult, allocator) or_return,
		List.create(ScheduledTask(TTask), allocator) or_return,
		List.create(ReferenceId, allocator) or_return,
	}
	eventLoop.microTask = proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		microTaskList: ..TMicroTask,
	) -> (
		error: BasePack.Error,
	) {
		List.push(&eventLoop.taskResult.microTaskList, element = microTaskList) or_return
		return
	}
	eventLoop.task = proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		type: ScheduledTaskType,
		duration: Timer.Time,
		task: TTask,
	) -> (
		scheduledTaskId: ReferenceId,
		error: BasePack.Error,
	) {
		if (type == .INTERVAL && duration <= 0) {
			error = .EVENT_LOOP_INTERVAL_TASK_MUST_HAVE_MINIMAL_DURATION_EQUAL_TO_1
			return
		}
		scheduledTaskId = IdPicker.get(&eventLoop.scheduledTaskIdPicker) or_return
		List.push(
			&eventLoop.taskResult.scheduledTaskList,
			ScheduledTask(TTask) {
				scheduledTaskId,
				PriorityQueue.Priority(eventLoop.currentTime + duration),
				duration,
				task,
				type,
			},
		) or_return
		return
	}
	eventLoop.result = proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		resultList: ..TResult,
	) -> (
		error: BasePack.Error,
	) {
		List.push(&eventLoop.taskResult.resultList, element = resultList) or_return
		return
	}
	eventLoop.unSchedule = proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
			TData,
		),
		scheduledTaskId: ReferenceId,
	) -> (
		error: BasePack.Error,
	) {
		found := PriorityQueue.remove(eventLoop.scheduledTaskQueue, scheduledTaskId) or_return
		if found {
			IdPicker.freeId(&eventLoop.scheduledTaskIdPicker, scheduledTaskId) or_return
			return
		}
		for event, index in eventLoop.taskResult.scheduledTaskList {
			if event.id != scheduledTaskId {
				continue
			}
			IdPicker.freeId(&eventLoop.scheduledTaskIdPicker, event.id) or_return
			unordered_remove(&eventLoop.taskResult.scheduledTaskList, index)
			return
		}
		error = .EVENT_LOOP_UNRECOGNIZED_SCHEDULED_TASK_ID
		return
	}
	return
}

@(require_results)
destroy :: proc(
	eventLoop: ^EventLoop(
		$TaskQueueCapacity,
		$TaskQueueType,
		$TTask,
		$TMicroTask,
		$ResultQueueCapacity,
		$ResultQueueType,
		$TResult,
		$TData,
	),
	allocator: BasePack.Allocator,
) -> (
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	Queue.destroy(eventLoop.microTaskQueue, allocator) or_return
	when TaskQueueType == .SPSC_LOCK_FREE {
		SPSCQueue.destroy(eventLoop.taskQueueLockFree, allocator) or_return
	} else when TaskQueueType == .SPSC_MUTEX {
		Queue.destroy(eventLoop.taskQueue, allocator) or_return
	}
	when ResultQueueType == .SPSC_LOCK_FREE {
		SPSCQueue.destroy(eventLoop.resultQueueLockFree, allocator) or_return
	} else when ResultQueueType == .SPSC_MUTEX {
		Queue.destroy(eventLoop.resultQueue, allocator) or_return
	}
	PriorityQueue.destroy(eventLoop.scheduledTaskQueue, allocator) or_return
	List.destroy(eventLoop.taskResult.microTaskList) or_return
	List.destroy(eventLoop.taskResult.resultList) or_return
	List.destroy(eventLoop.taskResult.scheduledTaskList) or_return
	Heap.deAllocate(eventLoop, allocator) or_return
	IdPicker.destroy(&eventLoop.scheduledTaskIdPicker, allocator) or_return
	return
}

@(private)
@(require_results)
processMicroTask :: proc(
	eventLoop: ^EventLoop(
		$TaskQueueCapacity,
		$TaskQueueType,
		$TTask,
		$TMicroTask,
		$ResultQueueCapacity,
		$ResultQueueType,
		$TResult,
		$TData,
	),
	event: TTask,
) -> (
	error: BasePack.Error,
) {

	defer BasePack.handleError(error)
	customError := eventLoop->microTaskExecutor(event)
	if int(customError) != 0 {
		error = .EVENT_LOOP_TASK_ERROR
		return
	}
	if eventLoop.taskResult.microTaskList != nil {
		Queue.pushMany(eventLoop.microTaskQueue, ..eventLoop.taskResult.microTaskList[:]) or_return
		List.purge(&eventLoop.taskResult.microTaskList) or_return
	}
	return
}

@(private)
@(require_results)
processTask :: proc(
	eventLoop: ^EventLoop(
		$TaskQueueCapacity,
		$TaskQueueType,
		$TTask,
		$TMicroTask,
		$ResultQueueCapacity,
		$ResultQueueType,
		$TResult,
		$TData,
	),
	event: TTask,
) -> (
	error: BasePack.Error,
) {

	defer BasePack.handleError(error)
	customError := eventLoop->taskExecutor(event)
	if int(customError) != 0 {
		error = .EVENT_LOOP_TASK_ERROR
		return
	}
	Queue.pushMany(eventLoop.microTaskQueue, ..eventLoop.taskResult.microTaskList[:]) or_return
	List.purge(&eventLoop.taskResult.microTaskList) or_return
	task: TTask
	found: bool
	for {
		task, found = Queue.pop(eventLoop.microTaskQueue) or_return
		if !found {
			break
		}
		processMicroTask(eventLoop, task) or_return
	}
	when ResultQueueType == .SPSC_LOCK_FREE {
		SPSCQueue.push(
			eventLoop.resultQueueLockFree,
			items = eventLoop.taskResult.resultList[:],
		) or_return
	} else when ResultQueueType == .SPSC_MUTEX {
		Queue.pushMany(
			eventLoop.resultQueue,
			events = eventLoop.taskResult.resultList[:],
		) or_return
	}
	List.purge(&eventLoop.taskResult.resultList) or_return
	for scheduledTask in eventLoop.taskResult.scheduledTaskList {
		PriorityQueue.push(
			eventLoop.scheduledTaskQueue,
			scheduledTask.id,
			scheduledTask.scheduledAt,
			scheduledTask,
		) or_return
	}
	List.purge(&eventLoop.taskResult.scheduledTaskList) or_return
	return
}

@(require_results)
flush :: proc(
	eventLoop: ^EventLoop(
		$TaskQueueCapacity,
		$TaskQueueType,
		$TTask,
		$TMicroTask,
		$ResultQueueCapacity,
		$ResultQueueType,
		$TResult,
		$TData,
	),
	currentTime: Timer.Time,
) -> (
	error: BasePack.Error,
) {

	defer BasePack.handleError(error)
	eventLoop.currentTime = currentTime

	found: bool
	when TaskQueueType == .SPSC_LOCK_FREE {
		for event in SPSCQueue.pop(
			eventLoop.taskQueueLockFree,
			0,
			context.temp_allocator,
		) or_return {
			processTask(eventLoop, event) or_return
		}
	} else when TaskQueueType == .SPSC_MUTEX {
		event: TTask
		for {
			event, found = Queue.pop(eventLoop.taskQueue) or_return
			if !found {
				break
			}
			processTask(eventLoop, event) or_return
		}
	}
	priorityEvent: PriorityQueue.PriorityEvent(ScheduledTask(TTask))
	for {
		priorityEvent, found = PriorityQueue.pop(
			eventLoop.scheduledTaskQueue,
			PriorityQueue.Priority(eventLoop.currentTime),
		) or_return
		if !found {
			break
		}
		if priorityEvent.data.type == .INTERVAL {
			priorityEvent.data.scheduledAt += PriorityQueue.Priority(priorityEvent.data.duration)
			PriorityQueue.push(
				eventLoop.scheduledTaskQueue,
				priorityEvent.data.id,
				priorityEvent.data.scheduledAt,
				priorityEvent.data,
			) or_return
		}
		processTask(eventLoop, priorityEvent.data.data) or_return
	}
	return
}

@(require_results)
pushTasks :: proc(
	eventLoop: ^EventLoop(
		$TaskQueueCapacity,
		$TaskQueueType,
		$TTask,
		$TMicroTask,
		$ResultQueueCapacity,
		$ResultQueueType,
		$TResult,
		$TData,
	),
	events: ..TTask,
) -> (
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	when TaskQueueType == .SPSC_LOCK_FREE {
		SPSCQueue.push(eventLoop.taskQueueLockFree, items = events) or_return
	} else when TaskQueueType == .SPSC_MUTEX {
		Queue.pushMany(eventLoop.taskQueue, events = events) or_return
	}
	return
}

@(require_results)
popResults :: proc(
	eventLoop: ^EventLoop(
		$TaskQueueCapacity,
		$TaskQueueType,
		$TTask,
		$TMicroTask,
		$ResultQueueCapacity,
		$ResultQueueType,
		$TResult,
		$TData,
	),
	limit: int,
	allocator: BasePack.Allocator,
) -> (
	resultSlice: []TResult,
	error: BasePack.Error,
) {
	defer BasePack.handleError(error)
	when ResultQueueType == .SPSC_LOCK_FREE {
		resultSlice = SPSCQueue.pop(eventLoop.resultQueueLockFree, 0, allocator) or_return
	} else when ResultQueueType == .SPSC_MUTEX {
		resultList := List.create(TResult, allocator) or_return
		result: TResult
		found: bool
		localLimit := limit
		for {
			if limit > 0 {
				if localLimit == 0 {
					break
				}
				localLimit -= 1
			}
			result, found = Queue.pop(eventLoop.resultQueue) or_return
			if !found {
				break
			}
			List.push(&resultList, result) or_return
		}
		resultSlice = resultList[:]
	}
	return
}
