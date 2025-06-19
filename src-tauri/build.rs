fn main() {
  tonic_build::configure()
    .build_server(false) // We only need client code
    .compile(
      &[
        "proto/session_service.proto",
        "proto/task_service.proto", 
        "proto/notification_service.proto",
        "proto/container_service.proto",
      ],
      &["proto/"]
    )
    .unwrap();
    
  tauri_build::build()
}
