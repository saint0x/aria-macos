"use client"

import { useEffect, useState } from "react"
import { cn } from "@/lib/utils"
import { XIcon, CheckCircle2Icon, AlertTriangleIcon } from "lucide-react"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion"
import type { EnhancedStep, Task } from "@/lib/types"
import { StepType } from "@/lib/types"
import { getStatusDisplayInfo, type StatusDisplayInfo } from "@/lib/utils/task-helpers"
import { format, parseISO, isValid } from "date-fns"
import { useBlur } from "@/lib/contexts/blur-context"

interface StepDetailPaneProps {
  step: EnhancedStep | null
  onClose: () => void
  className?: string
  mockTasksForDetailPane?: Task[]
  // blurIntensity prop is removed
}

interface SectionContent {
  richText: string
  jsonData: object
}

interface StepDetailsContent {
  input: SectionContent
  thinking: SectionContent
  output: SectionContent
  taskStatus?: Task["status"]
  isAiStep: boolean
}

const getStepDetailsContent = (item: EnhancedStep | null, allTasks?: Task[]): StepDetailsContent | null => {
  if (!item) return null

  if (item.text?.startsWith("TASK_DETAIL_")) {
    const taskId = item.text.replace("TASK_DETAIL_", "")
    const task = allTasks?.find((t) => t.id === taskId)
    if (task) {
      let inputRichText = `Task Name: ${task.name}\n`
      const taskStatusInfo = getStatusDisplayInfo(task.status)
      inputRichText += `Status: ${taskStatusInfo.text}\n\n`

      if (task.fullDescription) {
        inputRichText += `Description:\n${task.fullDescription}\n\n`
      }
      if (task.agent) {
        inputRichText += `Agent: ${task.agent}\n`
      }
      if (task.tools && task.tools.length > 0) {
        inputRichText += `Tools: ${task.tools.join(", ")}\n`
      }
      inputRichText += "\n"
      if (task.startTime) {
        const startTime = parseISO(task.startTime)
        if (isValid(startTime)) {
          inputRichText += `Start Time: ${format(startTime, "MMM d, yyyy 'at' HH:mm")}\n`
        }
      }
      if (task.endTime) {
        const endTime = parseISO(task.endTime)
        if (isValid(endTime)) {
          inputRichText += `End Time: ${format(endTime, "MMM d, yyyy 'at' HH:mm")}\n`
        }
      }
      inputRichText = inputRichText.trim()

      return {
        input: {
          richText: inputRichText,
          jsonData: { ...task },
        },
        thinking: {
          richText: task.currentStepDescription || "No specific step details.",
          jsonData: { currentStepDescription: task.currentStepDescription },
        },
        output: { richText: `Task ID: ${task.id}`, jsonData: { id: task.id } },
        taskStatus: task.status,
        isAiStep: false,
      }
    }
  }

  if (item.type === StepType.TOOL) {
    return {
      input: {
        richText: `Tool: ${item.toolName || "Unknown Tool"}\nInput: ${item.toolInput ? JSON.stringify(item.toolInput, null, 2) : "N/A"}`,
        jsonData: { toolName: item.toolName, input: item.toolInput, status: item.status },
      },
      thinking: {
        richText: `Status: ${item.status || "N/A"}\nDetails: ${item.text}`,
        jsonData: { status: item.status, message: item.text },
      },
      output: {
        richText: "Tool output would appear here.",
        jsonData: { result: "mock_tool_output_data" },
      },
      isAiStep: true,
      taskStatus: undefined,
    }
  }

  if (item.type === StepType.THOUGHT) {
    return {
      input: {
        richText: `Thought Process: ${item.text}`,
        jsonData: { thought: item.text, status: item.status },
      },
      thinking: {
        richText: `Current Status: ${item.status || "N/A"}`,
        jsonData: { status: item.status },
      },
      output: {
        richText: "This is a thinking step, no direct output here.",
        jsonData: {},
      },
      isAiStep: true,
      taskStatus: undefined,
    }
  }

  // Fallback for older mock data or unhandled types
  const getAiStepDetails = () => {
    // This is a placeholder for more complex logic if needed
    return {
      input: { richText: `Details for: ${item.text}`, jsonData: {} },
      thinking: { richText: "General processing.", jsonData: {} },
      output: { richText: "No specific output.", jsonData: {} },
    }
  }
  const aiDetails = getAiStepDetails()
  return {
    ...aiDetails,
    isAiStep: true,
    taskStatus: undefined,
  }
}

export function StepDetailPane({ step, onClose, className, mockTasksForDetailPane }: StepDetailPaneProps) {
  const { blurIntensity } = useBlur()
  const [internalStep, setInternalStep] = useState<EnhancedStep | null>(step)
  const [isAnimatingOut, setIsAnimatingOut] = useState(false)
  const [details, setDetails] = useState<StepDetailsContent | null>(null)
  const [viewMode, setViewMode] = useState<"richText" | "json">("richText")

  useEffect(() => {
    if (step) {
      setInternalStep(step)
      setDetails(getStepDetailsContent(step, mockTasksForDetailPane))
      setIsAnimatingOut(false)
    } else if (internalStep) {
      setIsAnimatingOut(true)
    }
  }, [step, internalStep, mockTasksForDetailPane])

  const handleAnimationEnd = () => {
    if (isAnimatingOut) {
      setInternalStep(null)
      setDetails(null)
      setIsAnimatingOut(false)
    }
  }

  if (!internalStep && !isAnimatingOut) {
    return null
  }

  const displayStep = internalStep
  const displayDetails = details || getStepDetailsContent(displayStep, mockTasksForDetailPane)

  if (!displayDetails) return null

  const renderContent = (content: SectionContent) => {
    if (viewMode === "json") {
      return (
        <pre className="text-xs text-neutral-700 dark:text-neutral-300 whitespace-pre-wrap break-all p-2.5 bg-black/[.03] dark:bg-white/[.03] rounded-md overflow-x-auto">
          <code>{JSON.stringify(content.jsonData, null, 2)}</code>
        </pre>
      )
    }
    return (
      <div className="text-xs text-neutral-800 dark:text-neutral-200 whitespace-pre-line pl-4">{content.richText}</div>
    )
  }

  // Inside StepDetailPane component, before return:
  let detailPaneTitle = "Details"
  if (displayStep) {
    if (displayStep.type === "tool") {
      detailPaneTitle = displayStep.toolName || "Tool Details"
    } else if (displayStep.text?.startsWith("TASK_DETAIL_")) {
      const taskId = displayStep.text.replace("TASK_DETAIL_", "")
      const task = mockTasksForDetailPane?.find((t) => t.id === taskId)
      if (task) detailPaneTitle = task.name
    } else if (displayStep.text) {
      detailPaneTitle = displayStep.text.length > 50 ? displayStep.text.substring(0, 47) + "..." : displayStep.text
    }
  }

  let statusInfoForPane: StatusDisplayInfo | null = null
  if (displayDetails.taskStatus) {
    statusInfoForPane = getStatusDisplayInfo(displayDetails.taskStatus)
  }

  const renderStatusBar = () => {
    if (statusInfoForPane) {
      const isCompleted = displayDetails.taskStatus === "completed"
      const isFailed = displayDetails.taskStatus === "failed"
      return (
        <div className={cn("flex items-center text-xs font-medium", statusInfoForPane.textColor)}>
          {isCompleted && <CheckCircle2Icon className="h-3.5 w-3.5 mr-1.5" />}
          {isFailed && <AlertTriangleIcon className="h-3.5 w-3.5 mr-1.5" />}
          <span>Status: {statusInfoForPane.text}</span>
        </div>
      )
    } else if (displayDetails.isAiStep) {
      return (
        <div className="flex items-center text-xs font-medium text-apple-green-dark dark:text-apple-green">
          <CheckCircle2Icon className="h-3.5 w-3.5 mr-1.5" />
          <span>Status: Success</span>
        </div>
      )
    }
    return null
  }

  return (
    <div
      onAnimationEnd={handleAnimationEnd}
      className={cn(
        "absolute top-0 left-full ml-4 z-10",
        "w-full max-w-xs h-[450px] rounded-2xl",
        "border border-white/20",
        "bg-white/30 dark:bg-neutral-800/30",
        "shadow-apple-xl flex flex-col",
        step && !isAnimatingOut ? "animate-slide-in-from-right" : "animate-slide-out-to-right",
      )}
      style={{
        // @ts-ignore
        "--tw-backdrop-blur": `blur(${blurIntensity}px)`,
        WebkitBackdropFilter: `blur(${blurIntensity}px)`,
        backdropFilter: `blur(${blurIntensity}px)`,
      }}
    >
      <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-white/30 to-transparent" />
      <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-black/5 to-transparent" />

      <div className="flex items-center justify-between px-3.5 py-3 border-b border-black/5 dark:border-white/5">
        <span title={detailPaneTitle} className="text-sm font-medium text-neutral-800 dark:text-neutral-100 truncate">
          {detailPaneTitle}
        </span>
        <button
          onClick={onClose}
          className="p-1 rounded-md hover:bg-black/5 dark:hover:bg-white/5 text-neutral-500 dark:text-neutral-400 flex-shrink-0"
          aria-label="Close details"
        >
          <XIcon className="h-4 w-4" />
        </button>
      </div>

      <div className="flex-1 p-3 overflow-y-auto space-y-1 [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none]">
        <Accordion type="single" collapsible className="w-full" defaultValue="item-1">
          <AccordionItem value="item-1" className="border-b border-black/5 dark:border-white/5">
            <AccordionTrigger className="text-xs font-medium text-neutral-800 dark:text-neutral-100 hover:no-underline py-2.5">
              {displayDetails.isAiStep ? "Input" : "Task Details"}
            </AccordionTrigger>
            <AccordionContent className="pt-1.5 pb-2.5">{renderContent(displayDetails.input)}</AccordionContent>
          </AccordionItem>
          <AccordionItem value="item-2" className="border-b border-black/5 dark:text-white/5">
            <AccordionTrigger className="text-xs font-medium text-neutral-800 dark:text-neutral-100 hover:no-underline py-2.5">
              {displayDetails.isAiStep ? "Thinking Process" : "Progress & Status"}
            </AccordionTrigger>
            <AccordionContent className="pt-1.5 pb-2.5">{renderContent(displayDetails.thinking)}</AccordionContent>
          </AccordionItem>
          <AccordionItem value="item-3" className="border-b-0">
            <AccordionTrigger className="text-xs font-medium text-neutral-800 dark:text-neutral-100 hover:no-underline py-2.5">
              {displayDetails.isAiStep ? "Output" : "Additional Info"}
            </AccordionTrigger>
            <AccordionContent className="pt-1.5 pb-2.5">{renderContent(displayDetails.output)}</AccordionContent>
          </AccordionItem>
        </Accordion>
      </div>

      <div className="flex items-center justify-between px-3.5 py-2.5 border-t border-black/5 dark:border-white/5">
        {renderStatusBar()}
        <button
          onClick={() => setViewMode(viewMode === "richText" ? "json" : "richText")}
          className="text-xs font-medium text-neutral-600 dark:text-neutral-400 hover:text-neutral-800 dark:hover:text-neutral-200 transition-colors"
        >
          {viewMode === "richText" ? "View JSON" : "View Rich Text"}
        </button>
      </div>
    </div>
  )
}
