package BasePackEventLoop

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
	$TError: typeid,
)
{
	currentTime:           Timer.Time,
	mapper:                proc(e: BasePack.Error) -> TError,
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
			TError,
		),
		task: TTask,
	) -> (
		error: TError
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
			TError,
		),
		task: TTask,
	) -> (
		error: TError
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
			TError,
		),
		microTask: ..TMicroTask,
	) -> (
		error: TError
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
			TError,
		),
		resultList: ..TResult,
	) -> (
		error: TError
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
			TError,
		),
		type: ScheduledTaskType,
		scheduledAt: Timer.Time,
		task: TTask,
	) -> (
		scheduledTaskId: ReferenceId,
		error: TError,
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
			TError,
		),
		scheduledTaskId: ReferenceId,
		required: bool,
	) -> (
		found: bool,
		error: TError,
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
			TError,
		),
	) -> (
		taskContext: TaskContext,
		error: TError,
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
			TError,
		),
		allocator: BasePack.Allocator,
	) -> (
		snapshot: Snapshot(TTask, TMicroTask, TResult),
		error: TError,
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
		$TError,
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
			TError,
		),
		task: TTask,
	) -> (
		error: TError
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
			TError,
		),
		task: TTask,
	) -> (
		error: TError
	),
	mapper: proc(e: BasePack.Error) -> TError,
	allocator: BasePack.Allocator,
) -> (
	error: TError,
) {
	err: BasePack.Error
	defer BasePack.handleError(err)
	eventLoop.mapper = mapper
	eventLoop.data = data
	eventLoop.microTaskExecutor = microTaskExecutor
	eventLoop.taskExecutor = taskExecutor

	when TaskQueueType == .SPSC_LOCK_FREE {
		eventLoop.taskQueueLockFree, err = SPSCQueue.create(TaskQueueCapacity, TTask, allocator)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	} else when TaskQueueType == .SPSC_MUTEX {
		eventLoop.taskQueue, err = Queue.create(TTask, true, int(TaskQueueCapacity), allocator)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	}
	when ResultQueueType == .SPSC_LOCK_FREE {
		eventLoop.resultQueueLockFree, err = SPSCQueue.create(
			ResultQueueCapacity,
			TResult,
			allocator,
		)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	} else when ResultQueueType == .SPSC_MUTEX {
		eventLoop.resultQueue, err = Queue.create(
			TResult,
			true,
			int(ResultQueueCapacity),
			allocator,
		)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	}
	eventLoop.microTaskQueue, err = Queue.create(TTask, false, 16, allocator)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	eventLoop.scheduledTaskQueue, err = PriorityQueue.create(ScheduledTask(TTask), allocator)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	eventLoop.scheduledTaskIdPicker, err = IdPicker.create(ReferenceId, allocator)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	eventLoop.taskResult, err = createTaskResult(TTask, TMicroTask, TResult, allocator)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
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
			TError,
		),
		microTaskList: ..TMicroTask,
	) -> (
		error: TError,
	) {
		err: BasePack.Error
		defer BasePack.handleError(err)
		err = List.push(&eventLoop.taskResult.microTaskList, element = microTaskList)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
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
			TError,
		),
		type: ScheduledTaskType,
		duration: Timer.Time,
		task: TTask,
	) -> (
		scheduledTaskId: ReferenceId,
		error: TError,
	) {
		err: BasePack.Error
		defer BasePack.handleError(err)
		// if !eventLoop.taskProcessing {
		// 	error = .EVENT_LOOP_CANNOT_BE_USED_OUTSIDE_OF_TASK_CONTEXT
		// }
		scheduledTaskId, err = IdPicker.get(eventLoop.scheduledTaskIdPicker)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
		err = PriorityQueue.push(
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
		)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
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
			TError,
		),
		resultList: ..TResult,
	) -> (
		error: TError,
	) {
		err: BasePack.Error
		defer BasePack.handleError(err)
		// if !eventLoop.taskProcessing {
		// 	error = .EVENT_LOOP_CANNOT_BE_USED_OUTSIDE_OF_TASK_CONTEXT
		// }
		err = List.push(&eventLoop.taskResult.resultList, element = resultList)
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
			TError,
		),
		scheduledTaskId: ReferenceId,
		required: bool,
	) -> (
		found: bool,
		error: TError,
	) {
		err: BasePack.Error
		defer BasePack.handleError(err)
		found, err = PriorityQueue.remove(eventLoop.scheduledTaskQueue, scheduledTaskId)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
		if found {
			err = IdPicker.freeId(eventLoop.scheduledTaskIdPicker, scheduledTaskId)
			if err != .NONE {
				error = eventLoop.mapper(err)
				return
			}
			return
		}
		for event, index in eventLoop.taskResult.scheduledTaskList {
			if event.id != scheduledTaskId {
				continue
			}
			err = IdPicker.freeId(eventLoop.scheduledTaskIdPicker, event.id)
			if err != .NONE {
				error = eventLoop.mapper(err)
				return
			}
			unordered_remove(&eventLoop.taskResult.scheduledTaskList, index)
			found = true
			return
		}
		if required && !found {
			err = .EVENT_LOOP_UNRECOGNIZED_SCHEDULED_TASK_ID
			error = eventLoop.mapper(err)
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
			TError,
		),
	) -> (
		taskContext: TaskContext,
		error: TError,
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
			TError,
		),
		allocator: BasePack.Allocator,
	) -> (
		snapshot: Snapshot(TTask, TMicroTask, TResult),
		error: TError,
	) {
		err: BasePack.Error
		defer BasePack.handleError(err)
		snapshot.scheduled, err = PriorityQueue.getSnapshot(
			eventLoop.scheduledTaskQueue,
			allocator,
		)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
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
		$TError,
	),
	allocator: BasePack.Allocator,
) -> (
	error: TError,
) {
	err: BasePack.Error
	defer BasePack.handleError(err)
	err = Queue.destroy(eventLoop.microTaskQueue, allocator)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	when TaskQueueType == .SPSC_LOCK_FREE {
		err = SPSCQueue.destroy(eventLoop.taskQueueLockFree, allocator)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	} else when TaskQueueType == .SPSC_MUTEX {
		err = Queue.destroy(eventLoop.taskQueue, allocator)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	}
	when ResultQueueType == .SPSC_LOCK_FREE {
		err = SPSCQueue.destroy(eventLoop.resultQueueLockFree, allocator)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	} else when ResultQueueType == .SPSC_MUTEX {
		err = Queue.destroy(eventLoop.resultQueue, allocator)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	}
	err = PriorityQueue.destroy(eventLoop.scheduledTaskQueue, allocator)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	err = List.destroy(eventLoop.taskResult.microTaskList, allocator)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	err = List.destroy(eventLoop.taskResult.resultList, allocator)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	err = List.destroy(eventLoop.taskResult.scheduledTaskList, allocator)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	err = IdPicker.destroy(eventLoop.scheduledTaskIdPicker, allocator)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	err = Heap.deAllocate(eventLoop, allocator)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
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
		$TError,
	),
	event: TTask,
) -> (
	error: TError,
) {
	err: BasePack.Error
	defer BasePack.handleError(err)
	customError := eventLoop->microTaskExecutor(event)
	if int(customError) != 0 {
		err = .EVENT_LOOP_TASK_ERROR
		error = eventLoop.mapper(err)
		return
	}
	if eventLoop.taskResult.microTaskList != nil {
		err = Queue.pushMany(eventLoop.microTaskQueue, ..eventLoop.taskResult.microTaskList[:])
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
		err = List.purge(&eventLoop.taskResult.microTaskList)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
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
		$TError,
	),
	event: TTask,
	taskContext: TaskContext,
) -> (
	error: TError,
) {
	err: BasePack.Error
	defer BasePack.handleError(err)
	eventLoop.taskProcessing = true
	defer eventLoop.taskProcessing = false
	eventLoop.taskContext = taskContext
	customError := eventLoop->taskExecutor(event)
	if int(customError) != 0 {
		err = .EVENT_LOOP_TASK_ERROR
		error = eventLoop.mapper(err)
		return
	}
	err = Queue.pushMany(eventLoop.microTaskQueue, ..eventLoop.taskResult.microTaskList[:])
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	err = List.purge(&eventLoop.taskResult.microTaskList)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	task: TTask
	found: bool
	for {
		task, found, err = Queue.pop(eventLoop.microTaskQueue)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
		if !found {
			break
		}
		processMicroTask(eventLoop, task) or_return
	}
	when ResultQueueType == .SPSC_LOCK_FREE {
		err = SPSCQueue.push(
			eventLoop.resultQueueLockFree,
			items = eventLoop.taskResult.resultList[:],
		)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	} else when ResultQueueType == .SPSC_MUTEX {
		err = Queue.pushMany(eventLoop.resultQueue, events = eventLoop.taskResult.resultList[:])
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	}
	err = List.purge(&eventLoop.taskResult.resultList)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
	for scheduledTask in eventLoop.taskResult.scheduledTaskList {
		err = PriorityQueue.push(
			eventLoop.scheduledTaskQueue,
			scheduledTask.id,
			scheduledTask.scheduledAt,
			scheduledTask,
		)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	}
	err = List.purge(&eventLoop.taskResult.scheduledTaskList)
	if err != .NONE {
		error = eventLoop.mapper(err)
		return
	}
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
		$TError,
	),
	currentTime: Timer.Time,
) -> (
	error: TError,
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
			event, found, err = Queue.pop(eventLoop.taskQueue)
			if err != .NONE {
				error = eventLoop.mapper(err)
				return
			}
			if !found {
				break
			}
			processTask(eventLoop, event, {.REGULAR, currentTime, nil}) or_return
		}
	}
	priorityEvent: PriorityQueue.PriorityEvent(ScheduledTask(TTask))
	for {
		priorityEvent, found, err = PriorityQueue.pop(
			eventLoop.scheduledTaskQueue,
			PriorityQueue.Priority(eventLoop.currentTime),
		)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
		if !found {
			break
		}
		if priorityEvent.data.interval {
			priorityEvent.data.scheduledAt += PriorityQueue.Priority(priorityEvent.data.duration)
			err = PriorityQueue.push(
				eventLoop.scheduledTaskQueue,
				priorityEvent.data.id,
				priorityEvent.data.scheduledAt,
				priorityEvent.data,
			)
			if err != .NONE {
				error = eventLoop.mapper(err)
				return
			}
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
		$TError,
	),
	events: ..TTask,
) -> (
	error: TError,
) {
	err: BasePack.Error
	defer BasePack.handleError(err)
	when TaskQueueType == .SPSC_LOCK_FREE {
		err = SPSCQueue.push(eventLoop.taskQueueLockFree, items = events)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	} else when TaskQueueType == .SPSC_MUTEX {
		err = Queue.pushMany(eventLoop.taskQueue, events = events)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
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
		$TError,
	),
	limit: int,
	allocator: BasePack.Allocator,
) -> (
	resultSlice: []TResult,
	error: TError,
) {
	err: BasePack.Error
	defer BasePack.handleError(err)
	when ResultQueueType == .SPSC_LOCK_FREE {
		resultSlice, err = SPSCQueue.pop(eventLoop.resultQueueLockFree, 0, allocator)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
	} else when ResultQueueType == .SPSC_MUTEX {
		resultList: [dynamic]TResult
		resultList, err = List.create(TResult, allocator)
		if err != .NONE {
			error = eventLoop.mapper(err)
			return
		}
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
			result, found, err = Queue.pop(eventLoop.resultQueue)
			if err != .NONE {
				error = eventLoop.mapper(err)
				return
			}
			if !found {
				break
			}
			err = List.push(&resultList, result)
			if err != .NONE {
				error = eventLoop.mapper(err)
				return
			}
		}
		resultSlice = resultList[:]
	}
	return
}
