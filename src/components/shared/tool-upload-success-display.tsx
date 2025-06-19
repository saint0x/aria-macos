"use client"

import { CheckCircle2Icon } from "lucide-react"
import { cn } from "@/lib/utils"
import { useBlur } from "@/lib/contexts/blur-context" // Import the hook

interface ToolUploadSuccessDisplayProps {
  message: string
  className?: string
  // blurIntensity prop is removed
}

export function ToolUploadSuccessDisplay({ message, className }: ToolUploadSuccessDisplayProps) {
  const { blurIntensity } = useBlur() // Get blur from context

  return (
    <div
      className={cn(
        "w-full max-w-lg rounded-2xl",
        "border border-white/20",
        "bg-white/30 dark:bg-neutral-800/30",
        "shadow-apple-xl",
        "p-3.5",
        "flex items-center",
        "transition-opacity duration-300 animate-expand-in",
        className,
      )}
      style={{
        // @ts-ignore
        "--tw-backdrop-blur": `blur(${blurIntensity}px)`,
        WebkitBackdropFilter: `blur(${blurIntensity}px)`,
        backdropFilter: `blur(${blurIntensity}px)`,
      }}
    >
      <CheckCircle2Icon className="h-4 w-4 mr-2 flex-shrink-0 text-apple-green-dark dark:text-apple-green" />
      <span className="text-sm text-neutral-800 dark:text-neutral-100">{message}</span>
    </div>
  )
}
