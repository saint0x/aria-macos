use std::sync::Arc;
use tokio::sync::Mutex;
use tonic::transport::{Channel, Endpoint, Uri};
use tonic::Request;

// Generated gRPC code
pub mod aria {
    pub mod v1 {
        tonic::include_proto!("aria.v1");
    }
}

use aria::v1::{
    session_service_client::SessionServiceClient,
    task_service_client::TaskServiceClient,
    notification_service_client::NotificationServiceClient,
    container_service_client::ContainerServiceClient,
    CreateSessionRequest, ExecuteTurnRequest, Session, TurnOutput,
    LaunchTaskRequest,
};

#[derive(Clone)]
pub struct AriaGrpcClient {
    session_client: Arc<Mutex<Option<SessionServiceClient<Channel>>>>,
    task_client: Arc<Mutex<Option<TaskServiceClient<Channel>>>>,
    notification_client: Arc<Mutex<Option<NotificationServiceClient<Channel>>>>,
    container_client: Arc<Mutex<Option<ContainerServiceClient<Channel>>>>,
}

impl AriaGrpcClient {
    pub fn new() -> Self {
        Self {
            session_client: Arc::new(Mutex::new(None)),
            task_client: Arc::new(Mutex::new(None)),
            notification_client: Arc::new(Mutex::new(None)),
            container_client: Arc::new(Mutex::new(None)),
        }
    }

    async fn connect(&self) -> Result<Channel, Box<dyn std::error::Error + Send + Sync>> {
        // Connect to Unix domain socket
        let _socket_path = std::env::var("HOME").unwrap_or_else(|_| "/tmp".to_string()) + "/.aria/runtime.sock";
        
        // Create a channel that connects to the Unix socket
        // Note: This is a simplified approach - in production you might want more robust connection handling
        let uri = Uri::from_static("http://[::1]:50051"); // Fallback to localhost for testing
        let channel = Endpoint::from(uri)
            .connect()
            .await?;
        
        Ok(channel)
    }

    async fn ensure_session_client(&self) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let mut client = self.session_client.lock().await;
        if client.is_none() {
            let channel = self.connect().await?;
            *client = Some(SessionServiceClient::new(channel));
        }
        Ok(())
    }

    async fn ensure_task_client(&self) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let mut client = self.task_client.lock().await;
        if client.is_none() {
            let channel = self.connect().await?;
            *client = Some(TaskServiceClient::new(channel));
        }
        Ok(())
    }

    pub async fn create_session(&self) -> Result<Session, Box<dyn std::error::Error + Send + Sync>> {
        self.ensure_session_client().await?;
        let mut client = self.session_client.lock().await;
        let client = client.as_mut().unwrap();
        
        let request = Request::new(CreateSessionRequest {});
        let response = client.create_session(request).await?;
        Ok(response.into_inner())
    }

    pub async fn execute_turn(&self, session_id: String, input: String) -> Result<Vec<TurnOutput>, Box<dyn std::error::Error + Send + Sync>> {
        self.ensure_session_client().await?;
        let mut client = self.session_client.lock().await;
        let client = client.as_mut().unwrap();
        
        let request = Request::new(ExecuteTurnRequest {
            session_id,
            input,
        });
        
        let mut stream = client.execute_turn(request).await?.into_inner();
        let mut outputs = Vec::new();
        
        while let Some(output) = stream.message().await? {
            outputs.push(output);
        }
        
        Ok(outputs)
    }

    pub async fn launch_task(&self, session_id: String, task_type: String, command_json: String) -> Result<String, Box<dyn std::error::Error + Send + Sync>> {
        self.ensure_task_client().await?;
        let mut client = self.task_client.lock().await;
        let client = client.as_mut().unwrap();
        
        let request = Request::new(LaunchTaskRequest {
            session_id,
            r#type: task_type,
            command_json,
            environment: std::collections::HashMap::new(),
            timeout_seconds: 300, // 5 minutes default
        });
        
        let response = client.launch_task(request).await?;
        Ok(response.into_inner().task_id)
    }
}

// Global client instance
static GRPC_CLIENT: std::sync::OnceLock<AriaGrpcClient> = std::sync::OnceLock::new();

pub fn get_grpc_client() -> &'static AriaGrpcClient {
    GRPC_CLIENT.get_or_init(|| AriaGrpcClient::new())
}