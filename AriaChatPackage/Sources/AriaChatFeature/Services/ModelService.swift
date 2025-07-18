import Foundation

@MainActor
public class ModelService: ObservableObject {
    public static let shared = ModelService()
    
    @Published public var providers: [ModelProvider] = []
    @Published public var currentProvider: String?
    @Published public var currentModel: String?
    @Published public var providerModels: [String: [Model]] = [:]
    @Published public var isLoadingProviders = false
    @Published public var isLoadingModels: [String: Bool] = [:]
    @Published public var providersError: Error?
    @Published public var modelsErrors: [String: Error] = [:]
    
    private let apiClient = RESTAPIClient.shared
    
    private init() {}
    
    // MARK: - Providers
    
    public func loadProviders(refresh: Bool = false) async throws {
        if isLoadingProviders && !refresh {
            return
        }
        
        isLoadingProviders = true
        providersError = nil
        
        do {
            let response: ModelProviderResponse = try await apiClient.get(
                APIEndpoints.modelProviders,
                type: ModelProviderResponse.self
            )
            
            self.providers = response.data.providers
            self.currentProvider = response.data.currentProvider
            self.currentModel = response.data.currentModel
            
            print("ModelService: Loaded \(providers.count) providers")
            print("ModelService: Current provider: \(currentProvider ?? "none")")
            print("ModelService: Current model: \(currentModel ?? "none")")
            
        } catch {
            print("ModelService: Error loading providers: \(error)")
            self.providersError = error
            throw error
        }
        
        isLoadingProviders = false
    }
    
    // MARK: - Models
    
    public func loadModels(for provider: String, refresh: Bool = false) async throws {
        if isLoadingModels[provider] == true && !refresh {
            return
        }
        
        isLoadingModels[provider] = true
        modelsErrors.removeValue(forKey: provider)
        
        do {
            let response: ProviderModelsResponse = try await apiClient.get(
                APIEndpoints.providerModels(provider),
                type: ProviderModelsResponse.self
            )
            
            self.providerModels[provider] = response.data.models
            print("ModelService: Loaded \(response.data.models.count) models for provider \(provider)")
            
        } catch {
            print("ModelService: Error loading models for \(provider): \(error)")
            self.modelsErrors[provider] = error
            throw error
        }
        
        isLoadingModels[provider] = false
    }
    
    public func loadAllProviderModels(refresh: Bool = false) async throws {
        let configuredProviders = providers.filter { $0.isConfigured }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for provider in configuredProviders {
                group.addTask {
                    try await self.loadModels(for: provider.name, refresh: refresh)
                }
            }
            
            for try await _ in group {}
        }
    }
    
    // MARK: - Model Selection
    
    public func selectModel(provider: String, model: String, setAsDefault: Bool = true) async throws {
        let request = SelectModelRequest(
            provider: provider,
            model: model,
            setAsDefault: setAsDefault
        )
        
        do {
            let _: APIResponse<EmptyResponse> = try await apiClient.post(
                APIEndpoints.selectModel,
                body: request,
                type: APIResponse<EmptyResponse>.self
            )
            
            if setAsDefault {
                self.currentProvider = provider
                self.currentModel = model
            }
            
            print("ModelService: Selected model \(model) from provider \(provider)")
            
        } catch {
            print("ModelService: Error selecting model: \(error)")
            throw error
        }
    }
    
    // MARK: - Model Testing
    
    public func testModel(
        provider: String,
        model: String,
        prompt: String,
        temperature: Double? = nil,
        maxTokens: Int? = nil
    ) async throws -> TestModelResponse {
        let request = TestModelRequest(
            provider: provider,
            model: model,
            prompt: prompt,
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        do {
            let response: TestModelResponse = try await apiClient.post(
                APIEndpoints.testModel,
                body: request,
                type: TestModelResponse.self
            )
            
            print("ModelService: Test completed for \(model) - latency: \(response.latencyMs)ms")
            return response
            
        } catch {
            print("ModelService: Error testing model: \(error)")
            throw error
        }
    }
    
    // MARK: - Utility Methods
    
    public func getConfiguredProviders() -> [ModelProvider] {
        return providers.filter { $0.isConfigured }
    }
    
    public func getActiveProviders() -> [ModelProvider] {
        return providers.filter { $0.isActive }
    }
    
    public func getAvailableModels(for provider: String) -> [Model] {
        return providerModels[provider]?.filter { $0.isAvailable } ?? []
    }
    
    public func getAllAvailableModels() -> [(provider: ModelProvider, models: [Model])] {
        return getConfiguredProviders().compactMap { provider in
            let models = getAvailableModels(for: provider.name)
            return models.isEmpty ? nil : (provider, models)
        }
    }
    
    public func getProvider(name: String) -> ModelProvider? {
        return providers.first { $0.name == name }
    }
    
    public func getModel(provider: String, name: String) -> Model? {
        return providerModels[provider]?.first { $0.name == name }
    }
    
    public func isProviderHealthy(_ provider: String) -> Bool {
        return getProvider(name: provider)?.configurationStatus.isHealthy ?? false
    }
    
    // MARK: - Refresh All
    
    public func refreshAll() async throws {
        try await loadProviders(refresh: true)
        try await loadAllProviderModels(refresh: true)
    }
}

// MARK: - Additional Response Models

public struct TestModelResponse: Codable, Sendable {
    public let response: String
    public let latencyMs: Double
    public let tokenUsage: TokenUsage
    public let costEstimate: CostEstimate
    
    private enum CodingKeys: String, CodingKey {
        case response
        case latencyMs = "latency_ms"
        case tokenUsage = "token_usage"
        case costEstimate = "cost_estimate"
    }
}

public struct TokenUsage: Codable, Sendable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
    
    private enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

public struct CostEstimate: Codable, Sendable {
    public let inputCost: Double
    public let outputCost: Double
    public let totalCost: Double
    public let currency: String
    
    private enum CodingKeys: String, CodingKey {
        case inputCost = "input_cost"
        case outputCost = "output_cost"
        case totalCost = "total_cost"
        case currency
    }
}

public struct EmptyResponse: Codable, Sendable {
    public init() {}
}