mod grpc_client;
mod commands;

use commands::{create_session, execute_turn, launch_task, health_check};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  tauri::Builder::default()
    .setup(|app| {
      if cfg!(debug_assertions) {
        app.handle().plugin(
          tauri_plugin_log::Builder::default()
            .level(log::LevelFilter::Info)
            .build(),
        )?;
      }
      Ok(())
    })
    .invoke_handler(tauri::generate_handler![
      create_session,
      execute_turn, 
      launch_task,
      health_check
    ])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
