import type { EnhancedStep } from '@/lib/types'
import { StepType, StepStatus } from '@/lib/types'

export type MessageFlowConfig = {
  onStepAdded?: (step: EnhancedStep) => void
  onStepUpdated?: (stepId: string, updates: Partial<EnhancedStep>) => void
  onHighlightChanged?: (stepId: string | null) => void
}

export class MessageFlowManager {
  private steps: EnhancedStep[] = []
  private activeHighlightId: string | null = null
  private config: MessageFlowConfig

  constructor(config: MessageFlowConfig = {}) {
    this.config = config
  }

  // Add a user message step
  addUserMessage(content: string): EnhancedStep {
    const userStep: EnhancedStep = {
      id: `user-${Date.now()}`,
      type: StepType.USER_MESSAGE,
      text: content,
      timestamp: new Date().toISOString(),
    }

    this.steps.push(userStep)
    this.setHighlight(userStep.id)
    this.config.onStepAdded?.(userStep)
    
    return userStep
  }

  // Add an assistant message step and highlight it
  addAssistantMessage(content: string): EnhancedStep {
    const assistantStep: EnhancedStep = {
      id: `assistant-${Date.now()}`,
      type: StepType.RESPONSE,
      text: content,
      status: StepStatus.COMPLETED,
      timestamp: new Date().toISOString(),
    }

    this.steps.push(assistantStep)
    this.setHighlight(assistantStep.id) // Key: highlight main messages, not tool substeps
    this.config.onStepAdded?.(assistantStep)
    
    return assistantStep
  }

  // Add a thinking/processing step and highlight it
  addThinkingStep(content: string = "Processing..."): EnhancedStep {
    const thinkingStep: EnhancedStep = {
      id: `thought-${Date.now()}`,
      type: StepType.THOUGHT,
      text: content,
      status: StepStatus.ACTIVE,
      timestamp: new Date().toISOString(),
    }

    this.steps.push(thinkingStep)
    this.setHighlight(thinkingStep.id) // Highlight main thinking steps
    this.config.onStepAdded?.(thinkingStep)
    
    return thinkingStep
  }

  // Add a tool call step (these are NOT highlighted - they're substeps)
  addToolCall(toolName: string, description: string): EnhancedStep {
    const toolStep: EnhancedStep = {
      id: `tool-${Date.now()}`,
      type: StepType.TOOL,
      text: description,
      toolName,
      status: StepStatus.ACTIVE,
      isIndented: true, // Key: tool calls are indented substeps
      timestamp: new Date().toISOString(),
    }

    this.steps.push(toolStep)
    // Note: Tool calls are NOT highlighted - they're substeps
    this.config.onStepAdded?.(toolStep)
    
    return toolStep
  }

  // Update a step's status/content
  updateStep(stepId: string, updates: Partial<EnhancedStep>): void {
    const stepIndex = this.steps.findIndex(s => s.id === stepId)
    if (stepIndex >= 0) {
      this.steps[stepIndex] = { ...this.steps[stepIndex], ...updates }
      this.config.onStepUpdated?.(stepId, updates)
    }
  }

  // Set the currently highlighted step (only main steps, not tool substeps)
  setHighlight(stepId: string | null): void {
    this.activeHighlightId = stepId
    this.config.onHighlightChanged?.(stepId)
  }

  // Clear highlighting
  clearHighlight(): void {
    this.setHighlight(null)
  }

  // Complete a step and move highlight to next main step if applicable
  completeStep(stepId: string): void {
    this.updateStep(stepId, { status: StepStatus.COMPLETED })
    
    // If this was the highlighted step, find the next main step to highlight
    if (this.activeHighlightId === stepId) {
      const currentIndex = this.steps.findIndex(s => s.id === stepId)
      const nextMainStep = this.findNextMainStep(currentIndex)
      
      if (nextMainStep) {
        this.setHighlight(nextMainStep.id)
      }
    }
  }

  // Find the next main step (non-indented, non-tool) after the given index
  private findNextMainStep(fromIndex: number): EnhancedStep | null {
    for (let i = fromIndex + 1; i < this.steps.length; i++) {
      const step = this.steps[i]
      // Main steps are: USER_MESSAGE, THOUGHT, RESPONSE (but not indented tools)
      if (!step.isIndented && 
          (step.type === StepType.USER_MESSAGE || 
           step.type === StepType.THOUGHT || 
           step.type === StepType.RESPONSE)) {
        return step
      }
    }
    return null
  }

  // Reset the entire flow
  reset(): void {
    this.steps = []
    this.activeHighlightId = null
    this.config.onHighlightChanged?.(null)
  }

  // Get current state
  getSteps(): EnhancedStep[] {
    return [...this.steps]
  }

  getActiveHighlightId(): string | null {
    return this.activeHighlightId
  }

  // Convert gRPC messages to enhanced steps
  convertGrpcMessagesToSteps(messages: Array<{
    id: string
    role: 'user' | 'assistant' | 'system' | 'tool'
    content: string
    timestamp: Date
  }>): EnhancedStep[] {
    return messages.map(msg => ({
      id: msg.id,
      type: msg.role === 'user' ? StepType.USER_MESSAGE : 
            msg.role === 'tool' ? StepType.TOOL : 
            StepType.RESPONSE,
      text: msg.content,
      status: StepStatus.COMPLETED,
      timestamp: msg.timestamp.toISOString(),
      isIndented: msg.role === 'tool', // Tool messages are indented
      toolName: msg.role === 'tool' ? 'Tool' : undefined,
    }))
  }
}

// Hook for using the message flow manager
export function useMessageFlow(config: MessageFlowConfig = {}) {
  const manager = new MessageFlowManager(config)
  return manager
}