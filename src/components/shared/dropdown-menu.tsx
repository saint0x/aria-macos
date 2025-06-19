"use client"

import React from "react"
import { useState, useEffect, type RefObject } from "react"
import { createPortal } from "react-dom"
import { cn } from "@/lib/utils"
import { useBlur } from "@/lib/contexts/blur-context" // Import the hook

export interface MenuItem {
  id: string
  name: string
  action?: () => void
  separator?: "before"
  disabled?: boolean
}

interface DropdownMenuProps {
  isOpen: boolean
  anchorRef: RefObject<HTMLElement>
  containerRef?: RefObject<HTMLElement>
  items: MenuItem[]
  onSelectItem?: (item: MenuItem) => void
  onClose?: () => void
  className?: string
  menuWidth?: number
  align?: "containerLeft" | "containerRight" | "center"
  // blurIntensity prop is removed
}

const MAX_VISIBLE_ITEMS = 4
const ITEM_HEIGHT_ESTIMATE_REM = 2.25

export function DropdownMenuComponent({
  isOpen,
  anchorRef,
  containerRef,
  items,
  onSelectItem,
  onClose,
  className,
  menuWidth = 180,
  align = "center",
}: DropdownMenuProps) {
  const { blurIntensity } = useBlur() // Get blur from context
  const [mounted, setMounted] = useState(false)
  const [portalElement, setPortalElement] = useState<HTMLElement | null>(null)
  const [position, setPosition] = useState({ top: 0, left: 0, width: 0 })

  useEffect(() => setPortalElement(document.body), [])

  useEffect(() => {
    if (isOpen) {
      const timer = setTimeout(() => setMounted(true), 10)
      return () => clearTimeout(timer)
    } else {
      setMounted(false)
    }
  }, [isOpen])

  useEffect(() => {
    if (isOpen && anchorRef.current && portalElement) {
      const triggerRect = anchorRef.current.getBoundingClientRect()
      const containerRect = containerRef?.current?.getBoundingClientRect()
      const finalMenuWidth = menuWidth

      let leftPosition: number

      if (align === "containerLeft" && containerRect) {
        leftPosition = containerRect.left
      } else if (align === "containerRight" && containerRect) {
        leftPosition = containerRect.right - finalMenuWidth
      } else {
        leftPosition = triggerRect.left + triggerRect.width / 2 - finalMenuWidth / 2
      }

      if (leftPosition + finalMenuWidth > window.innerWidth - 16) {
        leftPosition = window.innerWidth - finalMenuWidth - 16
      }
      if (leftPosition < 16) {
        leftPosition = 16
      }

      setPosition({
        top: triggerRect.bottom + 16,
        left: leftPosition,
        width: finalMenuWidth,
      })
    }
  }, [isOpen, anchorRef, containerRef, portalElement, menuWidth, align])

  useEffect(() => {
    if (!isOpen) return
    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as Node
      if (
        anchorRef.current &&
        !anchorRef.current.contains(target) &&
        target instanceof Element &&
        !target.closest(".dropdown-menu-container")
      ) {
        onClose?.()
      }
    }
    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [isOpen, anchorRef, onClose])

  if (!isOpen || !portalElement) return null

  return createPortal(
    <div
      className={cn(
        "fixed z-[100] overflow-hidden rounded-2xl border border-white/20",
        "bg-white/30 dark:bg-neutral-800/30",
        "shadow-apple-xl dropdown-menu-container",
        "transition-opacity duration-200 ease-[cubic-bezier(0.32,0.72,0,1)]",
        mounted ? "opacity-100 animate-expand-in" : "opacity-0 scale-95",
        className,
      )}
      style={{
        top: `${position.top}px`,
        left: `${position.left}px`,
        width: `${position.width}px`,
        // @ts-ignore
        "--tw-backdrop-blur": `blur(${blurIntensity}px)`,
        WebkitBackdropFilter: `blur(${blurIntensity}px)`,
        backdropFilter: `blur(${blurIntensity}px)`,
      }}
    >
      <div className="relative p-1.5">
        <div
          className={cn(
            "space-y-1 overflow-y-auto",
            "[&::-webkit-scrollbar]:hidden [-ms-overflow-style:none] [scrollbar-width:none]",
          )}
          style={{ maxHeight: `calc(${MAX_VISIBLE_ITEMS} * ${ITEM_HEIGHT_ESTIMATE_REM}rem)` }}
        >
          {items.map((item, index) => (
            <React.Fragment key={item.id}>
              {item.separator === "before" && index > 0 && (
                <div className="my-1 h-px bg-neutral-300/70 dark:bg-neutral-600/70" role="separator" />
              )}
              <div
                className={cn(
                  "flex cursor-pointer items-center justify-between rounded-lg px-2.5 py-1.5 text-sm",
                  "text-neutral-700 dark:text-neutral-200",
                  "transition-all duration-150 ease-out dropdown-menu-item",
                  mounted ? "opacity-100 translate-y-0" : "opacity-0 translate-y-1",
                  item.disabled
                    ? "opacity-50 cursor-not-allowed hover:bg-transparent dark:hover:bg-transparent"
                    : "hover:bg-black/5 dark:hover:bg-white/10",
                )}
                style={{ transitionDelay: mounted ? `${index * 20}ms` : "0ms" }}
                onClick={() => {
                  if (item.disabled) return
                  item.action ? item.action() : onSelectItem?.(item)
                  onClose?.()
                }}
                aria-disabled={item.disabled}
              >
                <div className="flex items-center gap-2.5">
                  <span>{item.name}</span>
                </div>
              </div>
            </React.Fragment>
          ))}
        </div>
      </div>
    </div>,
    portalElement,
  )
}
