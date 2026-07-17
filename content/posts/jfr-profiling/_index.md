+++
title = "Profiling HTTP Requests with JFR Events"
+++

## What is profiling?

Profiling is the practice of observing a running program to figure out where it actually spends its time and resources, as opposed to guessing based on how the code reads. For a web application, that usually means: which methods dominate CPU time while a request is being handled? A profiler answers that by periodically sampling the call stack of a thread while it runs, and aggregating those samples into a picture of "hot" code paths.

## How I'm using JFR events

[JDK Flight Recorder](https://openjdk.org/jeps/328) (JFR) already knows how to do this sampling — it's built into the JVM and ships events like `jdk.ExecutionSample`, which periodically records the stack trace of a running thread. Instead of running one long, always-on recording, I wanted a profile scoped to a single HTTP request: start a recording when the request comes in, stop it when the request finishes, and export just that slice.

The mechanics, briefly:

1. A Spring `HandlerInterceptor` starts a `jdk.jfr.Recording` in `preHandle`, enabling the execution-sampling event.
2. In `afterCompletion`, the recording is stopped and handed off asynchronously to be dumped to a temporary `.jfr` file and read back with `jdk.jfr.consumer.RecordingFile`.
3. The events are filtered down to the thread that handled the request, then converted into a [pprof](https://github.com/google/pprof) profile so they can be visualized as a flame graph or pushed to an observability backend.

Each request produces its own small profile, so the sampling cost is scoped to the request instead of running continuously across the whole application.

## A wrinkle: safepoint bias

The classic `jdk.ExecutionSample` event samples via a mechanism tied to *safepoints* — points in the code where the JVM can safely inspect a thread's stack. The sampler asks a thread to report its stack the next time it reaches one of these points, rather than at the exact instant the sampling timer fires. Most code hits safepoints constantly (method calls, allocations), so the skew is small. But the JIT compiler can strip safepoint checks out of tight, provably-terminating loops — which means that code can go completely unsampled, even while it's clearly consuming CPU. This is called *safepoint bias*, and it systematically under-represents exactly the kind of hot, optimized loops you'd most want visibility into.

JDK 25 introduces [`jdk.CPUTimeSample`](https://openjdk.org/jeps/509) (JEP 509), which samples via a per-thread CPU-time signal instead of waiting for a safepoint — so it doesn't have this blind spot. It's Linux-only for now, so I use it there and fall back to `jdk.ExecutionSample` elsewhere.

I'm not going to try to re-explain safepoints better than the person who already has — [The Inner Workings of Safepoints](https://mostlynerdless.de/blog/2023/07/31/the-inner-workings-of-safepoints/) on mostlynerdless.de is the best writeup I've found on how safepoints actually work under the hood. The same author also wrote a two-part series on JEP 509 itself, which is worth reading if you want the implementation details behind `jdk.CPUTimeSample`:

- [Java 25's new CPU-Time Profiler (1)](https://mostlynerdless.de/blog/2025/06/11/java-25s-new-cpu-time-profiler-1/)
- [Java 25's new CPU-Time Profiler: The Implementation (2)](https://mostlynerdless.de/blog/2025/07/30/java-25s-new-cpu-time-profiler-the-implementation-2/)
