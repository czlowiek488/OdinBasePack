# OdinBasePack

This package contains a group of different data structures I use to develop my odin apps and games.

The most important is event-loop.

This is my custom implementation of event loop lightly inspired by node.js.

This provides a ready to use base for event-driven applications.

Be aware that event-loop implementation is naive and may not meet more sophisticated requirements.

This implementation contains many shortcuts that make implementation trivial but makes sacrifices in other areas like edge-case performance.

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
   classDef TaskResult fill:aqua,color:black

   pushTasks["pushTasks()"]:::Operation
   popResults["popResults()"]:::Operation
   flush["flush()"]:::Operation
   task["->task()"]:::Operation
   microTask["->microTask()"]:::Operation
   result["->result()"]:::Operation
   unSchedule["->unSchedule()"]:::Operation

   taskExecutor[Task Executor]:::Executor
   microTaskExecutor[Micro Task Executor]:::Executor

   taskQueue[Task Queue]:::Queue
   microTaskQueue[Micro Task Queue]:::Queue
   scheduledQueue[Priority Queue]:::Queue
   resultQueue[Result Queue]:::Queue
   
   Finish:::Finish
   TaskFinish["Finish"]:::Finish
   TaskStart["Start"]:::Finish

   processScheduledTask["Process Scheduled Task"]:::Process
   processTask["Process Task"]:::Process
   passResultsToQueue["Pass Results To Queue"]:::Process
   passScheduledTasksToQueue["Pass Scheduled Tasks to Queue"]:::Process
   scheduleTask["Schedule Task"]:::Process

   pushMicroTasks["Push Micro Tasks"]:::Process

   nextScheduledTaskPresent@{ shape: diamond, label: "Next scheduled present?" }
   isInterval@{ shape: diamond, label: "Is Interval?" }
   nextTaskPresent@{ shape: diamond, label: "Next task present?" }
   nextMicroTaskPresent@{ shape: diamond, label: "Next micro present?" }

   pushTasks --> taskQueue
   resultQueue --> popResults
   flush --> nextTaskPresent
   nextTaskPresent -->|yes| processTask
   processTask --> nextTaskPresent
   nextTaskPresent -->|no| nextScheduledTaskPresent
   nextScheduledTaskPresent -->|yes| isInterval
   isInterval -->|yes| scheduleTask
   scheduleTask --> processScheduledTask 
   isInterval -->|no| processScheduledTask
   processScheduledTask --> nextScheduledTaskPresent
   nextScheduledTaskPresent -->|no| Finish 


   processScheduledTask -.- ProcessTask
   processTask -.- ProcessTask
   nextTaskPresent -.- taskQueue
   passResultsToQueue -.- resultQueue
   passScheduledTasksToQueue -.- scheduledQueue
   nextScheduledTaskPresent -.- scheduledQueue
   nextMicroTaskPresent -.- microTaskQueue
   pushMicroTasks -.- microTaskQueue
   scheduleTask -.- scheduledQueue

   taskResult:::TaskResult
   unSchedule --> scheduledQueue

   subgraph TaskResult
      task --> taskResult
      result --> taskResult
   end

   subgraph ProcessTask
      taskExecutor --> pushMicroTasks
      unSchedule --> taskResult
      microTask -.- taskExecutor
      unSchedule -.- taskExecutor
      result -.- taskExecutor
      task -.- taskExecutor
      microTask -.- microTaskQueue
      TaskStart --> taskExecutor
      pushMicroTasks --> nextMicroTaskPresent
      nextMicroTaskPresent -->|yes| microTaskExecutor
      nextMicroTaskPresent -->|no| passResultsToQueue
      passResultsToQueue --> passScheduledTasksToQueue
      passResultsToQueue -.- taskResult
      passScheduledTasksToQueue --> TaskFinish
      passScheduledTasksToQueue -.- taskResult
      microTaskExecutor --> pushMicroTasks
   end
```

## Information

### Multithreading

This single loop should always run using single thread BUT:
- you can `pushTasks()` using different thread
- you can `popResults()` using different thread
- you MUST use mutex if you want to `pushTasks()` from multiple threads
- you MUST use mutex if you want to `popResults()` from multiple threads

Event loop runs inside a single thread but it can execute multithreading work.
For example using [this package](https://github.com/jakubtomsu/jobs) allows to schedule jobs to be executed on separate threads, using syntax similar to javascript `Promise.all`.


### Usage

1. `->task()` - Scheduling New Tasks
   1. TIMEOUT - single execution delayed by duration
      1. if duration is equal to 0 - executes task after all current tasks inside current flush
      2. if duration is greater than 0 - task will not be executed in current flush
   2. INTERVAL - multiple executions delayed by duration
      1. duration must be greater than 0 - tasks will be executed until unScheduled
   3. At the end of task execution scheduled tasks and results are commited to the appriopriate queues.
2. `->unSchedule()` UnSchedule Scheduled Tasks
   1. `->task()` procedure returns `ReferenceId`
   2. `ReferenceId` allows to unSchedule scheduled tasks
3. `->microTask()` Schedule Micro Task
   1. micro task is added to the end of microtask queue, always executes within the same task execution
4. `->result()` Add Result
   1. use this to add results to the result queue, you can then read results using `popResults()` function
5. Event loop current time changes once per flush.
6. In theory if different thread constantly adds tasks during flush, flush may never end. 

### Usage

Please look at [event loop tests](EventLoop/event-loop.test.odin), my game architecture looks basically the same except I have more detailed error handling and task execution is splitted through many modules rather than having everything in single procedure.


### Contribution
All contributions, bug reports, pull requests, feature requests etc. are more than welcome!