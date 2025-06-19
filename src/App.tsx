import React from "react"
import { BrowserRouter, Routes, Route } from "react-router-dom"
import { AppProviders } from "@/lib/providers"
import Home from "./pages/Home"

function App() {
  return (
    <AppProviders>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Home />} />
        </Routes>
      </BrowserRouter>
    </AppProviders>
  )
}

export default App