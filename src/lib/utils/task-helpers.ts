import { TaskStatus, type Task } from "@/lib/types"

export interface StatusDisplayInfo {
  text: string
  textColor: string
  dotColor: string
}

export const getStatusDisplayInfo = (status: Task["status"]): StatusDisplayInfo => {
  switch (status) {
    case TaskStatus.COMPLETED:
      return {
        text: "Completed",
        textColor: "text-green-600 dark:text-green-500",
        dotColor: "bg-green-500",
      }
    case TaskStatus.RUNNING:
      return {
        text: "Running",
        textColor: "text-green-600 dark:text-green-500",
        dotColor: "bg-green-500",
      }
    case TaskStatus.IN_PROGRESS:
      return {
        text: "Paused",
        textColor: "text-yellow-600 dark:text-yellow-500",
        dotColor: "bg-yellow-500",
      }
    case TaskStatus.FAILED:
      return {
        text: "Failed",
        textColor: "text-red-600 dark:text-red-500",
        dotColor: "bg-red-500",
      }
    case TaskStatus.PENDING:
      return {
        text: "Pending",
        textColor: "text-neutral-600 dark:text-neutral-400",
        dotColor: "bg-neutral-500 dark:bg-neutral-600",
      }
    default:
      const _exhaustiveCheck: never = status
      return {
        text: "Unknown",
        textColor: "text-neutral-500 dark:text-neutral-400",
        dotColor: "bg-neutral-500",
      }
  }
}
