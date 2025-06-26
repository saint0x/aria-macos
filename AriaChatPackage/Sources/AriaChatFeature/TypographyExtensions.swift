import SwiftUI

// Typography extensions matching Tailwind classes
extension Font {
    // text-xs = 12px
    static let textXS = Font.system(size: 12)
    
    // text-sm = 14px
    static let textSM = Font.system(size: 14)
    
    // text-base = 16px
    static let textBase = Font.system(size: 16)
    
    // text-lg = 18px
    static let textLG = Font.system(size: 18)
    
    // text-xl = 20px
    static let textXL = Font.system(size: 20)
    
    // With weights
    static func textXS(_ weight: Font.Weight) -> Font {
        Font.system(size: 12, weight: weight)
    }
    
    static func textSM(_ weight: Font.Weight) -> Font {
        Font.system(size: 14, weight: weight)
    }
    
    static func textBase(_ weight: Font.Weight) -> Font {
        Font.system(size: 16, weight: weight)
    }
    
    static func textLG(_ weight: Font.Weight) -> Font {
        Font.system(size: 18, weight: weight)
    }
    
    // Design variants
    static let monoXS = Font.system(size: 12, design: .monospaced)
    static let monoSM = Font.system(size: 14, design: .monospaced)
}

// View extension for common text styles
extension View {
    func textStyle(_ size: Font, _ color: Color) -> some View {
        self
            .font(size)
            .foregroundColor(color)
    }
}