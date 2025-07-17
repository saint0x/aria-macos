import SwiftUI

struct DropdownButton: View {
    let title: String
    @Binding var isOpen: Bool
    let items: [MenuItem]
    let onSelect: (MenuItem) -> Void
    
    @State private var buttonFrame: CGRect = .zero
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: { isOpen.toggle() }) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.textXS)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(Color.textSecondary(for: colorScheme))
            }
        }
        .buttonStyle(FooterButtonStyle())
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        buttonFrame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                        buttonFrame = newFrame
                    }
            }
        )
        .overlay(
            Group {
                if isOpen {
                    DropdownMenuOverlay(
                        items: items,
                        isOpen: $isOpen,
                        buttonFrame: buttonFrame,
                        onSelect: onSelect
                    )
                }
            }
        )
    }
}

struct DropdownMenuView: View {
    let items: [MenuItem]
    let onSelect: (MenuItem) -> Void
    @Binding var isOpen: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var mounted = false
    
    var body: some View {
        let menuContent = VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                menuItemView(for: item)
                    .opacity(mounted ? 1 : 0)
                    .scaleEffect(mounted ? 1 : 0.97)
                    .animation(
                        AnimationSystem.gentleTransition // Use gentleTransition as per SWIFT2.md
                            .delay(Double(index) * 0.02), // Stagger animation  
                        value: mounted
                    )
            }
        }
        .padding(6)
        .frame(width: 180)
        
        let backgroundView = RoundedRectangle(cornerRadius: 12)
            .fill(Color.glassmorphicBackground(for: colorScheme))
            .background(
                VisualEffectView(material: .menu, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )
        
        let borderView = RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
        
        menuContent
            .background(backgroundView)
            .overlay(borderView)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .onAppear {
                mounted = true
            }
            .onDisappear {
                mounted = false
            }
    }
    
    @ViewBuilder
    private func menuItemView(for item: MenuItem) -> some View {
        let itemIndex = items.firstIndex(where: { $0.id == item.id }) ?? 0
        
        Group {
            if item.separator == "before" && itemIndex > 0 {
                Divider()
                    .background(Color(NSColor.separatorColor).opacity(0.3))
                    .padding(.vertical, 4)
            }
            
            menuButton(for: item)
        }
    }
    
    @ViewBuilder
    private func menuButton(for item: MenuItem) -> some View {
        Button(action: {
            if !item.disabled {
                onSelect(item)
                isOpen = false
            }
        }) {
            HStack(spacing: 8) {
                Text(item.name)
                    .font(.textSM)
                    .foregroundColor(menuItemTextColor(for: item))
                
                Spacer()
                
                // Category pill label (only show if category exists)
                if let category = item.category {
                    Text(category.displayName.uppercased())
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(category.color)
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(item.disabled)
        .background(menuButtonBackground(for: item))
        .onHover { hovering in
            handleHover(hovering: hovering, item: item)
        }
    }
    
    private func menuItemTextColor(for item: MenuItem) -> Color {
        item.disabled
            ? Color(NSColor.tertiaryLabelColor)
            : Color(NSColor.labelColor)
    }
    
    @State private var hoveredItemId: String? = nil
    
    private func menuButtonBackground(for item: MenuItem) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                hoveredItemId == item.id && !item.disabled ?
                Color.hoverBackground(for: colorScheme) :
                Color.clear
            )
            .animation(.easeOut(duration: 0.15), value: hoveredItemId)
    }
    
    private func handleHover(hovering: Bool, item: MenuItem) {
        if hovering && !item.disabled {
            hoveredItemId = item.id
            NSCursor.pointingHand.push()
        } else {
            if hoveredItemId == item.id {
                hoveredItemId = nil
            }
            NSCursor.pop()
        }
    }
}

struct DropdownMenuOverlay: View {
    let items: [MenuItem]
    @Binding var isOpen: Bool
    let buttonFrame: CGRect
    let onSelect: (MenuItem) -> Void
    
    @State private var mounted = false
    @Environment(\.colorScheme) var colorScheme
    
    private let menuWidth: CGFloat = 180
    
    var body: some View {
        ZStack {
            // Invisible background to capture clicks outside
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isOpen = false
                }
            
            // Dropdown menu
            DropdownMenuView(items: items, onSelect: onSelect, isOpen: $isOpen)
                .expandIn(isVisible: mounted)
                .position(
                    x: buttonFrame.midX,
                    y: buttonFrame.maxY + 16 + 90 // 16pt gap as per SWIFT2.md, plus half menu height
                )
        }
        .onAppear {
            DispatchQueue.main.async {
                mounted = true
            }
        }
    }
}
