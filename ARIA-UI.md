{
  "themeName": "Apple-Inspired Glassmorphism",
  "description": "A theme designed to emulate Apple's design language, focusing on depth, light, and material properties. It leverages a glassmorphic effect (frosted glass) for key UI elements, built upon a system of HSL color variables for easy theming in both light and dark modes.",
  "corePrinciples": [
    "Depth through layering, shadows, and blur.",
    "Clarity through legible, system-native typography.",
    "Translucency to create a sense of context and material realism."
  ],
  "specifications": {
    "glassmorphism": {
      "description": "The primary visual effect, achieved by combining a background blur with a semi-transparent background color and a subtle border.",
      "layers": [
        {
          "name": "Chatbar Background (Primary Surface)",
          "backdropFilter": {
            "property": "backdrop-filter",
            "value": "blur(24px)",
            "source": "tailwind.config.ts -> theme.extend.backdropBlur.xl"
          },
          "backgroundColor": {
            "lightMode": {
              "cssVariable": "N/A (Direct RGBA)",
              "value": "rgba(255, 255, 255, 0.30)",
              "tailwindClass": "bg-white/30"
            },
            "darkMode": {
              "cssVariable": "N/A (Direct RGBA from Tailwind's default palette)",
              "baseColor": "rgb(38, 38, 38) /* neutral-800 */",
              "value": "rgba(38, 38, 38, 0.30)",
              "tailwindClass": "dark:bg-neutral-800/30"
            }
          },
          "border": {
            "style": "1px solid rgba(255, 255, 255, 0.20)",
            "tailwindClass": "border border-white/20",
            "note": "This border is consistent across both light and dark modes to simulate light catching the edge of the glass."
          },
          "appliedClasses": [
            "backdrop-blur-xl",
            "bg-white/30",
            "dark:bg-neutral-800/30",
            "border",
            "border-white/20"
          ]
        },
        {
          "name": "Highlight Bar (Input/Step Highlight)",
          "backgroundColor": {
            "lightMode": {
              "baseColor": "rgb(243, 244, 246) /* neutral-100 */",
              "value": "rgba(243, 244, 246, 0.70)",
              "tailwindClass": "bg-neutral-100/70"
            },
            "darkMode": {
              "baseColor": "rgb(64, 64, 64) /* neutral-700 */",
              "value": "rgba(64, 64, 64, 0.50)",
              "tailwindClass": "dark:bg-neutral-700/50"
            }
          },
          "boxShadow": {
            "property": "box-shadow",
            "value": "inset 0 1px 1px 0 rgba(255,255,255,0.1), inset 0 -1px 1px 0 rgba(0,0,0,0.05)",
            "source": "tailwind.config.ts -> theme.extend.boxShadow.apple-inner"
          }
        }
      ]
    },
    "colorSystem": {
      "description": "Based on HSL CSS variables defined in app/globals.css, allowing for semantic color definitions.",
      "palettes": {
        "lightMode": {
          "--background": "210 40% 98%",
          "--foreground": "215 25% 27%",
          "--card": "210 40% 98%",
          "--primary": "217 91% 60%",
          "--secondary": "210 40% 96.1%",
          "--muted": "210 40% 96.1%",
          "--accent": "210 40% 96.1%",
          "--destructive": "0 84.2% 60.2%",
          "--border": "215 20% 90%",
          "--input": "215 20% 90%",
          "--ring": "217 91% 60%"
        },
        "darkMode": {
          "--background": "222 47% 11%",
          "--foreground": "210 40% 98%",
          "--card": "222 47% 11%",
          "--primary": "210 40% 98%",
          "--secondary": "217 33% 17%",
          "--muted": "217 33% 17%",
          "--accent": "217 33% 17%",
          "--destructive": "0 62.8% 30.6%",
          "--border": "217 20% 27%",
          "--input": "217 20% 27%",
          "--ring": "210 40% 98%"
        }
      }
    },
    "typography": {
      "fontStack": {
        "property": "font-family",
        "value": "-apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif, \"Apple Color Emoji\", \"Segoe UI Emoji\", \"Segoe UI Symbol\"",
        "source": "app/globals.css"
      },
      "fontSmoothing": {
        "webkit": "antialiased",
        "moz": "grayscale"
      },
      "baseTextSize": "16px",
      "componentTextSizes": {
        "input": "14px (text-sm)",
        "footerControls": "12px (text-xs)"
      }
    },
    "spacingAndSizing": {
      "baseUnit": "1rem (16px)",
      "borderRadius": {
        "source": "tailwind.config.ts -> theme.extend.borderRadius",
        "values": {
          "sm": "calc(var(--radius) - 4px) -> 8px",
          "md": "calc(var(--radius) - 2px) -> 10px",
          "lg": "var(--radius) -> 12px",
          "xl": "calc(var(--radius) + 4px) -> 16px",
          "2xl": "calc(var(--radius) + 10px) -> 22px",
          "3xl": "calc(var(--radius) + 18px) -> 30px"
        },
        "primaryUsage": "rounded-2xl (22px) for main containers."
      }
    },
    "effects": {
      "boxShadow": {
        "source": "tailwind.config.ts -> theme.extend.boxShadow",
        "primaryUsage": {
          "name": "apple-xl",
          "value": "0 20px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.04)"
        }
      },
      "animations": {
        "source": "tailwind.config.ts -> theme.extend.animation",
        "primaryUsage": {
          "expand-in": {
            "keyframes": "expand-in",
            "properties": "0.3s cubic-bezier(0.25, 1, 0.5, 1)"
          },
          "slide-up-fade": {
            "keyframes": "slide-up-fade",
            "properties": "0.3s cubic-bezier(0.25, 1, 0.5, 1)"
          }
        }
      }
    }
  }
}