import SwiftUI

/// A view that renders markdown-formatted text with proper styling
struct MarkdownTextView: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text(attributedMarkdown)
            .font(.textSM)
            .foregroundColor(Color.textPrimary(for: colorScheme))
            .tint(Color.appleBlue) // Color for links
    }
    
    private var attributedMarkdown: AttributedString {
        do {
            var attributed = try AttributedString(
                markdown: text,
                options: AttributedString.MarkdownParsingOptions(
                    allowsExtendedAttributes: true,
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            )
            
            // Apply custom styling
            for run in attributed.runs {
                // Handle inline code
                if let intent = run.attributes.inlinePresentationIntent,
                   intent.contains(.code) {
                    attributed[run.range].font = .system(size: 13, design: .monospaced)
                    attributed[run.range].backgroundColor = colorScheme == .dark ?
                        Color(white: 0.2).opacity(0.5) :
                        Color(white: 0.95)
                    attributed[run.range].foregroundColor = colorScheme == .dark ?
                        Color(red: 0.9, green: 0.6, blue: 0.4) : // Orange for dark mode
                        Color(red: 0.5, green: 0.3, blue: 0.1) // Brown for light mode
                }
                
                // Handle links
                if run.attributes.link != nil {
                    attributed[run.range].underlineStyle = .single
                    attributed[run.range].foregroundColor = Color.appleBlue
                }
                
                // Handle bold
                if let intent = run.attributes.inlinePresentationIntent,
                   intent.contains(.stronglyEmphasized) {
                    attributed[run.range].font = .system(size: 14, weight: .semibold)
                }
                
                // Handle italic
                if let intent = run.attributes.inlinePresentationIntent,
                   intent.contains(.emphasized) {
                    attributed[run.range].font = .system(size: 14).italic()
                }
            }
            
            return attributed
        } catch {
            // Fallback to plain text if markdown parsing fails
            return AttributedString(text)
        }
    }
}

/// Extension to support code block rendering
extension View {
    /// Renders text with markdown support
    func markdownText(_ text: String) -> some View {
        MarkdownTextView(text: text)
    }
}

/// A more advanced markdown renderer that handles code blocks separately
struct AdvancedMarkdownView: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    private var segments: [MarkdownSegment] {
        parseMarkdown(text)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(segments) { segment in
                switch segment.type {
                case .text:
                    // Use MarkdownTextView for inline markdown support
                    MarkdownTextView(text: segment.content)
                        .multilineTextAlignment(.leading)
                        
                case .codeBlock:
                    CodeBlockView(code: segment.content, language: segment.language)
                        
                case .inlineCode:
                    // This case is now handled by MarkdownTextView
                    MarkdownTextView(text: "`\(segment.content)`")
                }
            }
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownSegment] {
        var segments: [MarkdownSegment] = []
        
        // Simple parser for code blocks
        let codeBlockPattern = "```(\\w*)\\n([^`]+)```"
        
        // First, extract code blocks
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []) {
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
            
            var lastEnd = 0
            for match in matches {
                // Add text before code block
                if lastEnd < match.range.location {
                    let textRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                    if let range = Range(textRange, in: text) {
                        let textContent = String(text[range])
                        if !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            segments.append(MarkdownSegment(type: .text, content: textContent))
                        }
                    }
                }
                
                // Add code block
                if let langRange = Range(match.range(at: 1), in: text),
                   let codeRange = Range(match.range(at: 2), in: text) {
                    let language = String(text[langRange])
                    let code = String(text[codeRange])
                    segments.append(MarkdownSegment(type: .codeBlock, content: code, language: language))
                }
                
                lastEnd = match.range.location + match.range.length
            }
            
            // Add remaining text
            if lastEnd < text.count {
                let remainingText = String(text.suffix(from: text.index(text.startIndex, offsetBy: lastEnd)))
                if !remainingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    segments.append(MarkdownSegment(type: .text, content: remainingText))
                }
            }
        } else {
            // No code blocks found, return as text
            segments.append(MarkdownSegment(type: .text, content: text))
        }
        
        return segments
    }
}

// MARK: - Supporting Types

struct MarkdownSegment: Identifiable {
    let id = UUID()
    let type: SegmentType
    let content: String
    var language: String?
    
    enum SegmentType {
        case text
        case codeBlock
        case inlineCode
    }
}

struct CodeBlockView: View {
    let code: String
    let language: String?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language label
            if let lang = language, !lang.isEmpty {
                HStack {
                    Text(lang)
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary(for: colorScheme))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(colorScheme == .dark ?
                    Color(white: 0.15) :
                    Color(white: 0.85))
            }
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color.textPrimary(for: colorScheme))
                    .padding(12)
            }
            .background(colorScheme == .dark ?
                Color(white: 0.1) :
                Color(white: 0.95))
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.borderColor(for: colorScheme), lineWidth: 1)
        )
    }
}