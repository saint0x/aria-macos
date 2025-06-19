import { useState, useCallback, useEffect } from 'react'
import { invoke } from '@tauri-apps/api/core'

type ChatMessage = {
  id: string
  role: 'user' | 'assistant' | 'system' | 'tool'
  content: string
  timestamp: string
}

type SessionResponse = {
  id: string
  created_at: string
}

type ExecuteTurnResponse = {
  messages: ChatMessage[]
}

type SessionState = {
  session: SessionResponse | null
  messages: ChatMessage[]
  isLoading: boolean
  isStreaming: boolean
  error: string | null
}

export function useTauriSession() {
  const [state, setState] = useState<SessionState>({
    session: null,
    messages: [],
    isLoading: false,
    isStreaming: false,
    error: null,
  })

  // Create a new session
  const createSession = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true, error: null }))

    try {
      const session = await invoke<SessionResponse>('create_session')
      setState(prev => ({ 
        ...prev, 
        session, 
        isLoading: false,
        messages: [] 
      }))
      return session
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      setState(prev => ({ ...prev, isLoading: false, error: errorMessage }))
      throw error
    }
  }, [])

  // Execute a turn (send message and get response)
  const executeTurn = useCallback(async (input: string) => {
    if (!state.session) {
      setState(prev => ({ ...prev, error: 'No active session' }))
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
        timestamp: new Date().toISOString()
      }]
    }))

    try {
      const response = await invoke<ExecuteTurnResponse>('execute_turn', {
        sessionId: state.session.id,
        input
      })

      setState(prev => ({
        ...prev,
        isStreaming: false,
        messages: [...prev.messages, ...response.messages]
      }))
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      setState(prev => ({ ...prev, isStreaming: false, error: errorMessage }))
    }
  }, [state.session])

  // Health check
  const healthCheck = useCallback(async () => {
    try {
      const result = await invoke<string>('health_check')
      console.log('Health check:', result)
      return result
    } catch (error) {
      console.error('Health check failed:', error)
      throw error
    }
  }, [])

  // Auto-create session on mount
  useEffect(() => {
    if (!state.session && !state.isLoading) {
      createSession()
    }
  }, [createSession, state.session, state.isLoading])

  return {
    ...state,
    createSession,
    executeTurn,
    healthCheck,
  }
}