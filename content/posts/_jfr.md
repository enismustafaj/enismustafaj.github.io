# Java Flight Record

### Overview
Java flight record is a tool, integrated in JVM, for collecting diagnostics and profiling data from running Java applications. It causes insignificant performance overhead in the running application, so it can be enabled in high load production environaments.

### Events
JFR collects data in events. An event is comprised of a name, timestamp and its payload. The payload usually has information about the
