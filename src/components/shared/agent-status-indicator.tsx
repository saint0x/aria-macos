"use client"

import type React from "react"
import { cn } from "@/lib/utils"
import { CheckIcon, ChevronRightIcon, Loader2, ZapIcon } from "lucide-react"
import type { EnhancedStep } from "@/lib/types"
import type { StepStatus } from "@/lib/types"

interface AgentStatusIndicatorProps {
  steps: EnhancedStep[]
  onStepClick?: (step: EnhancedStep) => void
  itemRefs?: React.MutableRefObject<(HTMLDivElement | null)[]>
  activeHighlightId?: string | null
}

export function AgentStatusIndicator({ steps, onStepClick, itemRefs, activeHighlightId }: AgentStatusIndicatorProps) {
  if (!steps || steps.length === 0) {
    return null
  }

  const getStatusIcon = (status?: StepStatus, type?: EnhancedStep["type"]) => {
    if (status === "completed") return <CheckIcon className="h-4 w-4 text-apple-green-dark/90" />
    if (status === "active")
      return <Loader2 className="h-3.5 w-3.5 text-neutral-800 dark:text-neutral-100 animate-spin" />
    if (status === "failed") return <ZapIcon className="h-3.5 w-3.5 text-red-500 dark:text-red-400" />
    // Pending or default icon based on type
    if (type === "tool") return <ZapIcon className="h-3.5 w-3.5 text-neutral-500/80 dark:text-neutral-400/80" />
    // Default for 'thought' pending
    return <div className="h-2 w-2 rounded-full bg-neutral-500/70 dark:bg-neutral-400/70" />
  }

  return (
    <div role="list" className="space-y-2.5">
      {" "}
      {/* Increased spacing slightly */}
      {steps.map((step, index) => {
        const isHighlighted = activeHighlightId === step.id

        if (step.type === "userMessage") {
          return (
            <div
              key={step.id}
              ref={(el) => itemRefs && (itemRefs.current[index] = el)}
              className={cn(
                "flex justify-end animate-slide-up-fade",
                isHighlighted && "bg-neutral-100/70 dark:bg-neutral-700/50 rounded-lg shadow-apple-inner p-1.5 -m-1.5", // Added highlight styling
              )}
            >
              <div
                className={cn("max-w-[80%] px-3.5 py-2.5 text-sm text-right", "text-neutral-800 dark:text-neutral-100")}
              >
                {step.text}
              </div>
            </div>
          )
        }

        if (step.type === "response") {
          return (
            <div
              key={step.id}
              ref={(el) => itemRefs && (itemRefs.current[index] = el)}
              className={cn(
                "relative flex items-start gap-2.5 group text-sm animate-slide-up-fade", // Base styling, similar to thought
                "px-2 py-1.5 rounded-lg", // Padding and rounding for highlight consistency
                isHighlighted && "bg-neutral-100/70 dark:bg-neutral-700/50 shadow-apple-inner",
              )}
            >
              {/* Icon can be optional for response, or use a subtle one if desired */}
              {/* For now, no explicit icon for response to make it look like plain text unless highlighted */}
              <div
                className={cn(
                  "pt-[1px]", // Align text similar to other steps
                  isHighlighted
                    ? "text-neutral-800 dark:text-neutral-100 font-medium"
                    : "text-neutral-700 dark:text-neutral-300",
                  "group-hover:text-neutral-900 dark:group-hover:text-neutral-100 transition-colors",
                )}
              >
                {step.text}
              </div>
            </div>
          )
        }

        // For 'thought' and 'tool' types
        return (
          <div
            key={step.id}
            ref={(el) => itemRefs && (itemRefs.current[index] = el)}
            className={cn(
              "relative flex items-center justify-between gap-3 group",
              "px-2 py-1.5 rounded-lg",
              step.isIndented && "ml-5",
              isHighlighted && "bg-neutral-100/70 dark:bg-neutral-700/50 shadow-apple-inner",
              onStepClick && (step.type === "tool" || step.type === "thought") && "cursor-pointer",
            )}
            onClick={() => (step.type === "tool" || step.type === "thought") && onStepClick?.(step)}
          >
            {step.isIndented &&
              index > 0 &&
              steps[index - 1]?.type !== "response" &&
              steps[index - 1]?.type !== "userMessage" && (
                <div
                  className="absolute left-[calc(11px_-_1.25rem)] top-[-9px] h-[calc(100%_+_9px)] w-[1px] bg-neutral-400/30 dark:bg-neutral-600/30 group-hover:bg-neutral-500/50 dark:group-hover:bg-neutral-500/50 transition-colors"
                  aria-hidden="true"
                />
              )}

            <div className="flex items-start gap-2.5">
              <div
                className={cn(
                  "relative flex h-6 w-6 flex-shrink-0 items-center justify-center",
                  step.type === "tool" && "transform scale-90",
                )}
                aria-hidden="true"
              >
                {/* No BrainCircuitIcon, just the status icon */}
                {getStatusIcon(step.status, step.type)}
              </div>
              <p
                className={cn(
                  "text-sm pt-[1px]",
                  step.status === "active"
                    ? "text-neutral-800 dark:text-neutral-100 font-medium"
                    : "text-neutral-700 dark:text-neutral-300",
                  step.status === "pending" && "text-neutral-600 dark:text-neutral-400/90",
                  step.type === "tool" && "text-xs",
                  "group-hover:text-neutral-900 dark:group-hover:text-neutral-100 transition-colors",
                )}
              >
                {step.toolName && step.type === "tool" ? `${step.toolName}: ${step.text}` : step.text}
              </p>
            </div>
            {(step.type === "tool" || step.type === "thought") && onStepClick && (
              <ChevronRightIcon
                className={cn(
                  "h-5 w-5 flex-shrink-0 transition-colors",
                  step.status === "active"
                    ? "text-neutral-600 dark:text-neutral-400"
                    : "text-neutral-500/90 dark:text-neutral-500/90",
                  "group-hover:text-neutral-700 dark:group-hover:text-neutral-300",
                )}
              />
            )}
          </div>
        )
      })}
    </div>
  )
}
