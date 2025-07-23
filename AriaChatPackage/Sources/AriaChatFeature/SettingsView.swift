import SwiftUI

// MARK: - Settings View matching SWIFT.md spec with accordion layout
struct SettingsView: View {
    @EnvironmentObject var blurSettings: BlurSettings
    @StateObject private var themeSettings = ThemeSettings.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Model Configuration
    @State private var selectedModel = "gpt-4"
    @State private var systemPromptFile: String? = nil
    
    // Dynamic Services
    @StateObject private var registryService = RegistryService.shared
    @StateObject private var modelService = ModelService.shared
    
    // UI State
    @State private var isLoadingData = false
    
    // Accordion expansion states
    @State private var modelConfigExpanded = false
    @State private var utilityManagementExpanded = false
    @State private var visualSettingsExpanded = false
    
    // Dynamic computed property for model providers
    private var dynamicModelProviders: [(String, [String])] {
        return modelService.getAllAvailableModels().map { providerData in
            (providerData.provider.displayName, providerData.models.map { $0.name })
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) { // space-y-3
                // Model Configuration Section
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        modelConfigExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("Model Configuration")
                            .font(.textSM(.medium))
                            .foregroundColor(Color.textPrimary(for: colorScheme))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                            .rotationEffect(.degrees(modelConfigExpanded ? 0 : -90))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.inputBackground(for: colorScheme))
                )
                .appleShadowSmall()
                
                if modelConfigExpanded {
                    VStack(alignment: .leading, spacing: 16) {
                        // AI Model Select
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Model")
                                .font(.textSM)
                                .foregroundColor(Color.textSecondary(for: colorScheme))
                            
                            Menu {
                                if dynamicModelProviders.isEmpty {
                                    Text("Loading providers...")
                                        .foregroundColor(Color.textSecondary(for: colorScheme))
                                } else {
                                    ForEach(dynamicModelProviders, id: \.0) { provider, models in
                                        Section(header: Text(provider)) {
                                            ForEach(models, id: \.self) { model in
                                                Button(action: { 
                                                    selectedModel = model
                                                    // TODO: Call model selection API
                                                }) {
                                                    HStack {
                                                        Text(model)
                                                        if selectedModel == model {
                                                            Spacer()
                                                            Image(systemName: "checkmark")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedModel)
                                        .font(.textSM)
                                        .foregroundColor(Color.textPrimary(for: colorScheme))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.textSecondary(for: colorScheme))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.inputBackground(for: colorScheme))
                                )
                                .innerShadow(cornerRadius: 8)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // System Prompt File
                        VStack(alignment: .leading, spacing: 8) {
                            Text("System Prompt File")
                                .font(.textSM)
                                .foregroundColor(Color.textSecondary(for: colorScheme))
                            
                            Button(action: {
                                // File picker would go here
                            }) {
                                HStack {
                                    Text(systemPromptFile ?? "Select a file...")
                                        .font(.textSM)
                                        .foregroundColor(systemPromptFile != nil ? Color.textPrimary(for: colorScheme) : Color.textTertiary(for: colorScheme))
                                    Spacer()
                                    Image(systemName: "folder")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.textSecondary(for: colorScheme))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.inputBackground(for: colorScheme))
                                )
                                .innerShadow(cornerRadius: 8)
                            }
                            .buttonStyle(.plain)
                            .fileImporter(
                                isPresented: .constant(false),
                                allowedContentTypes: [.text],
                                allowsMultipleSelection: false
                            ) { result in
                                if case .success(let urls) = result,
                                   let url = urls.first {
                                    systemPromptFile = url.lastPathComponent
                                }
                            }
                        }
                    }
                    .padding(14)
                    .padding(.top, -8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.inputBackground(for: colorScheme).opacity(0.5))
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
                
                // Utility Management Section
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        utilityManagementExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("Utility Management")
                            .font(.textSM(.medium))
                            .foregroundColor(Color.textPrimary(for: colorScheme))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                            .rotationEffect(.degrees(utilityManagementExpanded ? 0 : -90))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.inputBackground(for: colorScheme))
                )
                .appleShadowSmall()
                
                if utilityManagementExpanded {
                    VStack(spacing: 16) {
                        // Tools
                        DynamicUtilitySection(
                            title: "Tools",
                            items: registryService.getAvailableTools().map { $0.name },
                            isLoading: registryService.isLoadingTools,
                            error: registryService.toolsError
                        )
                        
                        // Agents
                        DynamicUtilitySection(
                            title: "Agents", 
                            items: registryService.getAvailableAgents().map { $0.name },
                            isLoading: registryService.isLoadingAgents,
                            error: registryService.agentsError
                        )
                        
                        // Team (placeholder for now)
                        DynamicUtilitySection(
                            title: "Team",
                            items: [],
                            isLoading: false,
                            error: nil
                        )
                        
                        // Pipelines (placeholder for now)
                        DynamicUtilitySection(
                            title: "Pipelines",
                            items: [],
                            isLoading: false,
                            error: nil
                        )
                    }
                    .padding(14)
                    .padding(.top, -8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.inputBackground(for: colorScheme).opacity(0.5))
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
                
                // Visual Settings Section
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        visualSettingsExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("Visual Settings")
                            .font(.textSM(.medium))
                            .foregroundColor(Color.textPrimary(for: colorScheme))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                            .rotationEffect(.degrees(visualSettingsExpanded ? 0 : -90))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.inputBackground(for: colorScheme))
                )
                .appleShadowSmall()
                
                if visualSettingsExpanded {
                    VStack(alignment: .leading, spacing: 16) {
                        // Backdrop Blur Slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Backdrop Blur")
                                    .font(.textSM)
                                    .foregroundColor(Color.textSecondary(for: colorScheme))
                                Spacer()
                                Text("\(Int(blurSettings.blurIntensity))px")
                                    .font(.monoXS)
                                    .foregroundColor(Color.textPrimary(for: colorScheme))
                            }
                            
                            Slider(value: $blurSettings.blurIntensity, in: 0...40)
                                .tint(Color.appleBlue)
                        }
                        
                        // Interface Theme
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Interface Theme")
                                .font(.textSM)
                                .foregroundColor(Color.textSecondary(for: colorScheme))
                            
                            Menu {
                                ForEach(["Light", "Dark", "System"], id: \.self) { theme in
                                    Button(action: { themeSettings.selectedTheme = theme }) {
                                        HStack {
                                            Text(theme)
                                            if themeSettings.selectedTheme == theme {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(themeSettings.selectedTheme)
                                        .font(.textSM)
                                        .foregroundColor(Color.textPrimary(for: colorScheme))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.textSecondary(for: colorScheme))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.inputBackground(for: colorScheme))
                                )
                                .innerShadow(cornerRadius: 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .padding(.top, -8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.inputBackground(for: colorScheme).opacity(0.5))
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
            }
            .padding(4) // Outer padding
        }
        .slideUpFade(isVisible: true)
        .onAppear {
            if !isLoadingData {
                isLoadingData = true
                Task {
                    do {
                        async let toolsTask = registryService.loadTools()
                        async let agentsTask = registryService.loadAgents()
                        async let providersTask = modelService.loadProviders()
                        
                        try await toolsTask
                        try await agentsTask
                        try await providersTask
                        
                        // Load models for all configured providers
                        try await modelService.loadAllProviderModels()
                        
                        // Set current model selection if available
                        if let currentModel = modelService.currentModel {
                            selectedModel = currentModel
                        }
                        
                        print("SettingsView: Loaded dynamic data successfully")
                    } catch {
                        print("SettingsView: Error loading data: \(error)")
                    }
                    isLoadingData = false
                }
            }
        }
    }
}

// MARK: - Dynamic Utility Section Component
struct DynamicUtilitySection: View {
    let title: String
    let items: [String]
    let isLoading: Bool
    let error: Error?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.textXS(.medium))
                    .foregroundColor(Color.textSecondary(for: colorScheme))
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            if let error = error {
                Text("Error loading \(title.lowercased()): \(error.localizedDescription)")
                    .font(.textXS)
                    .foregroundColor(.red)
                    .italic()
            } else if items.isEmpty && !isLoading {
                Text("No \(title.lowercased()) available")
                    .font(.textXS)
                    .foregroundColor(Color.textTertiary(for: colorScheme))
                    .italic()
            } else if !items.isEmpty {
                ForEach(0..<items.count, id: \.self) { index in
                    VStack(spacing: 0) {
                        HStack {
                            Text(items[index])
                                .font(.textSM)
                                .foregroundColor(Color.textPrimary(for: colorScheme))
                            
                            Spacer()
                            
                            // Show availability indicator
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                        .padding(.vertical, 4)
                        
                        if index < items.count - 1 {
                            Divider()
                                .background(Color.borderColor(for: colorScheme).opacity(0.5))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Legacy Utility Section Component (kept for compatibility)
struct UtilitySection: View {
    let title: String
    @Binding var items: [String]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.textXS(.medium))
                .foregroundColor(Color.textSecondary(for: colorScheme))
            
            if items.isEmpty {
                Text("No \(title.lowercased()) configured")
                    .font(.textXS)
                    .foregroundColor(Color.textTertiary(for: colorScheme))
                    .italic()
            } else {
                ForEach(0..<items.count, id: \.self) { index in
                    if index < items.count {
                        VStack(spacing: 0) {
                            HStack {
                                Text(items[index])
                                    .font(.textSM)
                                    .foregroundColor(Color.textPrimary(for: colorScheme))
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        if index < items.count {
                                            items.remove(at: index)
                                        }
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.textTertiary(for: colorScheme))
                                }
                                .buttonStyle(.plain)
                                .hoverHighlight()
                            }
                            .padding(.vertical, 4)
                            
                            if index < items.count - 1 {
                                Divider()
                                    .background(Color.borderColor(for: colorScheme).opacity(0.5))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Accordion Style View Modifier
struct AccordionStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(14) // p-3.5
            .background(
                RoundedRectangle(cornerRadius: 16) // rounded-xl
                    .fill(Color.inputBackground(for: colorScheme)) // bg-white/20 dark:bg-neutral-700/20
            )
            .appleShadowSmall() // shadow-apple-sm
    }
}

extension View {
    func accordionStyle() -> some View {
        self.modifier(AccordionStyle())
    }
}