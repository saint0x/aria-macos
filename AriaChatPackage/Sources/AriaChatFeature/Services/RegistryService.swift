import Foundation

@MainActor
public class RegistryService: ObservableObject {
    public static let shared = RegistryService()
    
    @Published public var tools: [Tool] = []
    @Published public var agents: [Agent] = []
    @Published public var isLoadingTools = false
    @Published public var isLoadingAgents = false
    @Published public var toolsError: Error?
    @Published public var agentsError: Error?
    
    private let apiClient = RESTAPIClient.shared
    
    private init() {}
    
    // MARK: - Tools
    
    public func loadTools(
        search: String? = nil,
        category: String? = nil,
        scope: String? = nil,
        refresh: Bool = false
    ) async throws {
        if isLoadingTools && !refresh {
            return
        }
        
        isLoadingTools = true
        toolsError = nil
        
        do {
            let queryParams = APIEndpoints.QueryParams.toolsRegistry(
                search: search,
                category: category,
                scope: scope
            )
            
            let response: ToolRegistryResponse = try await apiClient.get(
                endpoint: APIEndpoints.toolsRegistry,
                queryParams: queryParams
            )
            
            self.tools = response.data.tools
            print("RegistryService: Loaded \(tools.count) tools")
            
        } catch {
            print("RegistryService: Error loading tools: \(error)")
            self.toolsError = error
            throw error
        }
        
        isLoadingTools = false
    }
    
    public func getToolDetails(_ name: String) async throws -> Tool? {
        do {
            let response: Tool = try await apiClient.get(
                endpoint: APIEndpoints.toolDetails(name)
            )
            return response
        } catch {
            print("RegistryService: Error getting tool details for \(name): \(error)")
            throw error
        }
    }
    
    // MARK: - Agents
    
    public func loadAgents(
        search: String? = nil,
        refresh: Bool = false
    ) async throws {
        if isLoadingAgents && !refresh {
            return
        }
        
        isLoadingAgents = true
        agentsError = nil
        
        do {
            let queryParams = APIEndpoints.QueryParams.agentsRegistry(search: search)
            
            let response: AgentRegistryResponse = try await apiClient.get(
                endpoint: APIEndpoints.agentsRegistry,
                queryParams: queryParams
            )
            
            self.agents = response.data.agents
            print("RegistryService: Loaded \(agents.count) agents")
            
        } catch {
            print("RegistryService: Error loading agents: \(error)")
            self.agentsError = error
            throw error
        }
        
        isLoadingAgents = false
    }
    
    // MARK: - Utility Methods
    
    public func getAvailableTools() -> [Tool] {
        return tools.filter { $0.isAvailable }
    }
    
    public func getAvailableAgents() -> [Agent] {
        return agents.filter { $0.isAvailable }
    }
    
    public func getToolsByCategory(_ category: String) -> [Tool] {
        return tools.filter { $0.category.lowercased() == category.lowercased() }
    }
    
    public func searchTools(_ query: String) -> [Tool] {
        let lowercaseQuery = query.lowercased()
        return tools.filter { tool in
            tool.name.lowercased().contains(lowercaseQuery) ||
            tool.description.lowercased().contains(lowercaseQuery) ||
            tool.capabilities.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    public func searchAgents(_ query: String) -> [Agent] {
        let lowercaseQuery = query.lowercased()
        return agents.filter { agent in
            agent.name.lowercased().contains(lowercaseQuery) ||
            agent.description.lowercased().contains(lowercaseQuery) ||
            agent.capabilities.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    // MARK: - Categories
    
    public func getToolCategories() -> [String] {
        return Array(Set(tools.map { $0.category })).sorted()
    }
    
    public func getToolScopes() -> [String] {
        return Array(Set(tools.map { $0.scope })).sorted()
    }
    
    // MARK: - Refresh All
    
    public func refreshAll() async throws {
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.loadTools(refresh: true)
            }
            
            group.addTask {
                try await self.loadAgents(refresh: true)
            }
            
            for await _ in group {}
        }
    }
}