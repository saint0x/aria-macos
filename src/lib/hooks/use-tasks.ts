"use client"

import { useQuery } from "@tanstack/react-query"
import { fetchTasks } from "@/lib/api/queries"

export const useTasks = () => {
  return useQuery({
    queryKey: ["tasks"],
    queryFn: fetchTasks,
  })
}
