+++
title = "Introduction to JDK Flight Recorder"
date = 2026-03-21
+++

## Overview
JDK Flight Recorder is a tool, integrated in JVM, for collecting diagnostics and profiling data from running Java applications. It causes insignificant performance overhead in the running application, so it can be enabled in high-load production environment.

## Events
JFR collects data in events. An event is comprised of a name, timestamp and its payload. The payload usually has information about the stack trace, CPU usage, head size before and after the event, etc. There are 3 types of JRF events:

1. **Duration Event**: it is logged only when it is completed. Setting a threshold for this type of event, would only record the events that exceed the threshold. This oprtion is not available for the other types of events.
2. **Instant Event**: it is logged immediately.
3. **Sample Event**: it is logged in intervals.

JFR provides built-in events that monitor the behavior of the JVM. Custom events can also be configured programmatically that will help you to monitor the behavior of your application running in JVM. To configure a custom event you need to extend the 
`jdk.jfr.Event` abstarct class:

```java
@Category("Payment")
@Label("PaymentCreation")
public class PaymentEvent extends jdk.jfr.Event {
    @Description("Payment ID")
    private String paymentId;
    
    @Description("Amount")
    private double amount;
    
    public void setPaymentId(String paymentId) {
        this.paymentId = paymentId;
    }
    
    public void setAmount(double amount) {
        this.amount = amount;
    }
}
```

In the previoud example we have defined an event that contains information about the payment id and amount. To record this event, the `commit()` method needs to be called:

```java
    public void execute(PaymentModel paymentModel) {
        try {
            
            // initialize the event
            PaymentEvent paymentEvent = new PaymentEvent();
            paymentEvent.setPaymentId(paymentModel.paymentId());
            paymentEvent.setAmount(paymentModel.amount());

            paymentEvent.begin();
            Thread.sleep(100);
            paymentEvent.end();
            paymentEvent.commit();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
```
If you want to record the time taken to execute the business operation which this event record, surround it by the `begin()` and `end()` method which indicate the beginning of the event and completion of theoperation.

### Activating JFR
To activate the JFR in the application JVM is running, you need to include the following options on the run command:
`java -XX:+FlightRecorder App`,
or include these JVM args into the run task on a Gradle project, build file:
```groovy
run {
    jvmArgs = [
        "-XX:StartFlightRecording=filename=events.jfr,settings=profile"
    ]
}
```

The settings option defines the way the data will be collected. There are 2 types of settings:
1. **Default**
JFR will collect basic GC, CPU, and Safepoint information. It is recommended to be used for continuous 24/7 production monitoring.

2. **Profile**
The JVM starts sampling the execution stacks of your threads frequently. This allows you to see exactly which methods are consuming the most CPU. A drawback of this option is that it captures much more data than default option. In a high-throughput environment, it can result in very large .jfr files in a short amount of time.

### Analyzing JFR Files

Analyzing the .jfr record files produced by the JDK Flight Recorder, we can use Java Mission Control tool, which is a graphical user interface tool, or the jfr cli. To get a summary of the recorded events, run the following command:
```bash
jfr summary <filename>
```
To fetch the details of recorded event, run the following command:
```bash
jfr print --events <filter> <filename>
```

For our payment application example, the output of the previous command is:
```json
emu.experimental.jfr.events.PaymentEvent {
  startTime = 00:45:18.223 (2026-03-27)
  duration = 103 ms
  paymentId = "id1"
  amount = 3.14
  eventThread = "http-nio-8080-exec-1" (javaThreadId = 45)
  stackTrace = [
    emu.experimental.jfr.domain.CreatePaymentUseCase.execute(PaymentModel) line: 19
    emu.experimental.jfr.rest.PaymentController.makePayment(PaymentRequest) line: 29
    jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Object, Object[]) line: 104
    java.lang.reflect.Method.invoke(Object, Object[]) line: 565
    org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(Object[]) line: 252
  ]
}
```
which provides us information about the duration of the operation, thread in which the operation ran and the stacktrace.

To check out the full source code, go to [Github](https://github.com/enismustafaj/jfr).
