# SWIFT.MD: macOS Native Application Porting Guide

## 1. Introduction

### 1.1. Purpose
This document serves as the definitive guide for porting the existing macOS-inspired web application (internally referred to as "macos app prod" or "glassmorphic-chatbar project") to a fully native macOS application using Swift and modern Apple frameworks.

### 1.2. Goal
The primary goal is to achieve a **pixel-perfect and behaviorally identical recreation** of the current web application's UI, UX, animations, and core functionality. Every nuance of the existing design, from glassmorphism to subtle animations and interaction flows, must be preserved.

### 1.3. Target Frameworks
-   **UI:** SwiftUI will be the primary framework for building the user interface due to its modern, declarative approach.
-   **Windowing/Advanced Customization:** AppKit may be leveraged where SwiftUI's capabilities are insufficient for specific low-level window manipulations or custom control needs (e.g., achieving a truly frameless window with custom traffic lights if necessary, though SwiftUI is increasingly capable).
-   **Concurrency:** Swift Concurrency (async/await).
-   **Networking:** Swift gRPC for communication with the Aria Runtime backend.
-   **Animations:** SwiftUI's built-in animation system, potentially augmented with Core Animation for highly custom effects if needed.

### 1.4. Core Principles for Porting
-   **Fidelity First:** Visual and interactive accuracy is paramount.
-   **Native Performance:** Leverage native capabilities for a smooth and responsive experience.
-   **Maintainability:** Structure the Swift code logically, mirroring the component-based architecture of the original application where sensible.

## 2. Core Application Shell & Window

### 2.1. Main Window Configuration
-   **Appearance:** The main application window should be a single, non-resizable (initially, or with defined min/max sizes that match the web app's behavior) window.
-   **Frameless Design:**
    -   The window should appear frameless, without a standard macOS title bar.
    -   Traffic light buttons (close, minimize, zoom) should be custom-placed or hidden if the design implies a completely custom chrome. Given the current web app's focus on the chatbar, a fully frameless approach where the chatbar *is* the window content seems likely.
    -   SwiftUI: Use `.windowStyle(.hiddenTitleBar)` and potentially `.windowToolbarStyle(.unifiedCompact)` or further AppKit customization via `NSWindowDelegate`.
-   **Background Image:**
    -   The static nature image (`https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-C3FgrzHdNMQh9mTRQ17pCq4eCvXCfG.png`) must be displayed as the window's background, covering the entire window area.
    -   SwiftUI: An `Image` view scaled to fill (`.scaledToFill()`) as the base layer of the window's content.
-   **Initial State:** The window should launch displaying the `GlassmorphicChatbar` in its compact state, centered on the screen or at a defined default position.

### 2.2. Window Behavior
-   **Activation/Deactivation:** Standard macOS window activation behavior.
-   **Centering:** The `GlassmorphicChatbar` (and its expanded form) should effectively be the main content, centered within this background.
-   **No Standard Title Bar Content:** All controls and information are part of the `GlassmorphicChatbar` or its child views.

## 3. GlassmorphicChatbar - Main UI (`components/glassmorphic-chatbar.tsx`)

This is the central and most critical UI element. Its Swift counterpart must replicate every detail.

### 3.1. Overall Structure & Appearance
-   **Container:** A `View` that dynamically changes its height based on whether it's `compact` or `expanded`.
    -   SwiftUI: Use `@State` for `isExpanded` and animate height changes.
-   **Glassmorphism (Backdrop Blur):**
    -   The entire chatbar background must have a frosted glass effect, blurring the main window's background image.
    -   The blur intensity is dynamic, controlled by a global setting (see SettingsView). Default: 16px.
    -   SwiftUI: Apply `.background(.ultraThinMaterial)` or a thicker material if needed. For dynamic blur radius, this is tricky in pure SwiftUI.
        -   Option 1 (Simpler, Fixed Materials): Use standard materials and accept their fixed blur.
        -   Option 2 (Complex, AppKit): Use `NSVisualEffectView` wrapped in `NSViewRepresentable` for precise control over `maskImage` and potentially blur radius if private APIs are acceptable or if future macOS versions expose this. The `blurIntensity` from `useBlur` context needs to be mapped.
-   **Rounded Corners:** Consistent rounded corners (Tailwind `rounded-2xl`, maps to `var(--radius) + 10px` which is `0.75rem + 10px`). Convert rem to points (e.g., 1rem = 16pt).
    -   SwiftUI: `.cornerRadius(value)`.
-   **Borders:** Subtle border (Tailwind `border-white/20`).
    -   SwiftUI: `.overlay(RoundedRectangle(cornerRadius: value).stroke(Color.white.opacity(0.2), lineWidth: 1))`.
-   **Shadows:** Apple-style shadow (Tailwind `shadow-apple-xl`).
    -   SwiftUI: `.shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 25)` and a secondary shadow for the finer detail: `.shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 10)`. These values need to be tuned to match.
-   **Subtle Highlights/Lowlights:**
    -   Top edge: `h-px bg-gradient-to-r from-transparent via-white/30 to-transparent`.
    -   Bottom edge: `h-px bg-gradient-to-r from-transparent via-black/5 to-transparent`.
    -   SwiftUI: Achievable with `LinearGradient` overlays of 1pt height.

### 3.2. Compact State (Initial State)
-   **Height:** Auto-sized to fit the input area and bottom controls.
-   **Content:**
    1.  Input Area (see 3.3).
    2.  Bottom Controls Bar (see 3.4).

### 3.3. Expanded State
-   **Height:** Fixed height (e.g., `450px` from web).
    -   SwiftUI: Animate this height change using `withAnimation`.
-   **Content:**
    1.  Input Area.
    2.  Content Display Area (AI Chat Flow or Selected View - see Section 5).
    3.  Bottom Controls Bar.
-   **Transition:** Smooth animation for height change and content appearance (Tailwind `animate-slide-up-fade` for content).
    -   SwiftUI: `.transition(.asymmetric(insertion: .offset(y: 10).combined(with: .opacity), removal: .offset(y: 8).combined(with: .opacity)))` for content, combined with height animation.

### 3.4. Input Area (`px-3.5 pt-3.5 pb-2.5`)
-   **Wrapper:** A `View` with inner glassmorphism and shadow.
    -   Styling: `bg-white/20 dark:bg-neutral-700/20 shadow-apple-inner rounded-xl px-3 py-2.5`.
    -   SwiftUI: Another layer of `.background(.ultraThinMaterial.opacity(0.2))` or similar, `.cornerRadius()`, and custom inner shadow (can be faked with careful gradient overlays or a more complex drawing).
-   **Input Field (`HTMLInputElement`):**
    -   SwiftUI: `TextField`.
    -   **Placeholder:** Dynamic. Default: "Ask me anything...". If a tool is active: "Using [Tool Name]...". If no tool: "Type your message...".
        -   SwiftUI: `TextField(dynamicPlaceholderText, text: $inputValue)`.
    -   **Value:** Bound to an `@State var inputValue: String`.
    -   **Styling:** Transparent background, text color matching web (Tailwind `text-neutral-800 dark:text-neutral-100`, `placeholder:text-neutral-600 dark:placeholder:text-neutral-400/80`).
        -   SwiftUI: `.textFieldStyle(.plain)`, `.background(.clear)`, custom font and color.
    -   **Focus:** Should auto-focus when the chatbar appears or a new task is started.
        -   SwiftUI: Use `@FocusState`.
    -   **Disabled State:** Disabled when `isProcessing` is true.
        -   SwiftUI: `.disabled(isProcessing)`.
    -   **Submission:**
        -   On Enter key: `onSubmit` modifier on `TextField`.
        -   Triggers `handleSubmit` function.
-   **Send Button (`SendIcon`):**
    -   Appears only if `inputValue` is not empty AND `isProcessing` is false.
    -   Icon: `SendIcon` (Lucide). Use SF Symbols equivalent (e.g., `paperplane.fill`).
    -   Action: Triggers `handleSubmit`.
    -   Styling: `ml-2 p-1 rounded-md hover:bg-black/10 dark:hover:bg-white/10 text-neutral-700 dark:text-neutral-300`.
        -   SwiftUI: `Button` with `Image(systemName: "paperplane.fill")`, custom styling for hover (using `.onHover` and state).

### 3.5. Bottom Controls Bar (`px-3 py-2 border-t`)
-   **Layout:** Horizontal `HStack` with three main elements, space-between.
-   **Border:** Top border `border-black/10 dark:border-white/10`.
    -   SwiftUI: Add a 1pt `Divider` or an overlay.
-   **"Tools" Dropdown Button:**
    -   Label: "Tools" or `activeTool.name` if a tool is selected.
    -   Icon: `ChevronDownIcon` (SF Symbol: `chevron.down`).
    -   Action: Toggles `isToolMenuOpen` state.
    -   Styling: Matches web (`text-neutral-800 dark:text-neutral-200 hover:bg-black/5 ...`).
    -   SwiftUI: `Button` with `HStack { Text(label); Image(systemName: "chevron.down") }`. Custom `ButtonStyle` for hover effects.
-   **"New Task" Button:**
    -   Label: "New Task".
    -   Action: Calls `handleNewTask` function.
        -   `handleNewTask` logic:
            -   Resets `aiSteps` to initial (empty).
            -   Clears `inputValue`.
            -   Resets `activeHighlightId`.
            -   Sets `showAiChatFlow = true`.
            -   Sets `expanded = true`.
            -   Resets `selectedItemForDetail`.
            -   Resets `activeTool`.
            -   Requests focus for the input field.
            -   **gRPC Call:** `SessionService.CreateSession` to get a new `session_id`.
    -   Styling: Matches web (`text-neutral-700 dark:text-neutral-300 hover:text-neutral-900 ...`).
    -   SwiftUI: `Button { Text("New Task") }`. Custom `ButtonStyle`.
-   **"Views" Dropdown / Toggle Button:**
    -   **Behavior:**
        -   If `showAiChatFlow` is true: Label is "Task View". Action: Sets `activeView` to "TaskListView", sets `showAiChatFlow = false`.
        -   If `showAiChatFlow` is false: Label is `activeView.name` (truncated if long). Action: Toggles `isViewMenuOpen` state.
    -   Icon: `ChevronDownIcon` (SF Symbol: `chevron.down`).
    -   Styling: Matches web.
    -   SwiftUI: `Button` with dynamic label and action.

### 3.6. `handleSubmit` Logic
1.  Prevent submission if `inputValue` is empty or `isProcessing` is true.
2.  Set `expanded = true`.
3.  Set `showAiChatFlow = true`.
4.  Create `EnhancedStep` for user message, add to `aiSteps`, set as `activeHighlightId`.
5.  Clear `inputValue`.
6.  **Simulated AI Processing (to be replaced by gRPC `ExecuteTurn`):**
    -   Set `isProcessing = true`, `processingComplete = false`.
    -   Add "Synthesizing response..." thought step.
    -   Add "Querying knowledge base..." tool step.
    -   Mark tool step as completed.
    -   Add "Analyzing patterns..." tool step.
    -   Mark tool step and thought step as completed.
    -   Add final AI response step.
    -   Set `isProcessing = false`, `processingComplete = true`.
    -   Scroll chat to bottom.
7.  **Actual gRPC Call (`SessionService.ExecuteTurn`):**
    -   Send `session_id` and `inputValue`.
    -   Stream `TurnOutput` events.
    -   For each event:
        -   `Message`: Create/update `EnhancedStep` (USER_MESSAGE, RESPONSE, THOUGHT).
        -   `ToolCall`: Create `EnhancedStep` (TOOL, status: ACTIVE).
        -   `ToolResult`: Update corresponding tool `EnhancedStep` (status: COMPLETED/FAILED).
        -   `final_response`: Create final `EnhancedStep` (RESPONSE, status: COMPLETED).
    -   Update `aiSteps`, `activeHighlightId`, `isProcessing`, `processingComplete` accordingly.

## 4. Dropdown Menus (`components/shared/dropdown-menu.tsx`)

Used for "Tools" and "Views".

### 4.1. Appearance & Behavior
-   **Trigger:** Associated button in the Bottom Controls Bar.
-   **Positioning:** Appears below and aligned to the anchor button (or container edge).
    -   SwiftUI: Use `.popover` or a custom view modifier that calculates frame and presents a new view.
-   **Glassmorphism:** Same backdrop blur as the chatbar.
    -   SwiftUI: `.background(.ultraThinMaterial)` for the popover content.
-   **Styling:** Rounded corners, border, shadow (matches `shadow-apple-xl`).
    -   SwiftUI: Modifiers on the popover content view.
-   **Animation:** `animate-expand-in` (scale and opacity).
    -   SwiftUI: `.transition(.scale.combined(with: .opacity))` on the popover.
-   **Content:** List of `MenuItem` objects.
    -   `MenuItem` structure: `id`, `name`, `action?`, `separator?`, `disabled?`.
-   **Item Styling:**
    -   Padding, text size/color.
    -   Hover effect (`hover:bg-black/5 dark:hover:bg-white/10`).
        -   SwiftUI: `.onHover` and state for background changes.
    -   Disabled state styling (opacity, no hover).
    -   Separators (`h-px bg-neutral-300/70 ...`).
        -   SwiftUI: `Divider()`.
-   **Scrolling:** If items exceed `MAX_VISIBLE_ITEMS` (4), content should scroll.
    -   SwiftUI: Wrap items in a `ScrollView` with a `.frame(maxHeight: ...)`.
-   **Dismissal:**
    -   Clicking an item.
    -   Clicking outside the menu.
    -   Pressing Escape key.

### 4.2. Swift Implementation
-   Create a reusable `DropdownMenuView<Item: Identifiable & Hashable>` struct.
-   `Item` protocol would require `id`, `name`, `isDisabled`, etc.
-   Use `@State` to control `isOpen`.
-   The menu content itself would be a `VStack` of `Button`s or custom styled `View`s.

## 5. Content Display Area (`expanded` chatbar state)

This area dynamically shows either the AI Chat Flow or one of the selected Views.

### 5.1. AI Chat Flow (`components/shared/agent-status-indicator.tsx`)
-   **Container:** A `ScrollView` that automatically scrolls to the bottom as new steps are added.
    -   SwiftUI: `ScrollViewReader` with `ScrollView` to use `.scrollTo()`.
-   **Rendering `EnhancedStep` items:**
    -   **`userMessage`:** Right-aligned, distinct background/styling.
    -   **`response`:** Left-aligned, plain text or subtle styling.
    -   **`thought` / `tool`:**
        -   **Layout:** Icon, Text, Chevron (if clickable).
        -   **Indentation:** `tool` steps are indented if `isIndented` is true and previous step allows (not user/response).
            -   SwiftUI: Use `padding(.leading, value)` or nested `HStack`s.
            -   Vertical connector line for indented items: Custom `Path` drawing or overlay.
        -   **Icon:**
            -   `thought`: Default dot or `brain` (if BrainCircuitIcon was used).
            -   `tool`: `ZapIcon` (SF Symbol: `bolt.fill` or `wand.and.stars`).
            -   Status overlay: `CheckIcon` (SF: `checkmark.circle.fill`), `Loader2` (SF: `arrow.triangle.2.circlepath`), `ZapIcon` (SF: `exclamationmark.triangle.fill`).
        -   **Text:** `step.text` or `toolName: step.text`. Styling based on `status` (active = bold).
        -   **Highlighting:** If `step.id == activeHighlightId`, apply a distinct background (`bg-neutral-100/70 dark:bg-neutral-700/50 shadow-apple-inner`).
        -   **Clickability:** If `onStepClick` is provided and type is `tool` or `thought`, the row is clickable, showing a `ChevronRightIcon` (SF: `chevron.right`). Action: Calls `onStepClick(step)`, which sets `selectedItemForDetail`.
-   **Animation:** `animate-slide-up-fade` for new steps.
    -   SwiftUI: Apply `.transition()` to items within a `ForEach` loop.

### 5.2. Views (`components/views/*.tsx`)
A container that switches its content based on `activeView.id`.

#### 5.2.1. TaskListView (`task-list-view.tsx`)
-   **Data Source:** `useTasks` hook (Tanstack Query).
    -   Swift: Async function fetching from gRPC `TaskService.ListTasks` (if added) or alternative source. Manage loading/error states.
-   **Loading State:** "Loading tasks..." with a spinner (`Loader2` -> SF: `arrow.triangle.2.circlepath`).
-   **Error State:** "Error loading tasks: [message]".
-   **Empty State:** "No tasks to display."
-   **Task Item Rendering:**
    -   Layout: Task Name, Status (dot + text), ChevronRight.
    -   Styling: `bg-white/20 dark:bg-neutral-700/20 hover:bg-white/30 ... shadow-apple-sm rounded-xl p-3`.
    -   **Status Dot & Text:** Colors based on `task.status` (from `getStatusDisplayInfo`).
        -   `getStatusDisplayInfo` logic needs to be ported to Swift.
    -   **Interaction:** Clicking a task item calls `onTaskSelect(task)`, which sets `selectedItemForDetail` with a synthetic `EnhancedStep` (e.g., `type: .thought, text: "TASK_DETAIL_\(task.id)"`).
-   **Animation:** `animate-slide-up-fade` for the list.

#### 5.2.2. LoggingView (`logging-view.tsx`)
-   **Data Source:** `useLogs` hook (Tanstack Query), filtered by `dateRange`.
    -   Swift: Async function fetching from gRPC `TaskService.StreamTaskOutput` or `ContainerService.StreamContainerLogs` or a new generic log stream. Date filtering would be a parameter to the gRPC call or client-side.
-   **Header:**
    -   Title: "Activity Logs".
    -   Timeframe Filter Dropdown:
        -   Label: `activeTimeframeLabel` (e.g., "7d").
        -   Icon: `ChevronDownIcon`.
        -   Action: Opens `DropdownMenuComponent` with items like "Last 24 hours", "Today", etc.
        -   Selection updates `dateRange` and `activeTimeframeLabel`.
-   **Log List Container:**
    -   Styling: `rounded-xl bg-white/20 dark:bg-neutral-700/20 shadow-apple-sm overflow-hidden`.
    -   Scrollable: Custom scrollbar hidden.
-   **Sticky Header Row (for log columns):** Timestamp, Level, Source, Message.
    -   Styling: `bg-white/60 dark:bg-neutral-800/60 backdrop-blur-sm`.
-   **Log Entry Row (`LogEntryRow` component):**
    -   Layout: Condensed Timestamp, Level, Source, Message, Expand Chevron (if `details` exist).
    -   **Timestamp:** Condensed form (`MMM d`), full form in tooltip (`MMM d, yyyy, HH:mm:ss.SSS`).
        -   SwiftUI: Use `Text(date, style: .date)` and `.hoverEffect(.content)` for tooltip or custom popover.
    -   **Level:** Formatted (e.g., "Info") and color-coded.
    -   **Source & Message:** Truncated with full text on title/tooltip.
    -   **Interaction:** Clicking row (if `details` present) toggles `isExpanded` for that row.
-   **Expanded Details:**
    -   If `isExpanded`, show a `pre` block with `JSON.stringify(entry.details, null, 2)`.
    -   SwiftUI: `Text(jsonString)` in a monospace font, within a styled block.
-   **Loading, Error, Empty States:** Similar to TaskListView.
-   **Animation:** `animate-slide-up-fade` for the view.

#### 5.2.3. GraphView (`graph-view.tsx`)
-   Currently a placeholder: "Graph View Content Placeholder".
-   Swift: Simple `Text` view.

#### 5.2.4. BillingView (`billing-view.tsx`)
-   Static display of mock billing info: Current Plan, Renews On, Available Credits.
-   Text links: "Add Credits", "Upgrade Plan", "Cancel Plan".
-   Styling: `rounded-xl bg-white/20 dark:bg-neutral-700/20 shadow-apple-sm p-3.5`.
-   Swift: `VStack` and `HStack` with `Text` and `Button` (styled as links) elements.

#### 5.2.5. SettingsView (`settings-view.tsx`)
-   **Layout:** Accordion-based.
    -   SwiftUI: `List` with `DisclosureGroup` for accordion items.
-   **Accordion Item Styling:** `border-none rounded-xl bg-white/20 dark:bg-neutral-700/20 shadow-apple-sm`.
-   **Sections:**
    -   **Model Configuration:**
        -   AI Model Select: `Select` component (maps to SwiftUI `Picker`).
            -   Picker items grouped by provider (OpenAI, Anthropic, Google, xAI).
            -   Custom styling for Picker and its items to match glassmorphic theme.
        -   System Prompt File: `Button` to trigger file picker, displays selected file name.
            -   SwiftUI: `Button` that uses `.fileImporter` modifier.
    -   **Utility Management:**
        -   Sub-sections for Tools, Agents, Team, Pipelines.
        -   Each lists items with a delete button (`Trash2Icon` -> SF: `trash`).
        -   SwiftUI: `ForEach` over data arrays, `Button` for delete.
    -   **Visual Settings:**
        -   Backdrop Blur Slider: `Slider` component (maps to SwiftUI `Slider`).
            -   Label and current value display.
            -   Custom track/thumb styling to match (`apple-blue`).
            -   Updates global `blurIntensity` state.
        -   Interface Theme Select: `Select` component (maps to SwiftUI `Picker`).
            -   Options: Light, Dark, System.
            -   Updates theme (SwiftUI: `.preferredColorScheme()`).
-   **Animation:** `animate-slide-up-fade` for the view.

## 6. StepDetailPane (`components/shared/step-detail-pane.tsx`)

### 6.1. Appearance & Behavior
-   **Trigger:** Clicking a qualifying step in `AgentStatusIndicator` or a task in `TaskListView`.
-   **Animation:** Slides in from the right of the `GlassmorphicChatbar`. `animate-slide-in-from-right` / `animate-slide-out-to-right`.
    -   SwiftUI: Appears as an overlay or adjacent view, use `.transition(.move(edge: .trailing).combined(with: .opacity))`.
-   **Positioning:** Absolutely positioned relative to the main chatbar.
-   **Dimensions:** `w-full max-w-xs h-[450px]`.
-   **Glassmorphism:** Same backdrop blur as chatbar.
-   **Styling:** Rounded corners, border, shadow (matches `shadow-apple-xl`).
-   **Header:**
    -   Title: Dynamic (Step text, Tool name, or Task name, truncated if long).
    -   Close Button (`XIcon` -> SF: `xmark`): Calls `onClose`.
-   **Content Area:** Scrollable, accordion-based.
    -   **Accordion Items (DisclosureGroups):**
        1.  "Input" / "Task Details"
        2.  "Thinking Process" / "Progress & Status"
        3.  "Output" / "Additional Info"
    -   Content of each section is dynamic based on `StepDetailsContent` (rich text or JSON).
        -   `getStepDetailsContent` logic needs to be ported to Swift.
-   **Footer:**
    -   Status Bar: Displays task status (e.g., "Status: Completed" with icon) or AI step status.
    -   View Mode Toggle Button: "View JSON" / "View Rich Text". Toggles display of accordion content between formatted text and raw JSON.
        -   JSON display: Monospaced font, pretty-printed.

### 6.2. Swift Implementation
-   A separate `View` struct, conditionally presented.
-   State to manage `selectedStep` and derived `detailsContent`.
-   Use `DisclosureGroup` for accordions.
-   JSON pretty-printing: `JSONSerialization` then `String(data:encoding:)`.

## 7. ToolUploadSuccessDisplay (`components/shared/tool-upload-success-display.tsx`)

### 7.1. Appearance & Behavior
-   **Trigger:** Appears when a "custom tool is uploaded successfully" (mechanism for this TBD, likely via `NotificationService.BundleUploadEvent`).
-   **Visibility:** Only shown when `GlassmorphicChatbar` is NOT expanded.
-   **Positioning:** Below the compact chatbar.
-   **Animation:** `animate-expand-in`.
-   **Glassmorphism:** Same backdrop blur.
-   **Styling:** Rounded corners, border, shadow, padding.
-   **Content:** `CheckCircle2Icon` (SF: `checkmark.circle.fill`, green color) + Message text.

### 7.2. Swift Implementation
-   A `View` struct, conditionally presented based on chatbar expansion state and a success flag.

## 8. Styling and Theming

### 8.1. Recreating Glassmorphism
-   Primary method: SwiftUI's material backgrounds (`.background(.thinMaterial)`, `.ultraThinMaterial)`, etc.).
-   For precise blur radius control (if standard materials are insufficient): `NSVisualEffectView` via `NSViewRepresentable`. This is complex and adds AppKit dependency. The `blurIntensity` state variable (0-40px) needs to be mapped to the chosen implementation.

### 8.2. Color Palette
-   Map Tailwind color definitions (e.g., `apple-gray-100`, `apple-blue`) to `Color` assets in Xcode or custom `Color` extensions in Swift.
-   Ensure all opacities (e.g., `rgba(242, 242, 247, 0.8)`) are correctly applied.
    -   SwiftUI: `Color.red.opacity(0.8)`.

### 8.3. Shadows, Radii, Borders
-   Translate Tailwind utility classes to SwiftUI modifiers:
    -   `rounded-xl`, `rounded-2xl`: `.cornerRadius(value)`.
    -   `shadow-apple-sm`, `shadow-apple-md`, etc.: `.shadow(color:radius:x:y:)`. Multiple shadows may be needed for complex effects.
    -   `border-white/20`: `.overlay(RoundedRectangle().stroke())`.

### 8.4. Typography
-   Default font: `-apple-system` (SF Pro). This is default in SwiftUI.
-   Font sizes (e.g., `text-xs`, `text-sm`) map to SwiftUI `.font(.system(size: ...))` or `.font(.caption)`, `.font(.footnote)`.
-   Font weights (e.g., `font-medium`) map to `.fontWeight(.medium)`.
-   Text colors: Apply mapped `Color` values.

### 8.5. Light/Dark Mode
-   Leverage SwiftUI's automatic adaptation to system appearance.
-   Ensure custom colors are defined for both light and dark appearances in the Asset Catalog or dynamically chosen in code.
-   The `ThemeProvider` from `next-themes` (allowing user override: Light, Dark, System) needs a Swift equivalent.
    -   Store user preference (e.g., `UserDefaults`).
    -   Apply `.preferredColorScheme()` modifier at the root of the app.

## 9. Animations

### 9.1. General Approach
-   Use SwiftUI's implicit animations (`.animation(.default, value: observedState)`) and explicit animations (`withAnimation { ... }`).
-   Match easing curves and durations from Tailwind/Framer Motion (`gentleTransition`, `cubic-bezier(0.25, 1, 0.5, 1)`).
    -   SwiftUI: `Animation.timingCurve(c0x, c0y, c1x, c1y, duration: ...)`.
    -   `gentleTransition` (spring): `Animation.spring(response:dampingFraction:blendDuration:)` - tune parameters.

### 9.2. Key Animations to Recreate:
-   **`expand-in` (Dropdowns, ToolUploadSuccessDisplay):** Scale + Opacity.
    -   SwiftUI: `.transition(.scale.combined(with: .opacity))`.
-   **`slide-up-fade` (Content in expanded chatbar, views):** Offset Y + Opacity.
    -   SwiftUI: `.transition(.asymmetric(insertion: .offset(y: 10).combined(with: .opacity), removal: .offset(y: 8).combined(with: .opacity)))`.
-   **`subtle-pulse`:** Not explicitly used in core components but defined.
-   **`slide-in-from-right` / `slide-out-to-right` (StepDetailPane):** Offset X + Opacity.
    -   SwiftUI: `.transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))`.
-   **Chatbar Height Animation:** Animate the `.frame(height: ...)` modifier.
-   **List Item Animations (AgentStatusIndicator, TaskListView):** Apply transitions to items within `ForEach`.

## 10. State Management Strategy

### 10.1. SwiftUI State Primitives
-   `@State`: For transient, view-local UI state (e.g., `isToolMenuOpen`, `inputValue`).
-   `@StateObject` / `@ObservedObject`: For reference type model objects that manage more complex state or business logic (e.g., a view model for `LoggingView` that handles data fetching and filtering).
-   `@EnvironmentObject`: For global state accessible throughout the view hierarchy (e.g., `BlurSettings`, `ThemeSettings`, `SessionManager`).
-   `@Environment`: For accessing system-provided values (e.g., color scheme, focus state).

### 10.2. Global State
-   **Blur Intensity:**
    -   Create an `ObservableObject` class, e.g., `VisualSettings`, holding `blurIntensity`.
    -   Provide it via `.environmentObject()` at the app's root.
    -   Accessed in `SettingsView` (slider) and any view applying the glassmorphic effect.
-   **Theme:**
    -   Similar `ObservableObject` for `currentTheme` (light, dark, system).
    -   Used with `.preferredColorScheme()`.
-   **Current Session ID:**
    -   Likely managed by a `SessionManager` (`ObservableObject`) responsible for `CreateSession` calls and holding the active `session_id`.

### 10.3. Data Fetching & Caching (Tanstack Query Equivalent)
-   No direct Swift equivalent of Tanstack Query.
-   Implement data fetching logic within `ObservableObject` view models or dedicated service classes.
-   Use `async/await` for gRPC calls.
-   Publish results using `@Published` properties to drive UI updates.
-   Caching: Implement custom caching logic if needed (e.g., `NSCache` or simple in-memory storage for short-lived data). For tasks/logs, freshness is key, so frequent refetching or streaming updates via gRPC are preferred.

## 11. Data Handling & Types

### 11.1. Translating TypeScript Types to Swift
-   `lib/types.ts` is the source of truth.
-   **Enums:** TypeScript `enum` -> Swift `enum` (often with `String` raw values if they map to backend strings).
    -   E.g., `LogLevel` -> `enum LogLevel: String, Codable, CaseIterable { case INFO, WARN, ... }`.
-   **Interfaces:** TypeScript `interface` -> Swift `struct` (prefer value types) or `class` (if reference semantics or inheritance needed).
    -   Make them `Codable` if they need to be serialized/deserialized (e.g., for mock data or local storage).
    -   Make them `Identifiable` for use in SwiftUI `ForEach` loops.
    -   E.g., `LogEntry` interface -> `struct LogEntry: Identifiable, Codable { ... }`.
    -   Handle optional fields (`?`) with Swift optionals (`Type?`).
    -   `Record<string, any>` -> `[String: AnyCodable]` or a more specific type if possible.
    -   Dates (`string` ISO): Use `Date` in Swift, with `ISO8601DateFormatter` for conversion.

### 11.2. gRPC Client Setup
-   Use a Swift gRPC library (e.g., `grpc-swift`).
-   Generate Swift client code from the `.proto` files (`aria.proto`, `notification_service.proto`, etc.).
-   Create service classes/clients in Swift to encapsulate gRPC calls for each service (`NotificationServiceClient`, `TaskServiceClient`, etc.).
-   Connect to the Unix Domain Socket: `ClientConnection.secure(group: eventLoopGroup).connect(unixDomainSocketPath: socketPath)`.

### 11.3. Mock Data
-   Translate `lib/data/mock-logs.ts` and `mock-tasks.ts` into Swift structures, perhaps loaded from JSON files in the app bundle during development.

## 12. gRPC Integration Details (Summary)

Refer to `INTEGRATION.json` for detailed mappings. Key interactions:

-   **`NotificationService.StreamNotifications`:** Maintain a persistent stream. Update UI for `BundleUploadEvent` and `TaskStatusEvent`.
-   **`SessionService.CreateSession`:** Called on "New Task" to get a `session_id`.
-   **`SessionService.ExecuteTurn`:** Core of chat. Stream `TurnOutput` to build `AgentStatusIndicator`.
-   **`TaskService.LaunchTask`:** Triggered by agent actions.
-   **`TaskService.GetTask`:** Populate `StepDetailPane` for tasks.
-   **`TaskService.StreamTaskOutput`:** Feed `LoggingView` or live task details.
-   **`TaskService.CancelTask`:** UI action to cancel tasks.
-   **`ContainerService`:** For future advanced tools/dev console.

## 13. Accessibility
-   **Labels:** Provide meaningful `.accessibilityLabel()` for all interactive elements.
-   **Values:** Use `.accessibilityValue()` for elements displaying dynamic data.
-   **Hints:** Use `.accessibilityHint()` to provide context.
-   **Traits:** Apply appropriate traits (e.g., `.isButton`, `.isHeader`).
-   **Focus Management:** Ensure logical focus order using `.accessibilitySortPriority()` and `@AccessibilityFocusState`.
-   **Dynamic Type:** Support Dynamic Type by using relative font sizes (e.g., `.font(.body)`) where possible.

## 14. Build and Packaging
-   Standard Xcode project setup for a macOS application.
-   Bundle the Swift gRPC runtime and generated client code.
-   Ensure the application can locate and connect to the `runtime.sock`.
-   Code signing and notarization for distribution.

## 15. Conclusion
Porting this application to native Swift/SwiftUI is a complex but achievable task. The key is a systematic approach, breaking down each web component and its behavior, and meticulously translating it using native macOS frameworks. Success hinges on rigorous attention to visual fidelity, interaction parity, and animation smoothness, all while leveraging the performance benefits of a native stack. This document provides the blueprint; careful execution will bring the vision to life.
