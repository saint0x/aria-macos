# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **Aria Swift**, a native macOS application that provides a floating, glassmorphic chat interface for the Aria AI platform. Built with Swift and SwiftUI, it requires macOS 14.0+ and uses no external dependencies.

## Development Commands

**Build and Run:**
- Open `AriaChat.xcworkspace` in Xcode to build and run
- Build from command line: `xcodebuild -workspace AriaChat.xcworkspace -scheme AriaChat build`
- Run tests: `xcodebuild -workspace AriaChat.xcworkspace -scheme AriaChat test`

**Project Structure:**
- Main app target: `AriaChat/`
- Core functionality: `AriaChatPackage/Sources/AriaChatFeature/`
- Tests: `AriaChatPackage/Tests/` and `AriaChatUITests/`
- Build config: `Config/*.xcconfig`

## Architecture

**Application Flow:**
1. `AriaChatApp.swift` - Main entry point
2. `AppDelegate.swift` - Creates borderless floating window with custom positioning
3. `GlassmorphicChatbar.swift` - Main chat interface with blur effects and transparency

**Key Services:**
- `ChatService.swift` - Orchestrates chat functionality and coordinates other services
- `RESTAPIClient.swift` - HTTP API communication with Aria backend
- `StreamingClient.swift` - Server-Sent Events for real-time AI responses
- `SessionManager.swift` - Manages persistent chat sessions
- `TaskManager.swift` - Handles task lifecycle and status tracking

**Data Flow:**
- API calls go through defined endpoints in `APIEndpoints.swift`
- Models defined in `Models.swift` (EnhancedStep, TaskStatus) and `APIModels.swift`
- Message visibility controlled by `MessageFilterUtils.swift` and `MessageVisibilityManager.swift`

**UI Architecture:**
- SwiftUI-based with custom glassmorphic design
- Floating window that stays above other applications
- Message filtering based on metadata and step types
- Status indicators and real-time updates through streaming

## Key Technical Details

**Window Management:**
- Creates transparent, borderless window via `AppDelegate`
- Floating behavior that can appear above other apps
- Custom positioning and glassmorphic visual effects

**API Integration:**
- Communicates with Aria API server using REST + SSE
- Session persistence across app launches
- Task management with status tracking
- Message streaming with intelligent filtering

**Message System:**
- Complex message visibility rules in `MessageFilterUtils.swift`
- Real-time message updates via Server-Sent Events
- Graceful fallback for incomplete server responses
- Message formatting and presentation handled by dedicated utilities

**Testing:**
- Unit tests for core functionality in `AriaChatPackage/Tests/`
- UI tests in `AriaChatUITests/`
- Test plan defined in `AriaChat.xctestplan`