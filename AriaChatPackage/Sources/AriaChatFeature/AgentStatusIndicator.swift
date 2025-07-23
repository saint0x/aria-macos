import SwiftUI

struct AgentStatusIndicator: View {
    let steps: [EnhancedStep]
    let onStepClick: (EnhancedStep) -> Void
    let activeHighlightId: String?
    
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var animationManager = AnimationManager.shared
    
    var body: some View {
        // Filter steps to show only those visible in main chat
        let visibleSteps = MessageVisibilityManager.filterSteps(steps, for: .mainChat)
        
        if visibleSteps.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 0) { // Changed to 0 for custom spacing
                ForEach(Array(visibleSteps.enumerated()), id: \.element.id) { index, step in
                    VStack(spacing: 0) {
                        stepView(for: step)
                            .animateMessageEntry(
                                messageId: step.id,
                                index: index,
                                totalMessages: visibleSteps.count
                            )
                        
                        // Add spacing based on message grouping
                        if index < visibleSteps.count - 1 {
                            let nextStep = visibleSteps[index + 1]
                            spacingView(between: step, and: nextStep)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func stepView(for step: EnhancedStep) -> some View {
        let isHighlighted = MessageVisibilityManager.shouldHighlight(step, activeHighlightId: activeHighlightId)
        
        switch step.type {
        case .userMessage:
            // User messages align to the right
            HStack {
                Spacer()
                Text(step.text)
                    .font(.textSM)
                    .foregroundColor(Color.textPrimary(for: colorScheme))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: 300, alignment: .trailing) // 80% of max width
            }
            .background(
                Group {
                    if isHighlighted {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.5) : Color(red: 243/255, green: 244/255, blue: 246/255).opacity(0.7))
                            .shadow(color: Color.white.opacity(0.1), radius: 1, x: 0, y: 1)
                            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: -1)
                            .padding(-6)
                    }
                }
            )
            
        case .thought:
            HStack(alignment: .center, spacing: 8) {
                statusIcon(for: step)
                    .frame(width: 16, height: 16)
                
                Text(step.text)
                    .font(.textSM)
                    .foregroundColor(Color.textPrimary(for: colorScheme))
                
                Spacer()
            }
            .padding(.horizontal, isHighlighted ? 8 : 0)
            .padding(.vertical, isHighlighted ? 6 : 0)
            .background(
                Group {
                    if isHighlighted {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.5) : Color(red: 243/255, green: 244/255, blue: 246/255).opacity(0.7))
                            .shadow(color: Color.white.opacity(0.1), radius: 1, x: 0, y: 1)
                            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: -1)
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if MessageVisibilityManager.isClickable(step) {
                    onStepClick(step)
                }
            }
            .onHover { hovering in
                if MessageVisibilityManager.isClickable(step) && hovering {
                    NSCursor.pointingHand.push()
                } else if !hovering {
                    NSCursor.pop()
                }
            }
            
        case .tool:
            ZStack(alignment: .topLeading) {
                // Vertical connector line for indented steps
                if step.isIndented, let stepIndex = steps.firstIndex(where: { $0.id == step.id }), stepIndex > 0 {
                    let previousStep = steps[stepIndex - 1]
                    // Check if previous step would be visible in main chat
                    if previousStep.isVisibleInMainChat && previousStep.type != .userMessage && previousStep.type != .response {
                        Rectangle()
                            .fill(colorScheme == .dark ? Color(white: 0.4).opacity(0.3) : Color.gray.opacity(0.3)) // neutral-400/30 or neutral-600/30
                            .frame(width: 1, height: 35) // Connect from previous step
                            .offset(x: step.isIndented ? 32 : 12, y: -25) // Position at parent icon location
                            .zIndex(-1)
                    }
                }
                
                HStack(alignment: .center, spacing: step.isIndented ? 8 : 10) { // gap-2 for indented, gap-2.5 for normal
                    if step.isIndented {
                        // Indentation for tool steps: ml-5 (20pt) + parent icon (24pt) + spacing (10pt) = 54pt total
                        Spacer()
                            .frame(width: 54)
                    }
                    
                    // Icon container with proper sizing
                    ZStack {
                        statusIcon(for: step)
                            .frame(width: 14, height: 14) // Icon is always 14x14 for tools
                    }
                    .frame(width: 24, height: 24) // Container is always 24x24
                    
                    // Tool text with proper formatting - "used: {toolName}"
                    if let toolName = step.toolName {
                        Text("used: ")
                            .font(.textXS) // Size 12 for prefix
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                        + Text(toolName)
                            .font(.textXS(.medium)) // Size 12 medium for tool name
                            .foregroundColor(step.status == .active ? 
                                Color.textPrimary(for: colorScheme) : 
                                Color.textSecondary(for: colorScheme))
                    } else {
                        Text("used: ")
                            .font(.textXS)
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                        + Text(step.text)
                            .font(.textXS(.medium)) // Size 12 medium for tools
                            .foregroundColor(step.status == .active ? 
                                Color.textPrimary(for: colorScheme) : 
                                Color.textSecondary(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    // Chevron for clickable steps
                    if !step.isIndented || isHighlighted {
                        Image(systemName: "chevron.right")
                            .frame(width: 20, height: 20) // h-5 w-5
                            .font(.system(size: 12))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.gray.opacity(0.9)) // text-neutral-500/90
                    }
                }
                .padding(.horizontal, 8) // px-2
                .padding(.vertical, 6) // py-1.5
                .background(
                    Group {
                        if isHighlighted {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark ? Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.5) : Color(red: 243/255, green: 244/255, blue: 246/255).opacity(0.7))
                                .shadow(color: Color.white.opacity(0.1), radius: 1, x: 0, y: 1)
                                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: -1)
                        }
                    }
                )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if MessageVisibilityManager.isClickable(step) {
                    onStepClick(step)
                }
            }
            .onHover { hovering in
                if MessageVisibilityManager.isClickable(step) && hovering {
                    NSCursor.pointingHand.push()
                } else if !hovering {
                    NSCursor.pop()
                }
            }
            
        case .response:
            HStack(alignment: .top, spacing: 8) {
                // Only show icon if not completed (no checkmarks for responses)
                if step.status != .completed {
                    statusIcon(for: step)
                        .frame(width: 16, height: 16)
                        .padding(.top, 2)
                }
                
                AdvancedMarkdownView(text: step.text)
                
                Spacer()
            }
            .padding(.horizontal, isHighlighted ? 8 : 0)
            .padding(.vertical, isHighlighted ? 6 : 0)
            .background(
                Group {
                    if isHighlighted {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color(red: 64/255, green: 64/255, blue: 64/255).opacity(0.5) : Color(red: 243/255, green: 244/255, blue: 246/255).opacity(0.7))
                            .shadow(color: Color.white.opacity(0.1), radius: 1, x: 0, y: 1)
                            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: -1)
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if MessageVisibilityManager.isClickable(step) {
                    onStepClick(step)
                }
            }
            .onHover { hovering in
                if MessageVisibilityManager.isClickable(step) && hovering {
                    NSCursor.pointingHand.push()
                } else if !hovering {
                    NSCursor.pop()
                }
            }
        }
    }
    
    @ViewBuilder
    private func statusIcon(for step: EnhancedStep) -> some View {
        if let iconConfig = StatusIconProvider.iconConfig(for: step, colorScheme: colorScheme) {
            Image(systemName: iconConfig.systemName)
                .foregroundColor(iconConfig.color)
                .font(.system(size: iconConfig.size, weight: iconConfig.weight))
        } else if StatusIconProvider.shouldShowProgressIndicator(for: step) {
            // Loader for active thoughts
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(0.7)
                .frame(width: 14, height: 14)
        } else if StatusIconProvider.shouldShowDot(for: step) {
            // Default dot for thoughts
            Circle()
                .fill(Color(red: 115/255, green: 115/255, blue: 115/255).opacity(0.7)) // neutral-500/70
                .frame(width: 8, height: 8)
        }
    }
    
    @ViewBuilder
    private func spacingView(between current: EnhancedStep, and next: EnhancedStep) -> some View {
        let spacing = MessageVisibilityManager.spacing(between: current, and: next)
        Spacer()
            .frame(height: spacing)
    }
}