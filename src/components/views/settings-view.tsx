"use client"
import { useState, useEffect } from "react"
import type React from "react"
import { useTheme } from "next-themes"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion"
import { Label } from "@/components/ui/label"
import { Button } from "@/components/ui/button"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  SelectGroup,
  SelectLabel,
} from "@/components/ui/select"
import { Slider } from "@/components/ui/slider"
import { UploadCloudIcon, FileTextIcon, Trash2Icon } from "lucide-react" // UsersIcon and WorkflowIcon removed
import { cn } from "@/lib/utils"
import { useBlur } from "@/lib/contexts/blur-context"

interface UtilityItem {
  id: string
  name: string
  description?: string
}

const initialTools: UtilityItem[] = [
  { id: "tool-001", name: "Data Analyzer v3.1" },
  { id: "tool-002", name: "Report Generator X" },
  { id: "tool-003", name: "Content Summarizer" },
]

const initialAgents: UtilityItem[] = [
  { id: "agent-alpha", name: "Support AI - Alpha" },
  { id: "agent-beta", name: "Research Bot - Beta" },
]

const initialTeamMembers: UtilityItem[] = [
  { id: "user-101", name: "Alice Wonderland (Admin)" },
  { id: "user-102", name: "Bob The Builder (Editor)" },
  { id: "user-103", name: "Charlie Chaplin (Viewer)" },
]

const initialPipelines: UtilityItem[] = [
  { id: "pipe-dev", name: "Development Build & Test" },
  { id: "pipe-stage", name: "Staging Deployment" },
  { id: "pipe-prod", name: "Production Release CI/CD" },
]

export function SettingsView() {
  const { blurIntensity, setBlurIntensity } = useBlur()
  const { theme, setTheme } = useTheme()
  const [selectedModel, setSelectedModel] = useState("gpt-4o")
  const [systemPromptFile, setSystemPromptFile] = useState<File | null>(null)
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.files && event.target.files[0]) {
      setSystemPromptFile(event.target.files[0])
    }
  }

  const createDeleteHandler =
    <T extends UtilityItem>(setter: React.Dispatch<React.SetStateAction<T[]>>) =>
    (itemId: string) => {
      setter((prevItems) => prevItems.filter((item) => item.id !== itemId))
    }

  const [tools, setTools] = useState<UtilityItem[]>(initialTools)
  const [agents, setAgents] = useState<UtilityItem[]>(initialAgents)
  const [teamMembers, setTeamMembers] = useState<UtilityItem[]>(initialTeamMembers)
  const [pipelines, setPipelines] = useState<UtilityItem[]>(initialPipelines)

  const handleDeleteTool = createDeleteHandler(setTools)
  const handleDeleteAgent = createDeleteHandler(setAgents)
  const handleDeleteTeamMember = createDeleteHandler(setTeamMembers)
  const handleDeletePipeline = createDeleteHandler(setPipelines)

  const renderUtilityList = (
    items: UtilityItem[],
    onDelete: (id: string) => void,
    emptyMessage: string,
    // IconComponent prop removed
  ) => {
    if (items.length === 0) {
      return <p className="text-xs text-neutral-500 dark:text-neutral-400 py-2">{emptyMessage}</p>
    }
    return (
      <ul className="space-y-1.5">
        {items.map((item) => (
          <li
            key={item.id}
            className="flex items-center justify-between text-xs text-neutral-700 dark:text-neutral-300 py-1.5 px-2 rounded-md hover:bg-black/5 dark:hover:bg-white/5 transition-colors group"
          >
            <div className="flex items-center min-w-0">
              {/* IconComponent rendering removed */}
              <span className="truncate pr-2" title={item.name}>
                {item.name}
              </span>
            </div>
            <Button
              variant="ghost"
              size="icon"
              className="h-6 w-6 opacity-60 group-hover:opacity-100 text-neutral-500 dark:text-neutral-400 hover:text-red-500 dark:hover:text-red-400 flex-shrink-0"
              onClick={() => onDelete(item.id)}
              aria-label={`Delete ${item.name}`}
            >
              <Trash2Icon className="h-3.5 w-3.5" />
            </Button>
          </li>
        ))}
      </ul>
    )
  }

  if (!mounted) {
    return null
  }

  return (
    <div className="p-1 animate-slide-up-fade">
      <Accordion type="multiple" defaultValue={["item-visual-settings"]} className="w-full space-y-1">
        <AccordionItem
          value="item-model-config"
          className="border-none rounded-xl bg-white/20 dark:bg-neutral-700/20 shadow-apple-sm overflow-hidden"
        >
          <AccordionTrigger className="text-sm font-medium text-neutral-800 dark:text-neutral-100 hover:no-underline px-3.5 py-3 data-[state=open]:border-b data-[state=open]:border-black/5 data-[state=open]:dark:border-white/5">
            Model Configuration
          </AccordionTrigger>
          <AccordionContent className="pt-2 pb-3.5 px-3.5 space-y-4">
            <div>
              <Label htmlFor="model-select" className="text-xs text-neutral-700 dark:text-neutral-300 mb-1.5 block">
                Select AI Model
              </Label>
              <Select value={selectedModel} onValueChange={setSelectedModel}>
                <SelectTrigger
                  id="model-select"
                  className="w-full text-xs bg-white/50 dark:bg-neutral-800/50 border-neutral-300/70 dark:border-neutral-600/70"
                >
                  <SelectValue placeholder="Choose a model" />
                </SelectTrigger>
                <SelectContent
                  className={cn(
                    "bg-white/80 dark:bg-neutral-800/80 border-none ring-0 outline-none", // Removed default border, added border-none
                    "dark:border-neutral-600/70", // This was for dark mode, now overridden by border-none
                  )}
                  style={{
                    // @ts-ignore
                    "--tw-backdrop-blur": `blur(${blurIntensity}px)`,
                    WebkitBackdropFilter: `blur(${blurIntensity}px)`,
                    backdropFilter: `blur(${blurIntensity}px)`,
                  }}
                >
                  <SelectGroup>
                    <SelectLabel className="px-2 py-1.5 text-xs font-semibold text-neutral-600 dark:text-neutral-400">
                      OpenAI
                    </SelectLabel>
                    <SelectItem value="gpt-4o" className="text-xs pl-4">
                      GPT-4o (Recommended)
                    </SelectItem>
                    <SelectItem value="gpt-3.5-turbo" className="text-xs pl-4">
                      GPT-3.5 Turbo
                    </SelectItem>
                  </SelectGroup>
                  <SelectGroup>
                    <SelectLabel className="px-2 py-1.5 text-xs font-semibold text-neutral-600 dark:text-neutral-400">
                      Anthropic
                    </SelectLabel>
                    <SelectItem value="claude-3-opus" className="text-xs pl-4">
                      Claude 3 Opus
                    </SelectItem>
                    <SelectItem value="claude-3-sonnet" className="text-xs pl-4">
                      Claude 3 Sonnet
                    </SelectItem>
                    <SelectItem value="claude-3-haiku" className="text-xs pl-4">
                      Claude 3 Haiku
                    </SelectItem>
                  </SelectGroup>
                  <SelectGroup>
                    <SelectLabel className="px-2 py-1.5 text-xs font-semibold text-neutral-600 dark:text-neutral-400">
                      Google
                    </SelectLabel>
                    <SelectItem value="gemini-1.5-pro" className="text-xs pl-4">
                      Gemini 1.5 Pro
                    </SelectItem>
                    <SelectItem value="gemini-1.5-flash" className="text-xs pl-4">
                      Gemini 1.5 Flash
                    </SelectItem>
                  </SelectGroup>
                  <SelectGroup>
                    <SelectLabel className="px-2 py-1.5 text-xs font-semibold text-neutral-600 dark:text-neutral-400">
                      xAI
                    </SelectLabel>
                    <SelectItem value="grok-3" className="text-xs pl-4">
                      Grok 3
                    </SelectItem>
                  </SelectGroup>
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label htmlFor="sysprompt-file" className="text-xs text-neutral-700 dark:text-neutral-300 mb-1.5 block">
                System Prompt File
              </Label>
              <Button
                variant="outline"
                className="w-full text-xs bg-white/50 dark:bg-neutral-800/50 border-neutral-300/70 dark:border-neutral-600/70 hover:bg-white/70 dark:hover:bg-neutral-800/70 text-neutral-700 dark:text-neutral-300 justify-start"
                onClick={() => document.getElementById("sysprompt-file-input")?.click()}
              >
                <UploadCloudIcon className="h-3.5 w-3.5 mr-2" />
                {systemPromptFile ? systemPromptFile.name : "Upload .txt or .md file"}
              </Button>
              <input
                type="file"
                id="sysprompt-file-input"
                className="hidden"
                accept=".txt,.md"
                onChange={handleFileChange}
              />
              {systemPromptFile && (
                <p className="mt-1.5 text-xs text-neutral-600 dark:text-neutral-400 flex items-center">
                  <FileTextIcon className="h-3 w-3 mr-1 flex-shrink-0" />
                  Attached: {systemPromptFile.name} ({(systemPromptFile.size / 1024).toFixed(1)} KB)
                </p>
              )}
            </div>
          </AccordionContent>
        </AccordionItem>

        <AccordionItem
          value="item-utility"
          className="border-none rounded-xl bg-white/20 dark:bg-neutral-700/20 shadow-apple-sm overflow-hidden"
        >
          <AccordionTrigger className="text-sm font-medium text-neutral-800 dark:text-neutral-100 hover:no-underline px-3.5 py-3 data-[state=open]:border-b data-[state=open]:border-black/5 data-[state=open]:dark:border-white/5">
            Utility Management
          </AccordionTrigger>
          <AccordionContent className="pt-2 pb-3.5 px-3.5 space-y-4">
            <div>
              <h4 className="text-xs font-semibold text-neutral-700 dark:text-neutral-200 mb-1.5">Tools</h4>
              {renderUtilityList(tools, handleDeleteTool, "No tools configured.")}
            </div>
            <div>
              <h4 className="text-xs font-semibold text-neutral-700 dark:text-neutral-200 mb-1.5">Agents</h4>
              {renderUtilityList(agents, handleDeleteAgent, "No agents found.")}
            </div>
            <div>
              <h4 className="text-xs font-semibold text-neutral-700 dark:text-neutral-200 mb-1.5">Team</h4>
              {renderUtilityList(teamMembers, handleDeleteTeamMember, "No team members added.")}
            </div>
            <div>
              <h4 className="text-xs font-semibold text-neutral-700 dark:text-neutral-200 mb-1.5">Pipelines</h4>
              {renderUtilityList(pipelines, handleDeletePipeline, "No pipelines configured.")}
            </div>
          </AccordionContent>
        </AccordionItem>

        <AccordionItem
          value="item-visual-settings"
          className="border-none rounded-xl bg-white/20 dark:bg-neutral-700/20 shadow-apple-sm overflow-hidden"
        >
          <AccordionTrigger className="text-sm font-medium text-neutral-800 dark:text-neutral-100 hover:no-underline px-3.5 py-3 data-[state=open]:border-b data-[state=open]:border-black/5 data-[state=open]:dark:border-white/5">
            Visual Settings
          </AccordionTrigger>
          <AccordionContent className="pt-3 pb-3.5 px-3.5 space-y-3">
            <div>
              <div className="flex justify-between items-center mb-1">
                <Label htmlFor="blur-slider" className="text-xs text-neutral-700 dark:text-neutral-300">
                  Backdrop Blur
                </Label>
                <span className="text-xs text-neutral-600 dark:text-neutral-400">{blurIntensity}px</span>
              </div>
              <Slider
                id="blur-slider"
                min={0}
                max={40}
                step={1}
                value={[blurIntensity]}
                onValueChange={(value) => setBlurIntensity(value[0])}
                className={cn(
                  "[&>span:first-child]:h-2 [&>span:first-child]:rounded-full",
                  "[&>span:first-child>span]:h-2 [&>span:first-child>span]:bg-apple-blue [&>span:first-child>span]:rounded-full",
                  "[&_button]:h-2 [&_button]:w-1 [&_button]:bg-transparent [&_button]:opacity-0",
                  "[&_button]:focus-visible:opacity-100 [&_button]:focus-visible:bg-apple-blue/50 [&_button]:focus-visible:ring-2 [&_button]:focus-visible:ring-apple-blue/30 [&_button]:focus-visible:ring-offset-0",
                )}
              />
            </div>
            <div className="flex items-center justify-between pt-1">
              <Label htmlFor="theme-select" className="text-xs text-neutral-700 dark:text-neutral-300">
                Interface Theme
              </Label>
              <Select value={theme} onValueChange={setTheme}>
                <SelectTrigger
                  id="theme-select"
                  className={cn(
                    "w-auto text-xs h-auto p-0 bg-transparent border-none shadow-none",
                    "text-neutral-700 dark:text-neutral-300 hover:text-neutral-900 dark:hover:text-neutral-100",
                    "focus:ring-0 focus:outline-none", // Important for removing focus ring on trigger
                    "data-[placeholder]:text-neutral-700 dark:data-[placeholder]:text-neutral-300",
                  )}
                  aria-label="Select interface theme"
                >
                  <SelectValue placeholder="System" />
                </SelectTrigger>
                <SelectContent
                  className={cn(
                    "bg-white/80 dark:bg-neutral-800/80 border-none ring-0 outline-none min-w-[8rem]", // Removed default border, added border-none
                  )}
                  style={{
                    // @ts-ignore
                    "--tw-backdrop-blur": `blur(${blurIntensity}px)`,
                    WebkitBackdropFilter: `blur(${blurIntensity}px)`,
                    backdropFilter: `blur(${blurIntensity}px)`,
                  }}
                >
                  <SelectItem value="light" className="text-xs">
                    Light
                  </SelectItem>
                  <SelectItem value="dark" className="text-xs">
                    Dark
                  </SelectItem>
                  <SelectItem value="system" className="text-xs">
                    System
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>
          </AccordionContent>
        </AccordionItem>
      </Accordion>
      <p className="text-center text-xs text-neutral-500 dark:text-neutral-400 pt-4">
        Settings are for demonstration and not fully functional.
      </p>
    </div>
  )
}
