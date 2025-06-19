import type { z } from "zod"

// Enums for consistent status representation
export enum LogLevel {
  INFO = "INFO",
  WARN = "WARN",
  ERROR = "ERROR",
  DEBUG = "DEBUG",
  SUCCESS = "SUCCESS",
}

export enum ProcessStatus {
  STARTED = "STARTED",
  IN_PROGRESS = "IN_PROGRESS",
  COMPLETED = "COMPLETED",
  FAILED = "FAILED",
  TOOL_CALL = "TOOL_CALL",
  TOOL_RESPONSE = "TOOL_RESPONSE",
  THINKING = "THINKING",
}

export enum TaskStatus {
  COMPLETED = "completed",
  IN_PROGRESS = "in-progress",
  FAILED = "failed",
  PENDING = "pending",
  RUNNING = "running",
}

export enum StepType {
  THOUGHT = "thought",
  TOOL = "tool",
  RESPONSE = "response",
  USER_MESSAGE = "userMessage",
}

export enum StepStatus {
  PENDING = "pending",
  ACTIVE = "active",
  COMPLETED = "completed",
  FAILED = "failed",
}

// Data structure for a single Log Entry
export interface LogEntry {
  id: string
  timestamp: string // ISO string
  level: LogLevel
  message: string
  source: string
  entityName?: string
  actor?: string
  status?: ProcessStatus
  durationMs?: number
  details?: Record<string, any>
}

// Data structure for a single Task
export interface Task {
  id: string
  name: string
  status: TaskStatus
  agent?: string
  tools?: string[]
  currentStepDescription?: string
  fullDescription: string
  startTime?: string // ISO string
  endTime?: string // ISO string
  detailIdentifier: string
}

// Data structure for an AI interaction step
export interface EnhancedStep {
  id: string
  type: StepType
  text: string
  status?: StepStatus
  toolName?: string
  toolInput?: any
  isIndented?: boolean
  timestamp?: string // ISO string
}

// API I/O Structures
// ChatRequestPayload will be replaced with gRPC types later

// Placeholder for API response structures
export interface GetTasksResponse {
  tasks: Task[]
}

export interface GetLogsResponse {
  logs: LogEntry[]
  pageInfo: {
    hasNextPage: boolean
    endCursor: string | null
  }
}
