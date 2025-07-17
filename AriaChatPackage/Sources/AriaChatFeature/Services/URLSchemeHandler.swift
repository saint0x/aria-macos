import Foundation
import AppKit

/// Handles URL scheme registration and processing for aria:// URLs
@MainActor
public final class URLSchemeHandler {
    public static let shared = URLSchemeHandler()
    
    private init() {}
    
    /// Register the aria:// URL scheme with the system
    /// Note: For this to work permanently, you need to add the URL scheme to Info.plist
    /// Since this project uses GENERATE_INFOPLIST_FILE=YES, you may need to manually add:
    /// CFBundleURLTypes array with CFBundleURLName and CFBundleURLSchemes
    public func registerURLScheme() {
        // Register this app as handler for aria:// URLs
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.aria.chat"
        let urlScheme = "aria"
        
        // Create URL for the scheme
        guard URL(string: "\(urlScheme)://") != nil else { return }
        
        // Register as default handler
        LSSetDefaultHandlerForURLScheme(urlScheme as CFString, bundleIdentifier as CFString)
        
        print("URLSchemeHandler: Registered \(urlScheme):// scheme for bundle: \(bundleIdentifier)")
    }
    
    /// Handle incoming URL from the system
    public func handleURL(_ url: URL) {
        print("URLSchemeHandler: Processing URL: \(url)")
        
        guard url.scheme == "aria" else {
            print("URLSchemeHandler: Ignoring non-aria URL")
            return
        }
        
        switch url.host {
        case "auth-success":
            handleAuthSuccess(url)
        default:
            print("URLSchemeHandler: Unknown aria URL host: \(url.host ?? "nil")")
        }
    }
    
    private func handleAuthSuccess(_ url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let token = components?.queryItems?.first(where: { $0.name == "token" })?.value else {
            print("URLSchemeHandler: No token found in auth success URL")
            return
        }
        
        print("URLSchemeHandler: Processing auth success with token: \(token.prefix(20))...")
        
        Task { @MainActor in
            print("URLSchemeHandler: Starting authentication callback processing")
            await AuthenticationManager.shared.handleAuthCallback(token: token)
            print("URLSchemeHandler: Authentication callback completed")
        }
    }
}

/// Info.plist configuration note for developers:
/// 
/// To properly register the aria:// URL scheme, add this to your Info.plist
/// (or create a custom Info.plist and set GENERATE_INFOPLIST_FILE=NO):
///
/// <key>CFBundleURLTypes</key>
/// <array>
///     <dict>
///         <key>CFBundleURLName</key>
///         <string>Aria Authentication</string>
///         <key>CFBundleURLSchemes</key>
///         <array>
///             <string>aria</string>
///         </array>
///         <key>CFBundleURLIconFile</key>
///         <string>AppIcon</string>
///     </dict>
/// </array>