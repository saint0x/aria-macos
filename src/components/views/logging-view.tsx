"use client"

import type React from "react"
import { useState, useRef } from "react"
import { cn } from "@/lib/utils"
import type { LogEntry } from "@/lib/types"
import { LogLevel } from "@/lib/types"
import {
  format,
  parseISO,
  isValid,
  startOfDay,
  endOfDay,
  subHours,
  subDays as dateFnsSubDays,
  startOfWeek,
} from "date-fns"
import { ChevronDownIcon, Loader2 } from "lucide-react"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip"
import { DropdownMenuComponent, type MenuItem } from "@/components/shared/dropdown-menu"
import type { DateRange } from "react-day-picker"
import { useLogs } from "@/lib/hooks/use-logs"

const formatLogLevel = (level: LogEntry["level"]): string => {
  if (!level) return "Unknown"
  return level.charAt(0).toUpperCase() + level.slice(1).toLowerCase()
}

const LogEntryRow: React.FC<{ entry: LogEntry }> = ({ entry }) => {
  const [isExpanded, setIsExpanded] = useState(false)
  const timestamp = parseISO(entry.timestamp)
  const fullTimestampString = isValid(timestamp) ? format(timestamp, "MMM d, yyyy, HH:mm:ss.SSS") : "Invalid Date"
  const condensedTimestampString = isValid(timestamp) ? format(timestamp, "MMM d") : "Invalid"

  return (
    <div className="border-b border-black/5 dark:border-white/5 last:border-b-0">
      <div
        className="flex items-center text-xs p-2.5 hover:bg-black/5 dark:hover:bg-white/5 transition-colors cursor-pointer"
        onClick={() => entry.details && setIsExpanded(!isExpanded)}
      >
        <Tooltip>
          <TooltipTrigger asChild>
            <div className="w-20 pr-2 flex-shrink-0 tabular-nums text-neutral-600 dark:text-neutral-400 cursor-default">
              {condensedTimestampString}
            </div>
          </TooltipTrigger>
          <TooltipContent
            side="top"
            align="center"
            className="text-xs bg-neutral-900/90 dark:bg-neutral-800/90 text-white dark:text-neutral-100 border-neutral-700/50 dark:border-neutral-700/50 shadow-lg backdrop-blur-sm rounded-md px-2 py-1"
          >
            <p>{fullTimestampString}</p>
          </TooltipContent>
        </Tooltip>

        <div className="w-16 pr-2 flex-shrink-0">
          <span
            className={cn("text-[11px] font-medium", {
              "text-blue-600 dark:text-blue-400": entry.level === LogLevel.INFO,
              "text-green-600 dark:text-green-400": entry.level === LogLevel.SUCCESS,
              "text-yellow-600 dark:text-yellow-400": entry.level === LogLevel.WARN,
              "text-red-600 dark:text-red-400": entry.level === LogLevel.ERROR,
              "text-purple-600 dark:text-purple-400": entry.level === LogLevel.DEBUG,
              "text-neutral-500 dark:text-neutral-400": !entry.level,
            })}
          >
            {formatLogLevel(entry.level)}
          </span>
        </div>
        <div className="w-48 pr-2 flex-shrink-0 truncate text-neutral-700 dark:text-neutral-300" title={entry.source}>
          {entry.source}
        </div>
        <div className="flex-1 pr-2 min-w-0">
          <p className="truncate text-neutral-800 dark:text-neutral-200" title={entry.message}>
            {entry.message}
          </p>
          {entry.entityName && (
            <p className="text-xs text-neutral-500 dark:text-neutral-400 truncate" title={entry.entityName}>
              Entity: {entry.entityName}
            </p>
          )}
        </div>
        {entry.details && (
          <ChevronDownIcon
            className={cn("h-4 w-4 text-neutral-500 transition-transform flex-shrink-0", isExpanded && "rotate-180")}
          />
        )}
      </div>
      {isExpanded && entry.details && (
        <div className="p-3 pl-10 bg-black/[.02] dark:bg-white/[.02] text-xs text-neutral-700 dark:text-neutral-300">
          <pre className="whitespace-pre-wrap break-all">{JSON.stringify(entry.details, null, 2)}</pre>
        </div>
      )}
    </div>
  )
}

const getDefaultDateRange = (): DateRange => ({
  from: startOfDay(dateFnsSubDays(new Date(), 6)),
  to: endOfDay(new Date()),
})

export function LoggingView() {
  const [dateRange, setDateRange] = useState<DateRange | undefined>(getDefaultDateRange())
  const [activeTimeframeLabel, setActiveTimeframeLabel] = useState<string>("7d")
  const [isTimeframeDropdownOpen, setIsTimeframeDropdownOpen] = useState(false)
  const timeframeButtonRef = useRef<HTMLButtonElement>(null)
  const loggingViewContainerRef = useRef<HTMLDivElement>(null)

  const { data, isLoading, isError, error } = useLogs(dateRange)
  const filteredLogs = data?.logs ?? []

  const timeframeItems: MenuItem[] = [
    { id: "24h", name: "Last 24 hours" },
    { id: "1d", name: "Today" },
    { id: "7d", name: "Last 7 days" },
    { id: "1w", name: "This week" },
  ]

  const handleTimeframeSelect = (selectedItem: MenuItem) => {
    let newRange: DateRange | undefined
    const now = new Date()
    switch (selectedItem.id) {
      case "24h":
        newRange = { from: subHours(now, 24), to: now }
        break
      case "1d":
        newRange = { from: startOfDay(now), to: endOfDay(now) }
        break
      case "7d":
        newRange = { from: startOfDay(dateFnsSubDays(now, 6)), to: endOfDay(now) }
        break
      case "1w":
        newRange = { from: startOfWeek(now, { weekStartsOn: 1 }), to: endOfDay(now) }
        break
      default:
        newRange = getDefaultDateRange()
    }
    setDateRange(newRange)
    setActiveTimeframeLabel(selectedItem.id)
    setIsTimeframeDropdownOpen(false)
  }

  const renderContent = () => {
    if (isLoading) {
      return (
        <div className="flex items-center justify-center p-8 text-sm text-neutral-600 dark:text-neutral-400">
          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
          Loading logs...
        </div>
      )
    }
    if (isError) {
      return (
        <p className="p-4 text-center text-sm text-red-600 dark:text-red-400">Error loading logs: {error.message}</p>
      )
    }
    if (filteredLogs.length === 0) {
      return (
        <p className="p-4 text-center text-sm text-neutral-600 dark:text-neutral-400">
          No logs found for the selected period.
        </p>
      )
    }
    return filteredLogs.map((entry) => <LogEntryRow key={entry.id} entry={entry} />)
  }

  return (
    <TooltipProvider delayDuration={300}>
      <div ref={loggingViewContainerRef} className="h-full flex flex-col animate-slide-up-fade p-1 space-y-2">
        <div className="flex items-center justify-between px-2.5 py-1.5">
          <h3 className="text-sm font-medium text-neutral-800 dark:text-neutral-100">Activity Logs</h3>
          <div className="relative">
            <button
              ref={timeframeButtonRef}
              onClick={() => setIsTimeframeDropdownOpen(!isTimeframeDropdownOpen)}
              className={cn(
                "flex items-center gap-1.5 rounded-md px-2.5 py-1 text-xs transition-colors",
                "text-neutral-700 dark:text-neutral-300 hover:bg-black/5 dark:hover:bg-white/10 hover:text-neutral-800 dark:hover:text-neutral-200",
                isTimeframeDropdownOpen && "bg-black/5 dark:bg-white/5 text-neutral-800 dark:text-neutral-200",
              )}
            >
              <span>{activeTimeframeLabel}</span>
              <ChevronDownIcon className="h-3.5 w-3.5 text-neutral-500 dark:text-neutral-500" />
            </button>
            <DropdownMenuComponent
              isOpen={isTimeframeDropdownOpen}
              anchorRef={timeframeButtonRef}
              containerRef={loggingViewContainerRef}
              items={timeframeItems}
              onSelectItem={handleTimeframeSelect}
              onClose={() => setIsTimeframeDropdownOpen(false)}
              menuWidth={160}
              align="containerRight"
            />
          </div>
        </div>

        <div className="flex-1 rounded-xl bg-white/20 dark:bg-neutral-700/20 shadow-apple-sm overflow-hidden">
          <div className="h-full w-full overflow-auto [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none]">
            <div className="min-w-[750px]">
              <div className="sticky top-0 z-10 flex items-center text-xs font-medium text-neutral-600 dark:text-neutral-400 p-2.5 border-b border-black/5 dark:border-white/5 bg-white/60 dark:bg-neutral-800/60 backdrop-blur-sm">
                <div className="w-20 pr-2 flex-shrink-0">Timestamp</div>
                <div className="w-16 pr-2 flex-shrink-0">Level</div>
                <div className="w-48 pr-2 flex-shrink-0">Source</div>
                <div className="flex-1 pr-2 min-w-0">Message</div>
                <div className="w-4 flex-shrink-0"></div>
              </div>
              {renderContent()}
            </div>
          </div>
        </div>
      </div>
    </TooltipProvider>
  )
}
