import React, { createContext, useContext, useEffect, useState } from 'react'
import AriaGrpcClient from '@/lib/grpc/client'

type GrpcContextType = {
  client: AriaGrpcClient | null
  isConnected: boolean
  isLoading: boolean
  error: string | null
}

const GrpcContext = createContext<GrpcContextType>({
  client: null,
  isConnected: false,
  isLoading: true,
  error: null,
})

export function GrpcProvider({ children }: { children: React.ReactNode }) {
  const [client, setClient] = useState<AriaGrpcClient | null>(null)
  const [isConnected, setIsConnected] = useState(false)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const initializeClient = async () => {
      try {
        setIsLoading(true)
        setError(null)
        
        const grpcClient = AriaGrpcClient.getInstance()
        setClient(grpcClient)
        
        // Check connection
        const connected = await grpcClient.isConnected()
        setIsConnected(connected)
        
        if (!connected) {
          setError('Unable to connect to Aria Runtime. Is the daemon running?')
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to initialize gRPC client')
        setIsConnected(false)
      } finally {
        setIsLoading(false)
      }
    }

    initializeClient()
  }, [])

  return (
    <GrpcContext.Provider value={{ client, isConnected, isLoading, error }}>
      {children}
    </GrpcContext.Provider>
  )
}

export function useGrpc() {
  const context = useContext(GrpcContext)
  if (!context) {
    throw new Error('useGrpc must be used within a GrpcProvider')
  }
  return context
}