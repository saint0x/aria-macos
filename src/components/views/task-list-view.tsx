"use client"
import { cn } from "@/lib/utils"
import { ChevronRightIcon, Loader2 } from "lucide-react"
import type { Task } from "@/lib/types"
import { getStatusDisplayInfo } from "@/lib/utils/task-helpers"
import { useTasks } from "@/lib/hooks/use-tasks"

interface TaskListViewProps {
  onTaskSelect: (task: Task) => void
}

export function TaskListView({ onTaskSelect }: TaskListViewProps) {
  const { data, isLoading, isError, error } = useTasks()

  if (isLoading) {
    return (
      <div className="flex items-center justify-center p-8 text-sm text-neutral-600 dark:text-neutral-400">
        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
        Loading tasks...
      </div>
    )
  }

  if (isError) {
    return (
      <div className="p-4 text-center text-sm text-red-600 dark:text-red-400 animate-slide-up-fade">
        Error loading tasks: {error.message}
      </div>
    )
  }

  const tasks = data?.tasks ?? []

  if (tasks.length === 0) {
    return (
      <div className="p-4 text-center text-sm text-neutral-600 dark:text-neutral-400 animate-slide-up-fade">
        No tasks to display.
      </div>
    )
  }

  return (
    <div className="space-y-2 animate-slide-up-fade pt-1">
      {tasks.map((task) => {
        const statusInfo = getStatusDisplayInfo(task.status)
        return (
          <div
            key={task.id}
            className={cn(
              "flex items-center justify-between p-3 rounded-xl",
              "bg-white/20 dark:bg-neutral-700/20 hover:bg-white/30 dark:hover:bg-neutral-700/30",
              "cursor-pointer transition-colors duration-150 shadow-apple-sm",
            )}
            onClick={() => onTaskSelect(task)}
          >
            <div className="flex flex-col min-w-0">
              <span className="text-sm text-neutral-800 dark:text-neutral-100 truncate" title={task.name}>
                {task.name}
              </span>
              <div className="flex items-center mt-1 pl-4">
                <span
                  className={cn("h-1.5 w-1.5 rounded-full mr-2 flex-shrink-0", statusInfo.dotColor)}
                  aria-hidden="true"
                />
                <span className={cn("text-xs", statusInfo.textColor)}>{statusInfo.text}</span>
              </div>
            </div>
            <ChevronRightIcon className="h-5 w-5 text-neutral-500 dark:text-neutral-400 flex-shrink-0 self-center" />
          </div>
        )
      })}
    </div>
  )
}
