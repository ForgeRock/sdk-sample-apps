/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.data

import com.pingidentity.logger.Logger
import com.pingidentity.logger.Standard
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID.randomUUID
import java.util.concurrent.ConcurrentLinkedQueue
import kotlin.collections.emptyList

/**
 * Data class representing a log entry.
 */
data class LogEntry(
    /** Unique identifier for this log entry. */
    val id: String = randomUUID().toString(),
    /** Human-readable timestamp formatted as `yyyy-MM-dd HH:mm:ss.SSS`. */
    val timestamp: String,
    /** Severity level string: `DEBUG`, `INFO`, `WARN`, or `ERROR`. */
    val level: String,
    /** The log message body. */
    val message: String,
    /** Formatted exception detail (class name, message, stack trace), or `null` if no throwable was supplied. */
    val throwable: String? = null
)

/**
 * Diagnostic logger that captures logs in memory for debugging purposes.
 * This logger wraps the standard logger and also stores logs for later viewing.
 */
object DiagnosticLogger : Logger {
    private val standardLogger = Standard()
    private val logEntries = ConcurrentLinkedQueue<LogEntry>()

    // DateTimeFormatter is immutable and thread-safe; SimpleDateFormat is not.
    private val dateFormat = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS")

    private const val MAX_LOG_ENTRIES = 1000

    private val _logs = MutableStateFlow<List<LogEntry>>(emptyList())
    /** Observable snapshot of the in-memory log buffer, capped at [MAX_LOG_ENTRIES] entries. */
    val logs: StateFlow<List<LogEntry>> = _logs.asStateFlow()

    private fun addLogEntry(level: String, message: String, throwable: Throwable? = null) {
        val timestamp = dateFormat.format(LocalDateTime.now())
        val throwableString = throwable?.let {
            "${it.javaClass.simpleName}: ${it.message}\n${it.stackTraceToString()}"
        }

        val logEntry = LogEntry(
            timestamp = timestamp,
            level = level,
            message = message,
            throwable = throwableString
        )

        logEntries.add(logEntry)

        // Keep only the last MAX_LOG_ENTRIES entries
        while (logEntries.size > MAX_LOG_ENTRIES) {
            logEntries.poll()
        }

        // Snapshot the queue into the StateFlow atomically so concurrent callers cannot observe
        // a _logs value that is older than the queue state at this point. Using update() rather
        // than direct assignment ensures the lambda always runs against the latest state and the
        // CAS loop in MutableStateFlow retries on contention.
        _logs.update { logEntries.toList() }
    }

    /** Logs a DEBUG-level [message] and stores it in the in-memory buffer. */
    override fun d(message: String) {
        standardLogger.d(message)
        addLogEntry("DEBUG", message)
    }

    /** Logs an INFO-level [message] and stores it in the in-memory buffer. */
    override fun i(message: String) {
        standardLogger.i(message)
        addLogEntry("INFO", message)
    }

    /** Logs a WARN-level [message] (with optional [throwable]) and stores it in the in-memory buffer. */
    override fun w(message: String, throwable: Throwable?) {
        standardLogger.w(message, throwable)
        addLogEntry("WARN", message, throwable)
    }

    /** Logs an ERROR-level [message] (with optional [throwable]) and stores it in the in-memory buffer. */
    override fun e(message: String, throwable: Throwable?) {
        standardLogger.e(message, throwable)
        addLogEntry("ERROR", message, throwable)
    }

    /**
     * Clear all captured log entries.
     */
    fun clearLogs() {
        logEntries.clear()
        _logs.update { emptyList() }
    }

    /**
     * Export all logs as a formatted string.
     */
    fun exportLogs(): String {
        val sb = StringBuilder()
        sb.appendLine("=== Diagnostic Logs Export ===")
        sb.appendLine("Exported at: ${dateFormat.format(LocalDateTime.now())}")
        sb.appendLine("Total entries: ${logEntries.size}")
        sb.appendLine()

        logEntries.forEach { entry ->
            sb.appendLine("[${entry.timestamp}] ${entry.level}: ${entry.message}")
            entry.throwable?.let { throwable ->
                sb.appendLine("Exception: $throwable")
            }
            sb.appendLine()
        }

        return sb.toString()
    }
}
