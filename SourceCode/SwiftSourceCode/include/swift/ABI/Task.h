//===--- Task.h - ABI structures for asynchronous tasks ---------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// Swift ABI describing tasks.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_ABI_TASK_H
#define SWIFT_ABI_TASK_H

#include "swift/ABI/TaskLocal.h"
#include "swift/ABI/Executor.h"
#include "swift/ABI/HeapObject.h"
#include "swift/ABI/Metadata.h"
#include "swift/ABI/MetadataValues.h"
#include "swift/Runtime/Config.h"
#include "swift/Basic/STLExtras.h"
#include "bitset"
#include "queue" // TODO: remove and replace with our own mpsc

namespace swift {
class AsyncTask;
class AsyncContext;
class Job;
struct OpaqueValue;
struct SwiftError;
class TaskStatusRecord;
class TaskGroup;

extern FullMetadata<DispatchClassMetadata> jobHeapMetadata;

/// A schedulable job.
class alignas(2 * alignof(void*)) Job : public HeapObject {
public:
  // Indices into SchedulerPrivate, for use by the runtime.
  enum {
    /// The next waiting task link, an AsyncTask that is waiting on a future.
    NextWaitingTaskIndex = 0,

    // The Dispatch object header is one pointer and two ints, which is
    // equvialent to three pointers on 32-bit and two pointers 64-bit. Set the
    // indexes accordingly so that DispatchLinkageIndex points to where Dispatch
    // expects.
    DispatchHasLongObjectHeader = sizeof(void *) == sizeof(int),

    /// An opaque field used by Dispatch when enqueueing Jobs directly.
    DispatchLinkageIndex = DispatchHasLongObjectHeader ? 1 : 0,

    /// The dispatch queue being used when enqueueing a Job directly with
    /// Dispatch.
    DispatchQueueIndex = DispatchHasLongObjectHeader ? 0 : 1,
  };

  // Reserved for the use of the scheduler.
  void *SchedulerPrivate[2];

  JobFlags Flags;

  // We use this union to avoid having to do a second indirect branch
  // when resuming an asynchronous task, which we expect will be the
  // common case.
  union {
    // A function to run a job that isn't an AsyncTask.
    JobInvokeFunction * __ptrauth_swift_job_invoke_function RunJob;

    // A function to resume an AsyncTask.
    TaskContinuationFunction * __ptrauth_swift_task_resume_function ResumeTask;
  };

  Job(JobFlags flags, JobInvokeFunction *invoke,
      const HeapMetadata *metadata = &jobHeapMetadata)
      : HeapObject(metadata), Flags(flags), RunJob(invoke) {
    assert(!isAsyncTask() && "wrong constructor for a task");
  }

  Job(JobFlags flags, TaskContinuationFunction *invoke,
      const HeapMetadata *metadata = &jobHeapMetadata)
      : HeapObject(metadata), Flags(flags), ResumeTask(invoke) {
    assert(isAsyncTask() && "wrong constructor for a non-task job");
  }

  bool isAsyncTask() const {
    return Flags.isAsyncTask();
  }

  JobPriority getPriority() const {
    return Flags.getPriority();
  }

  /// Given that we've fully established the job context in the current
  /// thread, actually start running this job.  To establish the context
  /// correctly, call swift_job_run or runJobInExecutorContext.
  void runInFullyEstablishedContext();

  /// Given that we've fully established the job context in the
  /// current thread, and that the job is a simple (non-task) job,
  /// actually start running this job.
  void runSimpleInFullyEstablishedContext() {
    RunJob(this);
  }
};

// The compiler will eventually assume these.
static_assert(sizeof(Job) == 6 * sizeof(void*),
              "Job size is wrong");
static_assert(alignof(Job) == 2 * alignof(void*),
              "Job alignment is wrong");

/// The current state of a task's status records.
class ActiveTaskStatus {
  enum : uintptr_t {
    IsCancelled = 0x1,
    IsLocked = 0x2,
    RecordMask = ~uintptr_t(IsCancelled | IsLocked)
  };

  uintptr_t Value;

public:
  constexpr ActiveTaskStatus() : Value(0) {}
  ActiveTaskStatus(TaskStatusRecord *innermostRecord,
                   bool cancelled, bool locked)
    : Value(reinterpret_cast<uintptr_t>(innermostRecord)
                + (locked ? IsLocked : 0)
                + (cancelled ? IsCancelled : 0)) {}

  /// Is the task currently cancelled?
  bool isCancelled() const { return Value & IsCancelled; }

  /// Is there an active lock on the cancellation information?
  bool isLocked() const { return Value & IsLocked; }

  /// Return the innermost cancellation record.  Code running
  /// asynchronously with this task should not access this record
  /// without having first locked it; see swift_taskCancel.
  TaskStatusRecord *getInnermostRecord() const {
    return reinterpret_cast<TaskStatusRecord*>(Value & RecordMask);
  }

  static TaskStatusRecord *getStatusRecordParent(TaskStatusRecord *ptr);

  using record_iterator =
    LinkedListIterator<TaskStatusRecord, getStatusRecordParent>;
  llvm::iterator_range<record_iterator> records() const {
    return record_iterator::rangeBeginning(getInnermostRecord());
  }
};

/// An asynchronous task.  Tasks are the analogue of threads for
/// asynchronous functions: that is, they are a persistent identity
/// for the overall async computation.
///
/// ### Fragments
/// An AsyncTask may have the following fragments:
///
///    +--------------------------+
///    | childFragment?           |
///    | groupChildFragment?      |
///    | futureFragment?          |*
///    +--------------------------+
///
/// * The future fragment is dynamic in size, based on the future result type
///   it can hold, and thus must be the *last* fragment.
class AsyncTask : public Job {
public:
  /// The context for resuming the job.  When a task is scheduled
  /// as a job, the next continuation should be installed as the
  /// ResumeTask pointer in the job header, with this serving as
  /// the context pointer.
  ///
  /// We can't protect the data in the context from being overwritten
  /// by attackers, but we can at least sign the context pointer to
  /// prevent it from being corrupted in flight.
  AsyncContext * __ptrauth_swift_task_resume_context ResumeContext;

  /// The currently-active information about cancellation.
  std::atomic<ActiveTaskStatus> Status;

  /// Reserved for the use of the task-local stack allocator.
  void *AllocatorPrivate[4];

  /// Task local values storage container.
  TaskLocal::Storage Local;

  AsyncTask(const HeapMetadata *metadata, JobFlags flags,
            TaskContinuationFunction *run,
            AsyncContext *initialContext)
    : Job(flags, run, metadata),
      ResumeContext(initialContext),
      Status(ActiveTaskStatus()),
      Local(TaskLocal::Storage()) {
    assert(flags.isAsyncTask());
  }

  /// Given that we've already fully established the job context
  /// in the current thread, start running this task.  To establish
  /// the job context correctly, call swift_job_run or
  /// runInExecutorContext.
  void runInFullyEstablishedContext() {
    ResumeTask(ResumeContext);
  }
  
  /// Check whether this task has been cancelled.
  /// Checking this is, of course, inherently race-prone on its own.
  bool isCancelled() const {
    return Status.load(std::memory_order_relaxed).isCancelled();
  }

  // ==== Task Local Values ----------------------------------------------------

  void localValuePush(const Metadata *keyType,
                      /* +1 */ OpaqueValue *value, const Metadata *valueType) {
    Local.pushValue(this, keyType, value, valueType);
  }

  OpaqueValue* localValueGet(const Metadata *keyType,
                             TaskLocal::TaskLocalInheritance inherit) {
    return Local.getValue(this, keyType, inherit);
  }

  void localValuePop() {
    Local.popValue(this);
  }

  // ==== Child Fragment -------------------------------------------------------

  /// A fragment of an async task structure that happens to be a child task.
  class ChildFragment {
    /// The parent task of this task.
    AsyncTask *Parent;

    // TODO: Document more how this is used from the `TaskGroupTaskStatusRecord`

    /// The next task in the singly-linked list of child tasks.
    /// The list must start in a `ChildTaskStatusRecord` registered
    /// with the parent task.
    ///
    /// Note that the parent task may have multiple such records.
    ///
    /// WARNING: Access can only be performed by the `Parent` of this task.
    AsyncTask *NextChild = nullptr;

  public:
    ChildFragment(AsyncTask *parent) : Parent(parent) {}

    AsyncTask *getParent() const {
      return Parent;
    }

    AsyncTask *getNextChild() const {
      return NextChild;
    }

    /// Set the `NextChild` to to the passed task.
    ///
    /// WARNING: This must ONLY be invoked from the parent of both
    /// (this and the passed-in) tasks for thread-safety reasons.
    void setNextChild(AsyncTask *task) {
      NextChild = task;
    }
  };

  bool hasChildFragment() const {
    return Flags.task_isChildTask();
  }

  ChildFragment *childFragment() {
    assert(hasChildFragment());

    auto offset = reinterpret_cast<char*>(this);
    offset += sizeof(AsyncTask);

    return reinterpret_cast<ChildFragment*>(offset);
  }

  // ==== TaskGroup Child ------------------------------------------------------

  /// A child task created by `group.add` is called a "task group child."
  /// Upon completion, in addition to the usual future notifying all its waiters,
  /// it must also `group->offer` itself to the group.
  ///
  /// This signalling is necessary to correctly implement the group's `next()`.
  class GroupChildFragment {
  private:
    TaskGroup* Group;

    friend class AsyncTask;
    friend class TaskGroup;

  public:
    explicit GroupChildFragment(TaskGroup *group)
        : Group(group) {}

    /// Return the group this task should offer into when it completes.
    TaskGroup* getGroup() {
      return Group;
    }
  };

  // Checks if task is a child of a TaskGroup task.
  //
  // A child task that is a group child knows that it's parent is a group
  // and therefore may `groupOffer` to it upon completion.
  bool hasGroupChildFragment() const { return Flags.task_isGroupChildTask(); }

  GroupChildFragment *groupChildFragment() {
    assert(hasGroupChildFragment());

    auto offset = reinterpret_cast<char*>(this);
    offset += sizeof(AsyncTask);
    if (hasChildFragment())
      offset += sizeof(ChildFragment);

    return reinterpret_cast<GroupChildFragment *>(offset);
  }

  // ==== Future ---------------------------------------------------------------

  class FutureFragment {
  public:
    /// Describes the status of the future.
    ///
    /// Futures always begin in the "Executing" state, and will always
    /// make a single state change to either Success or Error.
    enum class Status : uintptr_t {
      /// The future is executing or ready to execute. The storage
      /// is not accessible.
      Executing = 0,

      /// The future has completed with result (of type \c resultType).
      Success,

      /// The future has completed by throwing an error (an \c Error
      /// existential).
      Error,
    };

    /// An item within the wait queue, which includes the status and the
    /// head of the list of tasks.
    struct WaitQueueItem {
      /// Mask used for the low status bits in a wait queue item.
      static const uintptr_t statusMask = 0x03;

      uintptr_t storage;

      Status getStatus() const {
        return static_cast<Status>(storage & statusMask);
      }

      AsyncTask *getTask() const {
        return reinterpret_cast<AsyncTask *>(storage & ~statusMask);
      }

      static WaitQueueItem get(Status status, AsyncTask *task) {
        return WaitQueueItem{
          reinterpret_cast<uintptr_t>(task) | static_cast<uintptr_t>(status)};
      }
    };

  private:
    /// Queue containing all of the tasks that are waiting in `get()`.
    ///
    /// The low bits contain the status, the rest of the pointer is the
    /// AsyncTask.
    std::atomic<WaitQueueItem> waitQueue;

    /// The type of the result that will be produced by the future.
    const Metadata *resultType;

    SwiftError *error = nullptr;

    // Trailing storage for the result itself. The storage will be
    // uninitialized, contain an instance of \c resultType.

    friend class AsyncTask;

  public:
    explicit FutureFragment(const Metadata *resultType)
      : waitQueue(WaitQueueItem::get(Status::Executing, nullptr)),
        resultType(resultType) { }

    /// Destroy the storage associated with the future.
    void destroy();

    const Metadata *getResultType() const {
      return resultType;
    }

    /// Retrieve a pointer to the storage of result.
    OpaqueValue *getStoragePtr() {
      return reinterpret_cast<OpaqueValue *>(
          reinterpret_cast<char *>(this) + storageOffset(resultType));
    }

    /// Retrieve the error.
    SwiftError *&getError() { return error; }

    /// Compute the offset of the storage from the base of the future
    /// fragment.
    static size_t storageOffset(const Metadata *resultType)  {
      size_t offset = sizeof(FutureFragment);
      size_t alignment = resultType->vw_alignment();
      return (offset + alignment - 1) & ~(alignment - 1);
    }

    /// Determine the size of the future fragment given a particular future
    /// result type.
    static size_t fragmentSize(const Metadata *resultType) {
      return storageOffset(resultType) + resultType->vw_size();
    }
  };

  bool isFuture() const { return Flags.task_isFuture(); }

  FutureFragment *futureFragment() {
    assert(isFuture());
    auto offset = reinterpret_cast<char*>(this);
    offset += sizeof(AsyncTask);
    if (hasChildFragment())
      offset += sizeof(ChildFragment);
    if (hasGroupChildFragment())
      offset += sizeof(GroupChildFragment);

    return reinterpret_cast<FutureFragment *>(offset);
  }

  /// Wait for this future to complete.
  ///
  /// \returns the status of the future. If this result is
  /// \c Executing, then \c waitingTask has been added to the
  /// wait queue and will be scheduled when the future completes. Otherwise,
  /// the future has completed and can be queried.
  FutureFragment::Status waitFuture(AsyncTask *waitingTask);

  /// Complete this future.
  ///
  /// Upon completion, any waiting tasks will be scheduled on the given
  /// executor.
  void completeFuture(AsyncContext *context);

  // ==== ----------------------------------------------------------------------

  static bool classof(const Job *job) {
    return job->isAsyncTask();
  }

private:
  /// Access the next waiting task, which establishes a singly linked list of
  /// tasks that are waiting on a future.
  AsyncTask *&getNextWaitingTask() {
    return reinterpret_cast<AsyncTask *&>(
        SchedulerPrivate[NextWaitingTaskIndex]);
  }
};

// The compiler will eventually assume these.
static_assert(sizeof(AsyncTask) == 14 * sizeof(void*),
              "AsyncTask size is wrong");
static_assert(alignof(AsyncTask) == 2 * alignof(void*),
              "AsyncTask alignment is wrong");

inline void Job::runInFullyEstablishedContext() {
  if (auto task = dyn_cast<AsyncTask>(this))
    task->runInFullyEstablishedContext();
  else
    runSimpleInFullyEstablishedContext();
}

/// An asynchronous context within a task.  Generally contexts are
/// allocated using the task-local stack alloc/dealloc operations, but
/// there's no guarantee of that, and the ABI is designed to permit
/// contexts to be allocated within their caller's frame.
class alignas(MaximumAlignment) AsyncContext {
public:
  /// The parent context.
  AsyncContext * __ptrauth_swift_async_context_parent Parent;

  /// The function to call to resume running in the parent context.
  /// Generally this means a semantic return, but for some temporary
  /// translation contexts it might mean initiating a call.
  ///
  /// Eventually, the actual type here will depend on the types
  /// which need to be passed to the parent.  For now, arguments
  /// are always written into the context, and so the type is
  /// always the same.
  TaskContinuationFunction * __ptrauth_swift_async_context_resume
    ResumeParent;

  /// Flags describing this context.
  ///
  /// Note that this field is only 32 bits; any alignment padding
  /// following this on 64-bit platforms can be freely used by the
  /// function.  If the function is a yielding function, that padding
  /// is of course interrupted by the YieldToParent field.
  AsyncContextFlags Flags;

  AsyncContext(AsyncContextFlags flags,
               TaskContinuationFunction *resumeParent,
               AsyncContext *parent)
    : Parent(parent), ResumeParent(resumeParent),
      Flags(flags) {}

  AsyncContext(const AsyncContext &) = delete;
  AsyncContext &operator=(const AsyncContext &) = delete;

  /// Perform a return from this context.
  ///
  /// Generally this should be tail-called.
  SWIFT_CC(swiftasync)
  void resumeParent() {
    // TODO: destroy context before returning?
    // FIXME: force tail call
    return ResumeParent(Parent);
  }
};

/// An async context that supports yielding.
class YieldingAsyncContext : public AsyncContext {
public:
  /// The function to call to temporarily resume running in the
  /// parent context.  Generally this means a semantic yield.
  TaskContinuationFunction * __ptrauth_swift_async_context_yield
    YieldToParent;

  YieldingAsyncContext(AsyncContextFlags flags,
                       TaskContinuationFunction *resumeParent,
                       TaskContinuationFunction *yieldToParent,
                       AsyncContext *parent)
    : AsyncContext(flags, resumeParent, parent),
      YieldToParent(yieldToParent) {}

  static bool classof(const AsyncContext *context) {
    return context->Flags.getKind() == AsyncContextKind::Yielding;
  }
};

/// An async context that can be resumed as a continuation.
class ContinuationAsyncContext : public AsyncContext {
public:
  /// An atomic object used to ensure that a continuation is not
  /// scheduled immediately during a resume if it hasn't yet been
  /// awaited by the function which set it up.
  std::atomic<ContinuationStatus> AwaitSynchronization;

  /// The error result value of the continuation.
  /// This should be null-initialized when setting up the continuation.
  /// Throwing resumers must overwrite this with a non-null value.
  SwiftError *ErrorResult;

  /// A pointer to the normal result value of the continuation.
  /// Normal resumers must initialize this before resuming.
  OpaqueValue *NormalResult;

  /// The executor that should be resumed to.
  ExecutorRef ResumeToExecutor;

  static bool classof(const AsyncContext *context) {
    return context->Flags.getKind() == AsyncContextKind::Continuation;
  }
};

/// An asynchronous context within a task that describes a general "Future".
/// task.
///
/// This type matches the ABI of a function `<T> () async throws -> T`, which
/// is the type used by `detach` and `Task.group.add` to create
/// futures.
class FutureAsyncContext : public AsyncContext {
public:
  using AsyncContext::AsyncContext;
};

/// This matches the ABI of a closure `() async throws -> ()`
using AsyncVoidClosureEntryPoint =
  SWIFT_CC(swiftasync)
  void (SWIFT_ASYNC_CONTEXT AsyncContext *, SWIFT_CONTEXT HeapObject *);

/// This matches the ABI of a closure `<T>() async throws -> T`
using AsyncGenericClosureEntryPoint =
    SWIFT_CC(swiftasync)
    void(OpaqueValue *,
         SWIFT_ASYNC_CONTEXT AsyncContext *, SWIFT_CONTEXT HeapObject *);

/// This matches the ABI of the resume function of a closure
///  `() async throws -> ()`.
using AsyncVoidClosureResumeEntryPoint =
  SWIFT_CC(swiftasync)
  void(SWIFT_ASYNC_CONTEXT AsyncContext *, SWIFT_CONTEXT SwiftError *);

class AsyncContextPrefix {
public:
  // Async closure entry point adhering to compiler calling conv (e.g directly
  // passing the closure context instead of via the async context)
  AsyncVoidClosureEntryPoint *__ptrauth_swift_task_resume_function
      asyncEntryPoint;
   HeapObject *closureContext;
  SwiftError *errorResult;
};

/// Storage that is allocated before the AsyncContext to be used by an adapter
/// of Swift's async convention and the ResumeTask interface.
class FutureAsyncContextPrefix {
public:
  OpaqueValue *indirectResult;
  // Async closure entry point adhering to compiler calling conv (e.g directly
  // passing the closure context instead of via the async context)
  AsyncGenericClosureEntryPoint *__ptrauth_swift_task_resume_function
      asyncEntryPoint;
  HeapObject *closureContext;
  SwiftError *errorResult;
};

} // end namespace swift

#endif
