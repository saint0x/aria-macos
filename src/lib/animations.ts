"use client"

import type { Variants, Transition } from "framer-motion"

export const defaultTransition: Transition = {
  type: "spring",
  stiffness: 400,
  damping: 30,
  mass: 0.7,
}

export const gentleTransition: Transition = {
  type: "tween",
  duration: 0.3,
  ease: [0.32, 0.72, 0, 1], // Matches existing ease
}

export const fadeVariants: Variants = {
  initial: { opacity: 0 },
  animate: { opacity: 1 },
  exit: { opacity: 0 },
}

export const slideUpFadeVariants: Variants = {
  initial: { opacity: 0, y: 10 },
  animate: { opacity: 1, y: 0, transition: gentleTransition },
  exit: { opacity: 0, y: 8, transition: { ...gentleTransition, duration: 0.2 } },
}

export const expandInVariants: Variants = {
  initial: { opacity: 0, scale: 0.97 },
  animate: { opacity: 1, scale: 1, transition: gentleTransition },
  exit: { opacity: 0, scale: 0.97, transition: { ...gentleTransition, duration: 0.2 } },
}

// Specific for chatbar height animation
export const chatbarHeightProps = (isExpanded: boolean) => ({
  height: isExpanded ? "450px" : "auto",
  transition: gentleTransition,
})

// For the main chatbar container's entry/exit
export const mainChatbarContainerVariants: Variants = {
  initial: { opacity: 0, scale: 0.95 },
  animate: { opacity: 1, scale: 1, transition: gentleTransition },
  exit: { opacity: 0, scale: 0.95, transition: { ...gentleTransition, duration: 0.2 } },
}
