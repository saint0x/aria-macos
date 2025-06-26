import SwiftUI

// Hover state management
struct HoverStateModifier: ViewModifier {
    @State private var isHovered = false
    let onHover: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                isHovered = hovering
                onHover(hovering)
            }
    }
}

// Interactive button with hover states
struct InteractiveButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    
    @State private var isHovered = false
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            label()
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isPressed ? Color.hoverBackground(for: colorScheme).opacity(2) :
                    isHovered ? Color.hoverBackground(for: colorScheme) :
                    Color.clear
                )
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// Hover effect for clickable items
struct HoverHighlightModifier: ViewModifier {
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.hoverBackground(for: colorScheme) : Color.clear)
            )
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

extension View {
    func hoverState(onHover: @escaping (Bool) -> Void) -> some View {
        self.modifier(HoverStateModifier(onHover: onHover))
    }
    
    func hoverHighlight() -> some View {
        self.modifier(HoverHighlightModifier())
    }
}