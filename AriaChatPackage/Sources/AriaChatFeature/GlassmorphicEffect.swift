import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import QuartzCore

struct GlassmorphicModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var blurSettings: BlurSettings
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 22) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                // Use the custom glassmorphic view that properly implements blur
                GlassmorphicBackground(cornerRadius: cornerRadius, blurIntensity: blurSettings.blurIntensity)
            )
            .overlay(
                // Border: border-white/20
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

struct GlassmorphicBackground: NSViewRepresentable {
    let cornerRadius: CGFloat
    let blurIntensity: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        
        // Create custom blur effect view that supports dynamic blur radius
        let blurView = CustomBlurView()
        blurView.blurRadius = blurIntensity
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = cornerRadius
        blurView.layer?.masksToBounds = true
        
        // Create overlay view for glassmorphic tint
        let overlayView = NSView()
        overlayView.wantsLayer = true
        overlayView.layer?.cornerRadius = cornerRadius
        overlayView.layer?.masksToBounds = true
        
        // Set the tint color based on color scheme
        let tintColor = colorScheme == .dark
            ? NSColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 0.3)
            : NSColor(red: 1, green: 1, blue: 1, alpha: 0.3)
        overlayView.layer?.backgroundColor = tintColor.cgColor
        
        // Add subviews
        containerView.addSubview(blurView)
        containerView.addSubview(overlayView)
        
        // Setup constraints
        blurView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            overlayView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: containerView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update blur intensity
        if let blurView = nsView.subviews.first as? CustomBlurView {
            blurView.blurRadius = blurIntensity
        }
        
        // Update tint color if color scheme changes
        if let overlayView = nsView.subviews.last {
            let tintColor = colorScheme == .dark
                ? NSColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 0.3)
                : NSColor(red: 1, green: 1, blue: 1, alpha: 0.3)
            overlayView.layer?.backgroundColor = tintColor.cgColor
        }
    }
}

// Custom blur view that supports dynamic blur radius
class CustomBlurView: NSView {
    var blurRadius: CGFloat = 16.0 {
        didSet {
            needsDisplay = true
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layerUsesCoreImageFilters = true
        
        // Create visual effect view as base
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        
        addSubview(visualEffect)
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffect.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffect.topAnchor.constraint(equalTo: topAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Apply custom blur filter
        updateBlurFilter()
    }
    
    private func updateBlurFilter() {
        // Create gaussian blur filter with dynamic radius
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
        
        // Apply as background filter
        layer?.backgroundFilters = [blurFilter].compactMap { $0 }
    }
    
    override func updateLayer() {
        super.updateLayer()
        updateBlurFilter()
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let state: NSVisualEffectView.State
    let blurRadius: CGFloat
    
    init(material: NSVisualEffectView.Material, blendingMode: NSVisualEffectView.BlendingMode, state: NSVisualEffectView.State, blurRadius: CGFloat = 24) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.blurRadius = blurRadius
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.wantsLayer = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

struct InnerShadowModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 12) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.black.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .background(
                // Inner shadow effect using multiple overlays
                ZStack {
                    // Top inner highlight
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.1))
                        .offset(y: -1)
                        .blur(radius: 1)
                        .blendMode(.overlay)
                    
                    // Bottom inner shadow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.black.opacity(0.05))
                        .offset(y: 1)
                        .blur(radius: 1)
                        .blendMode(.multiply)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
    }
}

extension View {
    func glassmorphic(cornerRadius: CGFloat = 22) -> some View {
        self.modifier(GlassmorphicModifier(cornerRadius: cornerRadius))
    }
    
    func innerShadow(cornerRadius: CGFloat = 12) -> some View {
        self.modifier(InnerShadowModifier(cornerRadius: cornerRadius))
    }
}

// Remove duplicate color extensions - they're now in ColorExtensions.swift

// Apple-style shadow matching SWIFT2.md spec exactly
struct AppleShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            // Primary shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.05)
            .shadow(color: Color.black.opacity(0.05), radius: 12.5, x: 0, y: 10)
            // Secondary shadow: 0 8px 10px -6px rgba(0, 0, 0, 0.04)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 4)
    }
}

// Small Apple shadow for task items as per SWIFT2.md
struct AppleShadowSmall: ViewModifier {
    func body(content: Content) -> some View {
        content
            // Primary: 0 1px 2px 0 rgba(0, 0, 0, 0.03)
            .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
            // Secondary: 0 1px 1px 0 rgba(0,0,0,0.02)
            .shadow(color: Color.black.opacity(0.02), radius: 0.5, x: 0, y: 1)
    }
}

extension View {
    func appleShadow() -> some View {
        self.modifier(AppleShadow())
    }
    
    func appleShadowSmall() -> some View {
        self.modifier(AppleShadowSmall())
    }
}