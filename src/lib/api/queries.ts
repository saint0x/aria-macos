import { mockTasks } from "@/lib/data/mock-tasks"
import { mockLogs } from "@/lib/data/mock-logs"
import type { GetTasksResponse, GetLogsResponse } from "@/lib/types"
import { parseISO } from "date-fns"

// Simulate network delay
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

/**
 * @description Fetches the list of tasks.
 * @returns A promise that resolves to the list of tasks.
 * TODO: Replace with a real API call.
 */
export const fetchTasks = async (): Promise<GetTasksResponse> => {
  console.log("Fetching tasks...")
  await sleep(500) // Simulate network latency
  // In a real app, you would fetch from an endpoint:
  // const response = await fetch('/api/tasks');
  // if (!response.ok) throw new Error('Failed to fetch tasks');
  // return response.json();
  return { tasks: mockTasks }
}

/**
 * @description Fetches activity logs based on a date range.
 * @param from - The start date of the range.
 * @param to - The end date of the range.
 * @returns A promise that resolves to the filtered logs.
 * TODO: Replace with a real API call with pagination.
 */
export const fetchLogs = async (from: Date, to: Date): Promise<GetLogsResponse> => {
  console.log(`Fetching logs from ${from.toISOString()} to ${to.toISOString()}`)
  await sleep(750) // Simulate network latency

  const filteredLogs = mockLogs.filter((log) => {
    const logTimestamp = parseISO(log.timestamp)
    return logTimestamp >= from && logTimestamp <= to
  })

  const sortedLogs = filteredLogs.sort((a, b) => parseISO(b.timestamp).getTime() - parseISO(a.timestamp).getTime())

  return {
    logs: sortedLogs,
    pageInfo: {
      hasNextPage: false, // Placeholder for pagination
      endCursor: null,
    },
  }
}
