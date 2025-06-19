"use client"

import { useQuery } from "@tanstack/react-query"
import { fetchLogs } from "@/lib/api/queries"
import type { DateRange } from "react-day-picker"

export const useLogs = (dateRange: DateRange | undefined) => {
  return useQuery({
    queryKey: ["logs", dateRange],
    queryFn: () => {
      if (!dateRange?.from || !dateRange?.to) {
        // Or throw an error, depending on desired behavior for invalid range
        return Promise.resolve({ logs: [], pageInfo: { hasNextPage: false, endCursor: null } })
      }
      return fetchLogs(dateRange.from, dateRange.to)
    },
    enabled: !!dateRange?.from && !!dateRange?.to, // Only run query if range is valid
  })
}
