# OdinBasePack

This package contains a group of different data structures I use to develop my odin apps and games.

The most important is event-loop.

This is my custom implementation of event loop lightly inspired by node.js.

This provides a ready to use base for event-driven applications.

Be aware that event-loop implementation is naive and may not meet more sophisticated requirements.

This implementation contains many shortcuts that make implementation simple but as performant as it could be.

## Architecture

```mermaid
---
title: Event-Loop Architecture
---
graph TD;
   classDef Operation fill:blue,color:white
   classDef Queue fill:yellow,color:black
   classDef Process fill:white,color:black
   classDef Finish fill:green,color:black
   classDef Executor fill:orange,color:black

   pushTasks:::Operation
   popResults:::Operation
   flush:::Operation
   task[->task]:::Operation
   microTask[->microTask]:::Operation
   result[->result]:::Operation
   unSchedule[->unSchedule]:::Operation

   taskExecutor:::Executor
   microTaskExecutor:::Executor

   taskQueue:::Queue
   microTaskQueue:::Queue
   scheduledQueue:::Queue
   resultQueue:::Queue
   
   Finish:::Finish
   TaskFinish:::Finish

   processScheduledTask:::Process
   processScheduledTaskInternal:::Process
   processTaskInternal:::Process
   passResultsToQueue:::Process
   passScheduledTasksToQueue:::Process
   scheduleTask:::Process

   processTask:::Process
   pushMicroTasks:::Process

   nextScheduledTaskPresent@{ shape: diamond, label: "Next scheduled present?" }
   isInterval@{ shape: diamond, label: "Is Interval?" }
   nextTaskPresent@{ shape: diamond, label: "Next task present?" }
   nextMicroTaskPresent@{ shape: diamond, label: "Next micro present?" }

   pushTasks --> taskQueue
   resultQueue --> popResults
   flush --> processScheduledTask
   processScheduledTask --> nextScheduledTaskPresent
   nextScheduledTaskPresent -->|yes| isInterval
   isInterval -->|yes| scheduleTask
   scheduleTask --> processScheduledTaskInternal 
   isInterval -->|no| processScheduledTaskInternal
   processScheduledTaskInternal --> nextScheduledTaskPresent
   nextScheduledTaskPresent -->|no| processTask
   processTask --> nextTaskPresent
   nextTaskPresent -->|yes| processTaskInternal
   processTaskInternal --> processTask
   nextTaskPresent -->|no| passResultsToQueue
   passResultsToQueue --> passScheduledTasksToQueue
   passScheduledTasksToQueue --> Finish

   task -.- scheduledQueue
   unSchedule -.- scheduledQueue
   result -.- resultQueue
   microTask -.- microTaskQueue

   processScheduledTaskInternal -.- ProcessTask
   processTaskInternal -.- ProcessTask
   nextTaskPresent -.- taskQueue
   passResultsToQueue -.- resultQueue
   passScheduledTasksToQueue -.- scheduledQueue
   nextScheduledTaskPresent -.- scheduledQueue
   nextMicroTaskPresent -.- microTaskQueue
   pushMicroTasks -.- microTaskQueue

   subgraph ProcessTask
      taskExecutor --> pushMicroTasks
      pushMicroTasks --> nextMicroTaskPresent
      nextMicroTaskPresent -->|yes| microTaskExecutor
      nextMicroTaskPresent -->|no| TaskFinish
      microTaskExecutor --> pushMicroTasks
   end
```

## Information

### Multithreading

This single loop should always run using single thread BUT:
- you can pushTasks and popResults using different threads
- you can execute jobs on multiple threads inside event loop, for example: using this package - https://github.com/jakubtomsu/jobs can give usage of threads similar to what `Promise.all` in javascript can do (BUT on multiple threads!)


### Notes

1. Schedule Tasks
   1. TIMEOUT - single execution delayed by duration (if duration <= 0, task will execute in next flush>)
   2. INTERVAL - multiple executions delayed by duration (duration > 0)
2. UnSchedule Scheduled Tasks
   1. `->task()` procedure returns `ReferenceId` this can be stored and use later for removing task from schedule
   2. unScheduling task in the same flush it was scheduled is much slower (iterate over all tasks scheduled within current flush)
3. Time stops each flush
   1. You provide the time in which flush should happen, this time is the same for all tasks within flush
4. Results are committed to the result queue on flush end
   1. In theory if different thread constantly adds tasks during flush, flush may never end. 
   2. This is something what will probably change in feature, I guess correct solution is to pushResults when task finishes all it's microTasks.

### Usage

Please look at [event loop tests](EventLoop/event-loop.test.odin), my game architecture looks basically the same except I have more detailed error handling and task execution is splitted through many modules rather than having everything in single procedure.


### Contribution
All contributions, bug reports, pull requests, feature requests etc. are more than welcome!