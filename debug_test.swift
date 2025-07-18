import Foundation

// Test the JSON decoding with the exact response from the logs
let jsonString = """
{
  "data": {
    "tools": [
      {
        "name": "createContainer",
        "description": "Create a new container with specified configuration",
        "category": "Container Management",
        "scope": "primitive",
        "parameters": {
          "properties": {
            "environment": {
              "description": "Environment variables",
              "type": "object"
            },
            "image": {
              "description": "Container image",
              "type": "string"
            },
            "mounts": {
              "description": "Volume mounts",
              "type": "array"
            },
            "name": {
              "description": "Container name",
              "type": "string"
            }
          },
          "required": ["image", "name"],
          "type": "object"
        },
        "capabilities": ["container_operations"],
        "security_level": "Elevated",
        "source": {
          "type": "builtin"
        },
        "version": "1.0.0",
        "is_available": true
      }
    ],
    "total_count": 22
  }
}
"""

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        default:
            try container.encodeNil()
        }
    }
}

struct ToolSource: Codable {
    let type: String
    let bundleId: String?
    let bundlePath: String?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case bundleId = "bundle_id"
        case bundlePath = "bundle_path"
    }
}

struct Tool: Codable {
    let name: String
    let description: String
    let category: String
    let scope: String
    let parameters: [String: AnyCodable]?
    let capabilities: [String]
    let securityLevel: String
    let source: ToolSource
    let version: String
    let isAvailable: Bool
    
    private enum CodingKeys: String, CodingKey {
        case name, description, category, scope, parameters, capabilities, source, version
        case securityLevel = "security_level"
        case isAvailable = "is_available"
    }
}

struct ToolRegistryData: Codable {
    let totalCount: Int
    let tools: [Tool]
    
    private enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case tools
    }
}

struct ToolRegistryResponse: Codable {
    let data: ToolRegistryData
}

// Test decoding
do {
    let jsonData = jsonString.data(using: .utf8)!
    let response = try JSONDecoder().decode(ToolRegistryResponse.self, from: jsonData)
    print("✅ Decoding successful!")
    print("Tools count: \(response.data.tools.count)")
    print("Total count: \(response.data.totalCount)")
} catch {
    print("❌ Decoding failed: \(error)")
}