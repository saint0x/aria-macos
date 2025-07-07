TL;DR for Frontend Teams

  🖥️ macOS Team Requirements

  What you need to build:

  1. On App Install/First Launch:
    - Generate a cryptographically secure UUID v4 (magic number)
    - Store it in ~/aria/config.json:
  {
    "magic_number": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2025-01-05T10:00:00Z",
    "app_version": "1.0.0"
  }
  2. Sign In Button in App:
    - When clicked, open browser to:
  https://app.aria.dev/auth/login?magic={magic_number}
    - Start polling backend every 2 seconds: GET 
  /api/auth/magic-status?magic={magic_number}
    - Once linked (API returns {is_linked: true, user_email: "..."}) store the auth
  token
  3. After Authentication:
    - Store returned auth token in macOS Keychain
    - Include token in all API requests: Authorization: Bearer {token}
    - Subscribe to SSE notifications: GET /api/v1/notifications/stream (with auth
  header)
    - Show toast notifications when upload events arrive
  4. Optional: Deep Link Handler
    - Register aria:// URL scheme
    - Handle aria://auth-success?token={token} callback (eliminates polling)

    Full Version (Recommended)

  {
    "version": "1.0",
    "magic_number": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2025-01-05T10:00:00Z",
    "device_info": {
      "app_version": "1.0.0",
      "os_version": "macOS 14.2.1",
      "machine_id": "8A5B3C2D-1234-5678-9ABC-DEF012345678",
      "install_id": "inst_2025010510000000"
    },
    "auth": {
      "linked": true,
      "linked_at": "2025-01-05T10:30:00Z",
      "user_email": "user@example.com",
      "user_id": "usr_abc123",
      "access_token": "eyJhbGciOiJSUzI1NiIs...",
      "refresh_token": "rft_xyz789...",
      "expires_at": "2025-01-12T10:30:00Z"
    },
    "api": {
      "base_url": "https://api.aria.dev",
      "ws_url": "wss://api.aria.dev",
      "upload_endpoint": "/api/v1/bundles/upload"
    },
    "preferences": {
      "notifications": {
        "enabled": true,
        "sound": true,
        "badge": true
      },
      "auto_update": true,
      "telemetry": true,
      "theme": "system"
    },
    "cache": {
      "last_sync": "2025-01-05T11:00:00Z",
      "bundle_cache_dir": "~/aria/cache/bundles",
      "max_cache_size_mb": 500
    }
  }

  Key Sections Explained:

  1. Core Identity (magic_number, device_info)
  - magic_number: The unique device identifier
  - machine_id: Hardware identifier for additional security
  - install_id: Unique per installation (survives updates)

  2. Authentication (auth)
  - Stores tokens after successful OAuth flow
  - Tracks linking status for quick checks
  - Enables offline token refresh

  3. API Configuration (api)
  - Allows for environment switching (dev/staging/prod)
  - WebSocket URL for real-time features
  - Customizable endpoints

  4. User Preferences (preferences)
  - Notification settings for toast behavior
  - Update preferences
  - UI customization

  5. Cache Management (cache)
  - Local bundle caching for offline work
  - Sync timestamps for delta updates

  Security Considerations:

  What to Store:
  - ✅ Magic number (device-specific, not sensitive)
  - ✅ Refresh token (encrypted with macOS Keychain reference)
  - ✅ User email/ID (for display purposes)
  - ✅ API endpoints (configuration)

  What NOT to Store:
  - ❌ Passwords or secrets
  - ❌ Full access tokens (store in Keychain)
  - ❌ Payment information
  - ❌ Other users' data

  File Permissions:

  # Config file should be user-readable only
  chmod 600 ~/aria/config.json


----------------------------------------------------------------------------------------


  🌐 Landing Page Team Requirements

  What you need to build:

  1. Auth Entry Point (/auth/login):
    - Read magic query parameter from URL
    - Store in sessionStorage: sessionStorage.setItem('pending-magic', magic)
    - Show Google Sign In button (using better-auth)
  2. OAuth Callback Handler:
    - After successful Google auth, check for pending magic number
    - If exists, call: POST /api/auth/link-magic with:
  {
    "magic_number": "550e8400-..."
  }
    - Clear the pending magic from sessionStorage
  3. Success Page:
    - Show "Successfully linked to Aria Desktop!"
    - Optional: Redirect to aria://auth-success?token={jwt_token} for seamless return
  4. User Dashboard (future):
    - Show usage stats, subscription tier
    - Bundle management
    - Billing/upgrade options


  --------------------------------------------------------------------------------------


  🔧 Backend Implementation Plan

  Phase 1: Database Schema Updates

  1. Extend users table:
  ALTER TABLE users ADD COLUMN
      magic_number TEXT UNIQUE,
      magic_number_created_at INTEGER,
      magic_number_linked_at INTEGER,
      oauth_provider TEXT,
      oauth_id TEXT,
      oauth_email TEXT,
      subscription_tier TEXT DEFAULT 'free',
      tier_limits TEXT, -- JSON
      stripe_customer_id TEXT,
      stripe_subscription_id TEXT;

  CREATE INDEX idx_users_magic_number ON users(magic_number);

  2. Add usage tracking table:
  CREATE TABLE usage_metrics (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      metric_type TEXT NOT NULL, -- 'storage_bytes', 'bundle_count', 'api_calls'
      value INTEGER NOT NULL,
      period_start INTEGER NOT NULL,
      period_end INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(user_id)
  );

  Phase 2: Auth Service Implementation

  1. JWT Validation Service:
  pub struct JwtValidator {
      secret: String,
      issuer: String,
  }

  pub struct JwtClaims {
      pub sub: String, // user_id
      pub email: String,
      pub tier: String,
      pub exp: i64,
  }

  2. Magic Number Service:
  pub struct MagicNumberService {
      database: Arc<DatabaseManager>,
  }

  impl MagicNumberService {
      pub async fn validate_magic(&self, magic: &str) -> Result<Option<String>>;
      pub async fn link_to_user(&self, user_id: &str, magic: &str) -> Result<()>;
      pub async fn get_status(&self, magic: &str) -> Result<MagicStatus>;
  }

  Phase 3: HTTP Endpoints

  1. New Auth Routes:
  // In routes/auth.rs
  pub fn router() -> Router<HttpServerState> {
      Router::new()
          .route("/auth/link-magic", post(link_magic_number))
          .route("/auth/magic-status", get(check_magic_status))
          .route("/auth/validate-token", post(validate_token))
  }

  2. Enhance Auth Middleware:
  // Support both JWT tokens and magic numbers
  pub async fn auth_middleware(
      headers: HeaderMap,
      mut request: Request,
      next: Next,
  ) -> Result<Response, StatusCode> {
      // Check Bearer token first (for web/API clients)
      // Then check X-Aria-Magic-Number header (for CLI)
      // Inject AuthUser into request extensions
  }

  Phase 4: Upload Flow Enhancement

  1. Bundle Upload with Auth:
  async fn upload_bundle(
      State(state): State<HttpServerState>,
      Extension(user): Extension<AuthUser>, // From auth middleware
      headers: HeaderMap,
      multipart: Multipart,
  ) -> Response {
      // Check user tier limits
      let usage = state.usage_service.check_storage(&user.user_id).await?;

      // Process upload
      // Track usage
      // Send notification to user's channel
  }

  2. User-Specific Notifications:
  // Modify notification service to be user-aware
  impl NotificationService {
      pub async fn send_to_user(&self, user_id: &str, event: NotificationEvent);
      pub async fn subscribe_user(&self, user_id: &str) -> Receiver<Event>;
  }

  Phase 5: CLI Integration

  1. Update ar-c to read magic number:
  // In cli/upload.rs
  fn get_auth_header() -> Result<String> {
      let config_path = dirs::home_dir()
          .unwrap()
          .join("aria")
          .join("config.json");

      if let Ok(config) = fs::read_to_string(config_path) {
          let config: AriaConfig = serde_json::from_str(&config)?;
          return Ok(format!("X-Aria-Magic-Number: {}", config.magic_number));
      }

      Err(anyhow!("No Aria Desktop app found. Please install from https://aria.dev"))
  }

  Phase 6: Usage Enforcement

  1. Tier Limits:
  pub struct TierLimits {
      pub storage_bytes: u64,
      pub bundles_per_month: u32,
      pub api_calls_per_day: u32,
  }

  pub fn get_tier_limits(tier: &str) -> TierLimits {
      match tier {
          "free" => TierLimits {
              storage_bytes: 1_073_741_824, // 1GB
              bundles_per_month: 10,
              api_calls_per_day: 1000,
          },
          "pro" => TierLimits {
              storage_bytes: 10_737_418_240, // 10GB
              bundles_per_month: 100,
              api_calls_per_day: 10000,
          },
          _ => // enterprise limits
      }
  }

  Implementation Priority:

  1. Week 1: Database schema + JWT validation
  2. Week 2: Magic number service + auth endpoints
  3. Week 3: Enhanced auth middleware + usage tracking
  4. Week 4: User-specific notifications + CLI updates

----------------------------------------------------------------------------------------

  SDK:

  - The CLI should handle missing fields gracefully:
  #[derive(Deserialize, Default)]
  struct AriaConfig {
      magic_number: Option<String>,
      auth: Option<AuthConfig>,
      api: Option<ApiConfig>,
  }

  impl AriaConfig {
      fn get_auth_header(&self) -> Option<String> {
          if let Some(auth) = &self.auth {
              if auth.linked && auth.access_token.is_some() {
                  return Some(format!("Bearer {}",
  auth.access_token.as_ref().unwrap()));
              }
          }

          // Fallback to magic number
          self.magic_number.as_ref()
              .map(|m| format!("X-Aria-Magic-Number: {}", m))
      }
  }