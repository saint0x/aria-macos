import SwiftUI

// Apple-inspired color palette from tailwind.config.ts
extension Color {
    // Apple Gray colors with exact opacity values
    static let appleGray100 = Color(red: 242/255, green: 242/255, blue: 247/255).opacity(0.8)
    static let appleGray200 = Color(red: 229/255, green: 229/255, blue: 234/255).opacity(0.8)
    static let appleGray300 = Color(red: 209/255, green: 209/255, blue: 214/255).opacity(0.8)
    static let appleGray400 = Color(red: 199/255, green: 199/255, blue: 204/255).opacity(0.8)
    static let appleGray500 = Color(red: 174/255, green: 174/255, blue: 178/255).opacity(0.8)
    static let appleGray600 = Color(red: 142/255, green: 142/255, blue: 147/255).opacity(0.8)
    static let appleGray700 = Color(red: 99/255, green: 99/255, blue: 102/255).opacity(0.8)
    static let appleGray800 = Color(red: 72/255, green: 72/255, blue: 74/255).opacity(0.8)
    static let appleGray900 = Color(red: 58/255, green: 58/255, blue: 60/255).opacity(0.8)
    
    // Apple Blues
    static let appleBlue = Color(red: 0/255, green: 122/255, blue: 255/255).opacity(0.9)
    static let appleBlueLight = Color(red: 10/255, green: 132/255, blue: 255/255).opacity(0.9)
    
    // Apple Greens
    static let appleGreen = Color(red: 52/255, green: 199/255, blue: 89/255).opacity(0.9)
    static let appleGreenDark = Color(red: 41/255, green: 163/255, blue: 72/255).opacity(0.9)
    
    // Apple Reds
    static let appleRed = Color(red: 255/255, green: 59/255, blue: 48/255).opacity(0.9)
    
    // Apple Oranges
    static let appleOrange = Color(red: 255/255, green: 149/255, blue: 0/255).opacity(0.9)
    
    // Text colors from React components
    static func textPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(red: 245/255, green: 245/255, blue: 245/255) // text-neutral-100
            : Color(red: 38/255, green: 38/255, blue: 38/255)   // text-neutral-800
    }
    
    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 163/255, green: 163/255, blue: 163/255) // text-neutral-400
            : Color(red: 115/255, green: 115/255, blue: 115/255) // text-neutral-600
    }
    
    static func textTertiary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 115/255, green: 115/255, blue: 115/255) // text-neutral-600
            : Color(red: 82/255, green: 82/255, blue: 82/255)   // text-neutral-700
    }
    
    // Button text colors
    static func buttonText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 229/255, green: 229/255, blue: 229/255) // text-neutral-200
            : Color(red: 38/255, green: 38/255, blue: 38/255)   // text-neutral-800
    }
    
    static func buttonTextHover(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 245/255, green: 245/255, blue: 245/255) // text-neutral-100
            : Color(red: 23/255, green: 23/255, blue: 23/255)   // text-neutral-900
    }
    
    // Footer button specific colors
    static func footerButtonText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 212/255, green: 212/255, blue: 212/255) // text-neutral-300
            : Color(red: 64/255, green: 64/255, blue: 64/255)   // text-neutral-700
    }
    
    // Placeholder colors
    static func placeholderText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 163/255, green: 163/255, blue: 163/255).opacity(0.8) // placeholder:text-neutral-400/80
            : Color(red: 82/255, green: 82/255, blue: 82/255)                // placeholder:text-neutral-600
    }
    
    // Hover backgrounds
    static func hoverBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1) // hover:bg-white/10
            : Color.black.opacity(0.05) // hover:bg-black/5
    }
    
    // Border colors
    static func borderColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1) // border-white/10
            : Color.black.opacity(0.1) // border-black/10
    }
    
    // Input backgrounds - bg-white/20 dark:bg-neutral-700/20
    static func inputBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.2) // neutral-700/20
            : Color.white.opacity(0.2) // white/20
    }
    
    // Glassmorphic backgrounds
    static func glassmorphicBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 30/255, green: 30/255, blue: 30/255).opacity(0.6)
            : Color(red: 255/255, green: 255/255, blue: 255/255).opacity(0.8)
    }
}