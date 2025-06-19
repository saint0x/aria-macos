"use client"

import type React from "react"
import { useState, useEffect, useRef } from "react"
import { cn } from "@/lib/utils"
import { SendIcon, ChevronDownIcon } from "lucide-react"
import { useChat } from "ai/react"
import { motion, AnimatePresence } from "framer-motion"
import { DropdownMenuComponent, type MenuItem } from "./shared/dropdown-menu"
import { AgentStatusIndicator } from "@/components/shared/agent-status-indicator"
import type { EnhancedStep, Task } from "@/lib/types"
import { StepType, StepStatus } from "@/lib/types"
import { StepDetailPane } from "@/components/shared/step-detail-pane"
import { ToolUploadSuccessDisplay } from "@/components/shared/tool-upload-success-display"
import { TaskListView } from "./views/task-list-view"
import { LoggingView } from "./views/logging-view"
import { GraphView } from "./views/graph-view"
import { BillingView } from "./views/billing-view"
import { SettingsView } from "./views/settings-view"
import { gentleTransition, slideUpFadeVariants, mainChatbarContainerVariants } from "@/lib/animations"
import { useBlur } from "@/lib/contexts/blur-context"
import { useTasks } from "@/lib/hooks/use-tasks"

const initialAiSteps: EnhancedStep[] = []

interface GlassmorphicChatbarProps {
  isOpen?: boolean
  onClose?: () => void
  placeholder?: string
  className?: string
  initialValue?: string
}

export function GlassmorphicChatbar({
  isOpen = true,
  onClose,
  placeholder: initialPlaceholder = "Ask me anything...",
  className,
  initialValue = "",
}: GlassmorphicChatbarProps) {
  const { blurIntensity } = useBlur()
  const [open, setOpen] = useState(isOpen)
  const [mounted, setMounted] = useState(false)
  const [expanded, setExpanded] = useState(false)
  const [inputValue, setInputValue] = useState(initialValue)
  const [isToolMenuOpen, setIsToolMenuOpen] = useState(false)
  const [isViewMenuOpen, setIsViewMenuOpen] = useState(false)
  const [aiSteps, setAiSteps] = useState<EnhancedStep[]>(initialAiSteps)
  const [isProcessing, setIsProcessing] = useState(false)
  const [processingComplete, setProcessingComplete] = useState(false)
  const [selectedItemForDetail, setSelectedItemForDetail] = useState<EnhancedStep | null>(null)
  const [showAiChatFlow, setShowAiChatFlow] = useState(false)
  const [activeHighlightId, setActiveHighlightId] = useState<string | null>(null)

  const { data: tasksData } = useTasks()
  const tasks = tasksData?.tasks ?? []

  const toolMenuItems: MenuItem[] = [
    { id: "analyzerTool", name: "Analyzer Tool" },
    { id: "devConsoleTool", name: "Developer Console" },
    { id: "dataVizTool", name: "Data Visualizer" },
    { id: "apiExplorerTool", name: "API Explorer" },
    { id: "workflowTool", name: "Workflow Automator" },
    { id: "contentGenTool", name: "Content Generator" },
    { id: "securityScanTool", name: "Security Scanner" },
    { id: "collabHubTool", name: "Collaboration Hub" },
  ]
  const [activeTool, setActiveTool] = useState<MenuItem | null>(null)

  const viewMenuItems: MenuItem[] = [
    { id: "taskListView", name: "Task View" },
    { id: "loggingView", name: "Logging" },
    { id: "graphView", name: "Graph View", disabled: true },
    { id: "billingView", name: "Billing", separator: "before" },
    { id: "settingsView", name: "Settings" },
  ]
  const [activeView, setActiveView] = useState<MenuItem>(
    viewMenuItems.find((item) => item.id === "taskListView") || viewMenuItems[0],
  )

  const inputRef = useRef<HTMLInputElement>(null)
  const chatContainerRef = useRef<HTMLDivElement>(null)
  const toolButtonRef = useRef<HTMLButtonElement>(null)
  const viewButtonRef = useRef<HTMLButtonElement>(null)
  const mainChatbarRef = useRef<HTMLDivElement>(null)
  const stepItemRefs = useRef<(HTMLDivElement | null)[]>([])

  const { handleSubmit: originalHandleSubmit } = useChat({
    api: "/api/chat",
    onFinish: () => {
      if (isProcessing) {
        setIsProcessing(false)
        setProcessingComplete(true)
      }
    },
    onError: () => {
      if (isProcessing) {
        setIsProcessing(false)
        setProcessingComplete(true)
      }
    },
  })

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    if (inputValue.trim() && !isProcessing) {
      setExpanded(true)
      setShowAiChatFlow(true)

      const userMessageContent = inputValue

      const newUserMessageStep: EnhancedStep = {
        id: `user-${Date.now()}`,
        type: StepType.USER_MESSAGE,
        text: userMessageContent,
        timestamp: new Date().toISOString(),
      }

      setAiSteps((prevSteps) => [...prevSteps, newUserMessageStep])
      setActiveHighlightId(newUserMessageStep.id)
      setInputValue("")

      setTimeout(() => {
        setIsProcessing(true)
        setProcessingComplete(false)

        const synthesizingThought: EnhancedStep = {
          id: `thought-synthesizing-${Date.now()}`,
          type: StepType.THOUGHT,
          text: "Synthesizing response...",
          status: StepStatus.ACTIVE,
          timestamp: new Date().toISOString(),
        }
        setAiSteps((prevSteps) => [...prevSteps, synthesizingThought])
        setActiveHighlightId(synthesizingThought.id)

        setTimeout(() => {
          const tool1: EnhancedStep = {
            id: `tool-1-${Date.now()}`,
            type: StepType.TOOL,
            text: "Querying knowledge base...",
            toolName: "KnowledgeRetriever",
            status: StepStatus.ACTIVE,
            isIndented: true,
            timestamp: new Date().toISOString(),
          }
          setAiSteps((prevSteps) => [...prevSteps, tool1])

          setTimeout(() => {
            setAiSteps((prevSteps) =>
              prevSteps.map((s) => (s.id === tool1.id ? { ...s, status: StepStatus.COMPLETED } : s)),
            )

            const tool2: EnhancedStep = {
              id: `tool-2-${Date.now()}`,
              type: StepType.TOOL,
              text: "Analyzing patterns...",
              toolName: "PatternAnalyzer",
              status: StepStatus.ACTIVE,
              isIndented: true,
              timestamp: new Date().toISOString(),
            }
            setAiSteps((prevSteps) => [...prevSteps, tool2])

            setTimeout(async () => {
              setAiSteps((prevSteps) =>
                prevSteps.map((s) => (s.id === tool2.id ? { ...s, status: StepStatus.COMPLETED } : s)),
              )
              setAiSteps((prevSteps) =>
                prevSteps.map((s) => (s.id === synthesizingThought.id ? { ...s, status: StepStatus.COMPLETED } : s)),
              )

              const aiResponseStep: EnhancedStep = {
                id: `response-${Date.now()}`,
                type: StepType.RESPONSE,
                text: "Based on my analysis, here's the simulated finding: The data indicates a strong correlation.",
                status: StepStatus.COMPLETED,
                timestamp: new Date().toISOString(),
              }
              setAiSteps((prevSteps) => [...prevSteps, aiResponseStep])
              setActiveHighlightId(aiResponseStep.id)

              setIsProcessing(false)
              setProcessingComplete(true)
              // TODO: In a real scenario, you might call the actual API here
              // originalHandleSubmit(e, { data: { message: userMessageContent } });
            }, 1200)
          }, 1200)
        }, 800)
      }, 100)
    }
  }

  const handleNewTask = () => {
    setAiSteps(initialAiSteps)
    setInputValue("")
    setActiveHighlightId(null)
    setShowAiChatFlow(true)
    setExpanded(true)
    setSelectedItemForDetail(null)
    setActiveTool(null)
    inputRef.current?.focus()
  }

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        if (selectedItemForDetail) setSelectedItemForDetail(null)
        else if (isToolMenuOpen) setIsToolMenuOpen(false)
        else if (isViewMenuOpen) setIsViewMenuOpen(false)
        else if (expanded) {
          // Behavior: Keep expanded on ESC
        } else {
          setOpen(false)
          onClose?.()
        }
      }
    }
    document.addEventListener("keydown", handleKeyDown)
    return () => document.removeEventListener("keydown", handleKeyDown)
  }, [expanded, selectedItemForDetail, isToolMenuOpen, isViewMenuOpen, onClose])

  useEffect(() => {
    if (isOpen) {
      setOpen(true)
      if (inputRef.current && mounted) {
        setTimeout(() => inputRef.current?.focus(), 100)
      }
    } else {
      setOpen(false)
    }
  }, [isOpen, mounted])

  useEffect(() => {
    setMounted(true)
  }, [])

  useEffect(() => {
    setInputValue(initialValue)
  }, [initialValue])

  useEffect(() => {
    if (showAiChatFlow && chatContainerRef.current) {
      const element = chatContainerRef.current
      setTimeout(() => {
        element.scrollTo({
          top: element.scrollHeight,
          behavior: "smooth",
        })
      }, 100)
    }
  }, [aiSteps, showAiChatFlow])

  const handleToolSelect = (selectedTool: MenuItem) => {
    setActiveTool(activeTool?.id === selectedTool.id ? null : selectedTool)
    setIsToolMenuOpen(false)
    inputRef.current?.focus()
  }

  const handleViewSelect = (view: MenuItem) => {
    if (view.disabled) return
    setActiveView(view)
    setShowAiChatFlow(false)
    setExpanded(true)
    setSelectedItemForDetail(null)
    setIsViewMenuOpen(false)
    inputRef.current?.focus()
  }

  const handleTaskSelectForDetail = (task: Task) => {
    setSelectedItemForDetail({
      id: task.id,
      type: StepType.THOUGHT,
      text: task.detailIdentifier,
      status: StepStatus.ACTIVE,
    })
  }

  const handleAiStepSelectForDetail = (step: EnhancedStep) => {
    if (step.type === StepType.TOOL || step.type === StepType.THOUGHT || step.type === StepType.RESPONSE) {
      setSelectedItemForDetail(step)
    }
  }

  const currentPlaceholder = activeTool ? `Using ${activeTool.name}...` : "Type your message..."

  return (
    <AnimatePresence>
      {open && (
        <div
          className={cn(
            "fixed inset-0 z-50 flex flex-col items-center justify-center p-4 sm:p-6",
            className,
            open && mounted ? "opacity-100" : "opacity-0 pointer-events-none",
          )}
          onClick={(e) => {
            if (e.target === e.currentTarget && !expanded && !selectedItemForDetail) {
              setOpen(false)
              onClose?.()
            }
          }}
        >
          <div className="relative w-full max-w-lg">
            <motion.div
              key="chatbar-main"
              ref={mainChatbarRef}
              layout
              className={cn(
                "relative w-full rounded-2xl",
                "border border-white/20",
                "bg-white/30 dark:bg-neutral-800/30",
                "shadow-apple-xl",
                "flex flex-col overflow-hidden",
              )}
              style={{
                height: expanded ? "450px" : "auto",
                // @ts-ignore
                "--tw-backdrop-blur": `blur(${blurIntensity}px)`,
                WebkitBackdropFilter: `blur(${blurIntensity}px)`,
                backdropFilter: `blur(${blurIntensity}px)`,
              }}
              variants={mainChatbarContainerVariants}
              initial="initial"
              animate="animate"
              exit="exit"
              transition={gentleTransition}
            >
              <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-white/30 to-transparent" />
              <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-black/5 to-transparent" />

              <div className="px-3.5 pt-3.5 pb-2.5 relative z-10">
                <div
                  className={cn(
                    "flex items-center w-full rounded-xl px-3 py-2.5",
                    "bg-white/20 dark:bg-neutral-700/20 shadow-apple-inner",
                  )}
                >
                  <form onSubmit={handleSubmit} className="flex-1">
                    <input
                      ref={inputRef}
                      type="text"
                      placeholder={currentPlaceholder}
                      value={inputValue}
                      onChange={(e) => setInputValue(e.target.value)}
                      className={cn(
                        "w-full bg-transparent text-sm text-neutral-800 dark:text-neutral-100 placeholder:text-neutral-600 dark:placeholder:text-neutral-400/80 outline-none",
                      )}
                      disabled={isProcessing}
                    />
                  </form>
                  {inputValue && !isProcessing && (
                    <button
                      type="submit"
                      onClick={(e) => {
                        e.preventDefault()
                        handleSubmit(e as any)
                      }}
                      className="ml-2 p-1 rounded-md hover:bg-black/10 dark:hover:bg-white/10 text-neutral-700 dark:text-neutral-300 flex-shrink-0"
                      aria-label="Send message"
                    >
                      <SendIcon className="h-4 w-4" />
                    </button>
                  )}
                </div>
              </div>

              <AnimatePresence initial={false}>
                {expanded && (
                  <motion.div
                    key="expanded-content"
                    ref={chatContainerRef}
                    className="flex-1 overflow-y-auto px-3.5 pt-1 pb-3 relative z-10 [&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none]"
                    variants={slideUpFadeVariants}
                    initial="initial"
                    animate="animate"
                    exit="exit"
                  >
                    {showAiChatFlow ? (
                      <div className="mb-3">
                        <AgentStatusIndicator
                          steps={aiSteps}
                          onStepClick={handleAiStepSelectForDetail}
                          itemRefs={stepItemRefs}
                          activeHighlightId={activeHighlightId}
                        />
                      </div>
                    ) : (
                      <>
                        {activeView.id === "taskListView" && <TaskListView onTaskSelect={handleTaskSelectForDetail} />}
                        {activeView.id === "loggingView" && <LoggingView />}
                        {activeView.id === "graphView" && <GraphView />}
                        {activeView.id === "billingView" && <BillingView />}
                        {activeView.id === "settingsView" && <SettingsView />}
                      </>
                    )}
                  </motion.div>
                )}
              </AnimatePresence>

              <div
                className={cn(
                  "flex items-center justify-between border-t border-black/10 dark:border-white/10 px-3 py-2 mt-auto relative z-10",
                )}
              >
                <button
                  ref={toolButtonRef}
                  className={cn(
                    "flex items-center gap-1.5 rounded-md px-2 py-1 text-xs transition-colors",
                    "text-neutral-800 dark:text-neutral-200 hover:bg-black/5 dark:hover:bg-white/5 hover:text-neutral-900 dark:hover:text-neutral-100",
                    isToolMenuOpen && "bg-black/5 dark:bg-white/5 text-neutral-900 dark:text-neutral-100",
                  )}
                  onClick={() => setIsToolMenuOpen(!isToolMenuOpen)}
                >
                  <span>{activeTool ? activeTool.name : "Tools"}</span>
                  <ChevronDownIcon className="h-3.5 w-3.5 text-neutral-600 dark:text-neutral-400" />
                </button>

                <button
                  onClick={handleNewTask}
                  className={cn(
                    "rounded-md px-2.5 py-1 text-xs font-medium transition-all duration-150 ease-out",
                    "text-neutral-700 dark:text-neutral-300",
                    "hover:text-neutral-900 dark:hover:text-neutral-100 hover:bg-black/5 dark:hover:bg-white/10",
                    "focus-visible:ring-2 focus-visible:ring-apple-blue/50 focus-visible:outline-none",
                  )}
                  aria-label="Start a new task"
                >
                  New Task
                </button>

                <button
                  ref={viewButtonRef}
                  onClick={() => {
                    if (showAiChatFlow) {
                      setActiveView(viewMenuItems.find((item) => item.id === "taskListView") || viewMenuItems[0])
                      setShowAiChatFlow(false)
                    } else {
                      setIsViewMenuOpen(!isViewMenuOpen)
                    }
                  }}
                  className={cn(
                    "flex items-center gap-1.5 rounded-md pl-2 pr-1 py-1 text-xs transition-colors",
                    "text-neutral-800 dark:text-neutral-200 hover:bg-black/5 dark:hover:bg-white/5 hover:text-neutral-900 dark:hover:text-neutral-100",
                    isViewMenuOpen && "bg-black/5 dark:bg-white/5 text-neutral-900 dark:text-neutral-100",
                  )}
                  aria-label="Select View"
                >
                  <span>
                    {showAiChatFlow
                      ? "Task View"
                      : activeView.name.length > 10
                        ? activeView.name.substring(0, 7) + "..."
                        : activeView.name}
                  </span>
                  <ChevronDownIcon className="h-3.5 w-3.5 text-neutral-600 dark:text-neutral-400" />
                </button>
              </div>
            </motion.div>

            <AnimatePresence>
              {selectedItemForDetail && (
                <StepDetailPane
                  step={selectedItemForDetail}
                  onClose={() => setSelectedItemForDetail(null)}
                  mockTasksForDetailPane={tasks}
                />
              )}
            </AnimatePresence>

            <DropdownMenuComponent
              isOpen={isToolMenuOpen}
              anchorRef={toolButtonRef}
              containerRef={mainChatbarRef}
              items={toolMenuItems}
              onSelectItem={handleToolSelect}
              onClose={() => setIsToolMenuOpen(false)}
              menuWidth={180}
              align="containerLeft"
            />
            <DropdownMenuComponent
              isOpen={isViewMenuOpen}
              anchorRef={viewButtonRef}
              containerRef={mainChatbarRef}
              items={viewMenuItems}
              onSelectItem={handleViewSelect}
              onClose={() => setIsViewMenuOpen(false)}
              menuWidth={180}
              align="containerRight"
            />
          </div>

          {!expanded && mounted && (
            <div className="mt-4 w-full max-w-lg">
              <ToolUploadSuccessDisplay message="Custom tool uploaded successfully!" />
            </div>
          )}
        </div>
      )}
    </AnimatePresence>
  )
}
