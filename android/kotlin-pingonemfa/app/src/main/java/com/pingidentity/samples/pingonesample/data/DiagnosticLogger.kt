/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.data

import android.annotation.SuppressLint
import com.pingidentity.logger.Logger
import com.pingidentity.logger.Standard
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID.randomUUID
import java.util.concurrent.ConcurrentLinkedQueue
import kotlin.collections.emptyList

/**
 * Data class representing a log entry.
 */
data class LogEntry(
    val id: String = randomUUID().toString(),
    val timestamp: String,
    val level: String,
    val message: String,
    val throwable: String? = null
)

/**
 * Diagnostic logger that captures logs in memory for debugging purposes.
 * This logger wraps the standard logger and also stores logs for later viewing.
 */
object DiagnosticLogger : Logger {
    private val standardLogger = Standard()
    private val logEntries = ConcurrentLinkedQueue<LogEntry>()

    @SuppressLint("ConstantLocale")
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.getDefault())

    private const val MAX_LOG_ENTRIES = 1000

    private val _logs = MutableStateFlow<List<LogEntry>>(emptyList())
    val logs: StateFlow<List<LogEntry>> = _logs.asStateFlow()

    private fun addLogEntry(level: String, message: String, throwable: Throwable? = null) {
        val timestamp = dateFormat.format(Date())
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

    override fun d(message: String) {
        standardLogger.d(message)
        addLogEntry("DEBUG", message)
    }

    override fun i(message: String) {
        standardLogger.i(message)
        addLogEntry("INFO", message)
    }

    override fun w(message: String, throwable: Throwable?) {
        standardLogger.w(message, throwable)
        addLogEntry("WARN", message, throwable)
    }

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
        sb.appendLine("Exported at: ${dateFormat.format(Date())}")
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
