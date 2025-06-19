"use client"

import type { ReactNode } from "react"
import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { ReactQueryDevtools } from "@tanstack/react-query-devtools"
import { ThemeProvider } from "next-themes"
import { BlurProvider } from "@/lib/contexts/blur-context"

// Create a client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      // Production defaults
      staleTime: 1000 * 60 * 5, // 5 minutes
      refetchOnWindowFocus: process.env.NODE_ENV === "production",
    },
  },
})

export function AppProviders({ children }: { children: ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
        <BlurProvider>{children}</BlurProvider>
      </ThemeProvider>
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}
