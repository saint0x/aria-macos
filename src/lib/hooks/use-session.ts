import { useState, useCallback, useEffect } from 'react'
import { useGrpc } from '@/lib/contexts/grpc-context'
import type { Session } from '@/generated/aria/v1/Session'
import type { TurnOutput } from '@/generated/aria/v1/TurnOutput'

type ChatMessage = {
  id: string
  role: 'user' | 'assistant' | 'system' | 'tool'
  content: string
  timestamp: Date
}

type SessionState = {
  session: Session | null
  messages: ChatMessage[]
  isLoading: boolean
  isStreaming: boolean
  error: string | null
}

export function useSession() {
  const { client, isConnected } = useGrpc()
  const [state, setState] = useState<SessionState>({
    session: null,
    messages: [],
    isLoading: false,
    isStreaming: false,
    error: null,
  })

  // Create a new session
  const createSession = useCallback(async () => {
    if (!client || !isConnected) {
      setState(prev => ({ ...prev, error: 'gRPC client not available' }))
      return null
    }

    setState(prev => ({ ...prev, isLoading: true, error: null }))

    try {
      const sessionClient = client.getSessionClient()
      
      return new Promise<Session>((resolve, reject) => {
        sessionClient.CreateSession({}, (error: any, response: Session) => {
          if (error) {
            setState(prev => ({ 
              ...prev, 
              isLoading: false, 
              error: `Failed to create session: ${error.message}` 
            }))
            reject(error)
          } else {
            setState(prev => ({ 
              ...prev, 
              session: response, 
              isLoading: false,
              messages: [] 
            }))
            resolve(response)
          }
        })
      })
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      setState(prev => ({ ...prev, isLoading: false, error: errorMessage }))
      throw error
    }
  }, [client, isConnected])

  // Execute a turn (send message and stream response)
  const executeTurn = useCallback(async (input: string) => {
    if (!client || !isConnected || !state.session) {
      setState(prev => ({ ...prev, error: 'No active session or gRPC connection' }))
      return
    }

    setState(prev => ({ 
      ...prev, 
      isStreaming: true, 
      error: null,
      // Add user message immediately
      messages: [...prev.messages, {
        id: `user-${Date.now()}`,
        role: 'user' as const,
        content: input,
        timestamp: new Date()
      }]
    }))

    try {
      const sessionClient = client.getSessionClient()
      const stream = sessionClient.ExecuteTurn({
        session_id: state.session.id,
        input
      })

      let assistantMessage = ''
      let currentMessageId = `assistant-${Date.now()}`

      stream.on('data', (turnOutput: TurnOutput) => {
        if (turnOutput.message) {
          // Handle message events
          const roleMap: Record<string, ChatMessage['role']> = {
            'USER': 'user',
            'ASSISTANT': 'assistant',
            'SYSTEM': 'system',
            'TOOL': 'tool'
          }
          
          const message: ChatMessage = {
            id: turnOutput.message.id || `msg-${Date.now()}`,
            role: roleMap[turnOutput.message.role as string] || 'assistant',
            content: turnOutput.message.content || '',
            timestamp: turnOutput.message.createdAt ? new Date((turnOutput.message.createdAt as any).seconds * 1000) : new Date()
          }

          setState(prev => ({
            ...prev,
            messages: [...prev.messages, message]
          }))
        } else if (turnOutput.toolCall) {
          // Handle tool call events
          const toolMessage: ChatMessage = {
            id: `tool-call-${Date.now()}`,
            role: 'tool',
            content: `Tool: ${(turnOutput.toolCall as any).toolName || 'Unknown'}\nParameters: ${(turnOutput.toolCall as any).parametersJson || '{}'}`,
            timestamp: new Date()
          }

          setState(prev => ({
            ...prev,
            messages: [...prev.messages, toolMessage]
          }))
        } else if (turnOutput.toolResult) {
          // Handle tool result events
          const resultMessage: ChatMessage = {
            id: `tool-result-${Date.now()}`,
            role: 'tool',
            content: `Result: ${(turnOutput.toolResult as any).resultJson || 'No result'}${(turnOutput.toolResult as any).success === false ? ` (Error: ${(turnOutput.toolResult as any).errorMessage})` : ''}`,
            timestamp: new Date()
          }

          setState(prev => ({
            ...prev,
            messages: [...prev.messages, resultMessage]
          }))
        } else if (turnOutput.finalResponse) {
          // Handle final response
          const finalMessage: ChatMessage = {
            id: `final-${Date.now()}`,
            role: 'assistant',
            content: turnOutput.finalResponse,
            timestamp: new Date()
          }

          setState(prev => ({
            ...prev,
            messages: [...prev.messages, finalMessage]
          }))
        }
      })

      stream.on('end', () => {
        setState(prev => ({ ...prev, isStreaming: false }))
      })

      stream.on('error', (error: any) => {
        setState(prev => ({ 
          ...prev, 
          isStreaming: false, 
          error: `Stream error: ${error.message}` 
        }))
      })
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      setState(prev => ({ ...prev, isStreaming: false, error: errorMessage }))
    }
  }, [client, isConnected, state.session])

  // Auto-create session on first use
  useEffect(() => {
    if (isConnected && !state.session && !state.isLoading) {
      createSession()
    }
  }, [isConnected, createSession, state.session, state.isLoading])

  return {
    ...state,
    createSession,
    executeTurn,
  }
}