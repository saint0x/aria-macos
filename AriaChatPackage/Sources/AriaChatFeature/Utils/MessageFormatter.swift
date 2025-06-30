import Foundation

/// Formats messages for display, handling JSON, tool results, and other content types
enum MessageFormatter {
    
    /// Format a tool result for display
    static func formatToolResult(_ result: String?) -> String? {
        guard let result = result else { return nil }
        
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to parse as JSON and format nicely
        if let formatted = formatJSON(trimmed) {
            return formatted
        }
        
        // If not JSON, return as-is but cleaned up
        return trimmed.isEmpty ? nil : trimmed
    }
    
    /// Format a tool step for display
    static func formatToolStep(_ step: EnhancedStep) -> String {
        guard step.type == .tool else { return step.text }
        
        // Build the display text
        var parts: [String] = []
        
        // Tool name
        if let toolName = step.toolName {
            parts.append("used: \(toolName)")
        } else {
            parts.append("used: \(step.text)")
        }
        
        // Add status if not active
        if step.status != .active {
            parts.append("[\(step.status.rawValue)]")
        }
        
        return parts.joined(separator: " ")
    }
    
    /// Format JSON string into a readable format
    private static func formatJSON(_ jsonString: String) -> String? {
        // First check if it looks like JSON
        guard (jsonString.hasPrefix("{") && jsonString.hasSuffix("}")) ||
              (jsonString.hasPrefix("[") && jsonString.hasSuffix("]")) else {
            return nil
        }
        
        // Try to parse and format
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        
        // Convert to readable format
        return formatJSONObject(json, indent: 0)
    }
    
    /// Recursively format a JSON object
    private static func formatJSONObject(_ obj: Any, indent: Int) -> String {
        let indentString = String(repeating: "  ", count: indent)
        
        if let dict = obj as? [String: Any] {
            if dict.isEmpty { return "{}" }
            
            var lines: [String] = []
            for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
                let formattedValue = formatJSONValue(value, indent: indent + 1)
                lines.append("\(indentString)  \(key): \(formattedValue)")
            }
            
            if lines.count == 1 && lines[0].count < 60 {
                // Single line for short objects
                return "{ \(lines[0].trimmingCharacters(in: .whitespaces)) }"
            } else {
                return "{\n\(lines.joined(separator: ",\n"))\n\(indentString)}"
            }
        } else if let array = obj as? [Any] {
            if array.isEmpty { return "[]" }
            
            let items = array.map { formatJSONValue($0, indent: indent + 1) }
            
            if items.count == 1 && items[0].count < 60 {
                // Single line for short arrays
                return "[\(items[0])]"
            } else {
                let formattedItems = items.map { "\(indentString)  \($0)" }
                return "[\n\(formattedItems.joined(separator: ",\n"))\n\(indentString)]"
            }
        } else {
            return formatJSONValue(obj, indent: indent)
        }
    }
    
    /// Format a single JSON value
    private static func formatJSONValue(_ value: Any, indent: Int) -> String {
        if let str = value as? String {
            // Truncate long strings
            if str.count > 100 {
                return "\"\(str.prefix(97))...\""
            }
            return "\"\(str)\""
        } else if let bool = value as? Bool {
            return bool ? "true" : "false"
        } else if value is NSNull {
            return "null"
        } else if let dict = value as? [String: Any] {
            return formatJSONObject(dict, indent: indent)
        } else if let array = value as? [Any] {
            return formatJSONObject(array, indent: indent)
        } else {
            return "\(value)"
        }
    }
    
    /// Strip sensitive information from messages
    static func stripSensitiveInfo(_ text: String) -> String {
        var result = text
        
        // Remove API keys or tokens (common patterns)
        let patterns = [
            // API key patterns
            #"[a-zA-Z0-9_-]{20,}"#,
            // Bearer tokens
            #"Bearer\s+[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+"#,
            // Session IDs
            #"session[_-]?id[\"']?\s*[:=]\s*[\"']?[a-zA-Z0-9_-]+[\"']?"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(location: 0, length: result.count),
                    withTemplate: "[REDACTED]"
                )
            }
        }
        
        return result
    }
}