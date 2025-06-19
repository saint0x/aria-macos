use serde::{Deserialize, Serialize};
use crate::grpc_client::get_grpc_client;

#[derive(Serialize, Deserialize)]
pub struct ChatMessage {
    pub id: String,
    pub role: String, // 'user', 'assistant', 'system', 'tool'
    pub content: String,
    pub timestamp: String,
}

#[derive(Serialize, Deserialize)]
pub struct SessionResponse {
    pub id: String,
    pub created_at: String,
}

#[derive(Serialize, Deserialize)]
pub struct ExecuteTurnResponse {
    pub messages: Vec<ChatMessage>,
}

// Session commands
#[tauri::command]
pub async fn create_session() -> Result<SessionResponse, String> {
    let client = get_grpc_client();
    
    match client.create_session().await {
        Ok(session) => Ok(SessionResponse {
            id: session.id,
            created_at: session.created_at
                .map(|ts| format!("{}.{:09}", ts.seconds, ts.nanos))
                .unwrap_or_else(|| chrono::Utc::now().to_rfc3339()),
        }),
        Err(e) => Err(format!("Failed to create session: {}", e)),
    }
}

#[tauri::command]
pub async fn execute_turn(session_id: String, input: String) -> Result<ExecuteTurnResponse, String> {
    let client = get_grpc_client();
    
    match client.execute_turn(session_id, input).await {
        Ok(outputs) => {
            let messages = outputs
                .into_iter()
                .filter_map(|output| {
                    match output.event {
                        Some(crate::grpc_client::aria::v1::turn_output::Event::Message(message)) => {
                            Some(ChatMessage {
                                id: message.id,
                                role: match message.role {
                                    0 => "system".to_string(),
                                    1 => "user".to_string(), 
                                    2 => "assistant".to_string(),
                                    3 => "tool".to_string(),
                                    _ => "unknown".to_string(),
                                },
                                content: message.content,
                                timestamp: message.created_at
                                    .map(|ts| format!("{}.{:09}", ts.seconds, ts.nanos))
                                    .unwrap_or_else(|| chrono::Utc::now().to_rfc3339()),
                            })
                        },
                        Some(crate::grpc_client::aria::v1::turn_output::Event::ToolCall(tool_call)) => {
                            Some(ChatMessage {
                                id: format!("tool-call-{}", chrono::Utc::now().timestamp_millis()),
                                role: "tool".to_string(),
                                content: format!("Tool: {}\nParameters: {}", tool_call.tool_name, tool_call.parameters_json),
                                timestamp: chrono::Utc::now().to_rfc3339(),
                            })
                        },
                        Some(crate::grpc_client::aria::v1::turn_output::Event::ToolResult(tool_result)) => {
                            Some(ChatMessage {
                                id: format!("tool-result-{}", chrono::Utc::now().timestamp_millis()),
                                role: "tool".to_string(),
                                content: format!("Result: {}{}", 
                                    tool_result.result_json,
                                    if !tool_result.success {
                                        tool_result.error_message
                                            .map(|e| format!(" (Error: {})", e))
                                            .unwrap_or_else(|| " (Error: Unknown)".to_string())
                                    } else {
                                        String::new()
                                    }
                                ),
                                timestamp: chrono::Utc::now().to_rfc3339(),
                            })
                        },
                        Some(crate::grpc_client::aria::v1::turn_output::Event::FinalResponse(final_response)) => {
                            Some(ChatMessage {
                                id: format!("final-{}", chrono::Utc::now().timestamp_millis()),
                                role: "assistant".to_string(),
                                content: final_response,
                                timestamp: chrono::Utc::now().to_rfc3339(),
                            })
                        },
                        None => None,
                    }
                })
                .collect();
                
            Ok(ExecuteTurnResponse { messages })
        },
        Err(e) => Err(format!("Failed to execute turn: {}", e)),
    }
}

// Task commands
#[tauri::command]
pub async fn launch_task(session_id: String, task_type: String, command_json: String) -> Result<String, String> {
    let client = get_grpc_client();
    
    match client.launch_task(session_id, task_type, command_json).await {
        Ok(task_id) => Ok(task_id),
        Err(e) => Err(format!("Failed to launch task: {}", e)),
    }
}

// Health check command
#[tauri::command]
pub async fn health_check() -> Result<String, String> {
    Ok("gRPC client is ready".to_string())
}