package BasePackEventLoop2

import BasePack "../"
import "../Memory/Heap"
import "../Memory/IdPicker"
import "../Memory/List"
import "../Memory/PriorityQueue"
import "../Memory/Queue"
import "../Memory/SPSCQueue"
import "../Memory/Timer"

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
	interval:    bool,
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

Snapshot :: struct($TTask: typeid, $TMicroTask: typeid, $TResult: typeid) {
	scheduled:  PriorityQueue.PriorityQueueSnapshot(ScheduledTask(TTask)),
	taskResult: TaskResult(TTask, TMicroTask, TResult),
}

EventLoop :: struct(
	$TaskQueueCapacity: u64,
	$TaskQueueType: QueueType,
	$TTask: typeid,
	$TMicroTask: typeid,
	$ResultQueueCapacity: u64,
	$ResultQueueType: QueueType,
	$TResult: typeid,
) {
	currentTime:           Timer.Time,
	taskQueueLockFree:     ^SPSCQueue.Queue(TaskQueueCapacity, TTask),
	taskQueue:             ^Queue.Queue(TTask, true),
	microTaskQueue:        ^Queue.Queue(TMicroTask, false),
	resultQueue:           ^Queue.Queue(TResult, true),
	resultQueueLockFree:   ^SPSCQueue.Queue(ResultQueueCapacity, TResult),
	scheduledTaskIdPicker: ^IdPicker.IdPicker(ReferenceId),
	scheduledTaskQueue:    ^PriorityQueue.Queue(ScheduledTask(TTask)),
	data:                  rawptr,
	taskProcessing:        bool,
	taskContext:           TaskContext,
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
		),
		task: TTask,
	) -> (
		error: BasePack.Error,
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
		),
		task: TTask,
	) -> (
		error: BasePack.Error,
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
		),
		microTask: ..TMicroTask,
	) -> (
		error: BasePack.Error,
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
		),
		resultList: ..TResult,
	) -> (
		error: BasePack.Error,
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
		),
		scheduledTaskId: ReferenceId,
		required: bool,
	) -> (
		found: bool,
		error: BasePack.Error,
	),
	ctx:                   proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
		),
	) -> (
		taskContext: TaskContext,
		error: BasePack.Error,
	),
	getSnapshot:           proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
		),
		allocator: BasePack.Allocator,
	) -> (
		snapshot: Snapshot(TTask, TMicroTask, TResult),
		error: BasePack.Error,
	),
}

TaskType :: enum {
	REGULAR,
	TIMEOUT,
	INTERVAL,
}

TaskContext :: struct {
	taskType:    TaskType,
	startedAt:   Timer.Time,
	referenceId: Maybe(ReferenceId),
}

@(private = "file")
createTaskResult :: proc(
	$TTask: typeid,
	$TMicroTask: typeid,
	$TResult: typeid,
	allocator: BasePack.Allocator,
) -> (
	taskResult: TaskResult(TTask, TMicroTask, TResult),
	error: BasePack.Error,
) {
	taskResult.microTaskList = List.create(TMicroTask, allocator) or_return
	taskResult.resultList = List.create(TResult, allocator) or_return
	taskResult.scheduledTaskList = List.create(ScheduledTask(TTask), allocator) or_return
	taskResult.unScheduleTaskList = List.create(ReferenceId, allocator) or_return
	return
}

@(require_results)
create :: proc(
	data: rawptr,
	eventLoop: ^EventLoop(
		$TaskQueueCapacity,
		$TaskQueueType,
		$TTask,
		$TMicroTask,
		$ResultQueueCapacity,
		$ResultQueueType,
		$TResult,
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
		),
		task: TTask,
	) -> (
		error: BasePack.Error,
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
		),
		task: TTask,
	) -> (
		error: BasePack.Error,
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
	eventLoop.scheduledTaskIdPicker = IdPicker.create(ReferenceId, allocator) or_return
	eventLoop.taskResult = createTaskResult(TTask, TMicroTask, TResult, allocator) or_return
	//  {
	// 	List.create(TMicroTask, allocator) or_return,
	// 	List.create(TResult, allocator) or_return,
	// 	List.create(ScheduledTask(TTask), allocator) or_return,
	// 	List.create(ReferenceId, allocator) or_return,
	// }
	eventLoop.microTask = proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
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
		),
		type: ScheduledTaskType,
		duration: Timer.Time,
		task: TTask,
	) -> (
		scheduledTaskId: ReferenceId,
		error: BasePack.Error,
	) {
		// if !eventLoop.taskProcessing {
		// 	error = .EVENT_LOOP_CANNOT_BE_USED_OUTSIDE_OF_TASK_CONTEXT
		// }
		scheduledTaskId = IdPicker.get(eventLoop.scheduledTaskIdPicker) or_return
		PriorityQueue.push(
			eventLoop.scheduledTaskQueue,
			scheduledTaskId,
			PriorityQueue.Priority(eventLoop.currentTime + duration),
			ScheduledTask(TTask) {
				scheduledTaskId,
				PriorityQueue.Priority(eventLoop.currentTime + duration),
				duration,
				task,
				type == .INTERVAL,
			},
		) or_return
		// List.push(
		// 	&eventLoop.taskResult.scheduledTaskList,
		// 	ScheduledTask(TTask) {
		// 		scheduledTaskId,
		// 		PriorityQueue.Priority(eventLoop.currentTime + duration),
		// 		duration,
		// 		task,
		// 		type,
		// 	},
		// ) or_return
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
		),
		resultList: ..TResult,
	) -> (
		error: BasePack.Error,
	) {
		// if !eventLoop.taskProcessing {
		// 	error = .EVENT_LOOP_CANNOT_BE_USED_OUTSIDE_OF_TASK_CONTEXT
		// }
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
		),
		scheduledTaskId: ReferenceId,
		required: bool,
	) -> (
		found: bool,
		error: BasePack.Error,
	) {
		found = PriorityQueue.remove(eventLoop.scheduledTaskQueue, scheduledTaskId) or_return
		if found {
			IdPicker.freeId(eventLoop.scheduledTaskIdPicker, scheduledTaskId) or_return
			return
		}
		for event, index in eventLoop.taskResult.scheduledTaskList {
			if event.id != scheduledTaskId {
				continue
			}
			IdPicker.freeId(eventLoop.scheduledTaskIdPicker, event.id) or_return
			unordered_remove(&eventLoop.taskResult.scheduledTaskList, index)
			found = true
			return
		}
		if required && !found {
			error = .EVENT_LOOP_UNRECOGNIZED_SCHEDULED_TASK_ID
			return
		}
		return
	}
	eventLoop.ctx = proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
		),
	) -> (
		taskContext: TaskContext,
		error: BasePack.Error,
	) {
		err: BasePack.Error
		defer BasePack.handleError(err)
		taskContext = eventLoop.taskContext
		return
	}
	eventLoop.getSnapshot = proc(
		eventLoop: ^EventLoop(
			TaskQueueCapacity,
			TaskQueueType,
			TTask,
			TMicroTask,
			ResultQueueCapacity,
			ResultQueueType,
			TResult,
		),
		allocator: BasePack.Allocator,
	) -> (
		snapshot: Snapshot(TTask, TMicroTask, TResult),
		error: BasePack.Error,
	) {
		err: BasePack.Error
		defer BasePack.handleError(err)
		snapshot.scheduled = PriorityQueue.getSnapshot(
			eventLoop.scheduledTaskQueue,
			allocator,
		) or_return
		snapshot.taskResult = eventLoop.taskResult
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
	List.destroy(eventLoop.taskResult.microTaskList, allocator) or_return
	List.destroy(eventLoop.taskResult.resultList, allocator) or_return
	List.destroy(eventLoop.taskResult.scheduledTaskList, allocator) or_return
	IdPicker.destroy(eventLoop.scheduledTaskIdPicker, allocator) or_return
	Heap.deAllocate(eventLoop, allocator) or_return
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
	),
	event: TTask,
) -> (
	error: BasePack.Error,
) {
	eventLoop->microTaskExecutor(event) or_return
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
	),
	event: TTask,
	taskContext: TaskContext,
) -> (
	error: BasePack.Error,
) {
	err: BasePack.Error
	defer BasePack.handleError(err)
	eventLoop.taskProcessing = true
	defer eventLoop.taskProcessing = false
	eventLoop.taskContext = taskContext
	eventLoop->taskExecutor(event) or_return
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
	),
	currentTime: Timer.Time,
) -> (
	error: BasePack.Error,
) {
	err: BasePack.Error
	defer BasePack.handleError(err)
	//todo currentTime should be set each task execution, and be present in taskContext
	eventLoop.currentTime = currentTime

	found: bool
	when TaskQueueType == .SPSC_LOCK_FREE {
		for event in SPSCQueue.pop(
			eventLoop.taskQueueLockFree,
			0,
			context.temp_allocator,
		) or_return {
			processTask(eventLoop, event, {.REGULAR, currentTime, nil}) or_return
		}
	} else when TaskQueueType == .SPSC_MUTEX {
		event: TTask
		for {
			event, found = Queue.pop(eventLoop.taskQueue) or_return
			if !found {
				break
			}
			processTask(eventLoop, event, {.REGULAR, currentTime, nil}) or_return
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
		if priorityEvent.data.interval {
			priorityEvent.data.scheduledAt += PriorityQueue.Priority(priorityEvent.data.duration)
			PriorityQueue.push(
				eventLoop.scheduledTaskQueue,
				priorityEvent.data.id,
				priorityEvent.data.scheduledAt,
				priorityEvent.data,
			) or_return
			processTask(
				eventLoop,
				priorityEvent.data.data,
				{.INTERVAL, currentTime, priorityEvent.data.id},
			) or_return
		} else {
			processTask(
				eventLoop,
				priorityEvent.data.data,
				{.TIMEOUT, currentTime, priorityEvent.data.id},
			) or_return
		}
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
	),
	events: ..TTask,
) -> (
	error: BasePack.Error,
) {
	err: BasePack.Error
	defer BasePack.handleError(err)
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
	),
	limit: int,
	allocator: BasePack.Allocator,
) -> (
	resultSlice: []TResult,
	error: BasePack.Error,
) {
	when ResultQueueType == .SPSC_LOCK_FREE {
		resultSlice = SPSCQueue.pop(eventLoop.resultQueueLockFree, 0, allocator) or_return
	} else when ResultQueueType == .SPSC_MUTEX {
		resultList: [dynamic]TResult
		resultList = List.create(TResult, allocator) or_return
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
