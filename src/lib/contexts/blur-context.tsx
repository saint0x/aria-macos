"use client"

import { createContext, useState, useContext, type ReactNode } from "react"

interface BlurContextType {
  blurIntensity: number
  setBlurIntensity: (value: number) => void
}

// Create the context with a default undefined value
const BlurContext = createContext<BlurContextType | undefined>(undefined)

// Create the provider component
export function BlurProvider({ children }: { children: ReactNode }) {
  // State for blur intensity is managed here, with a default of 16
  const [blurIntensity, setBlurIntensity] = useState(16)

  return <BlurContext.Provider value={{ blurIntensity, setBlurIntensity }}>{children}</BlurContext.Provider>
}

// Create a custom hook for easy access to the context
export function useBlur() {
  const context = useContext(BlurContext)
  if (context === undefined) {
    throw new Error("useBlur must be used within a BlurProvider")
  }
  return context
}
