import * as grpc from '@grpc/grpc-js'
import * as protoLoader from '@grpc/proto-loader'
import path from 'path'
import { ProtoGrpcType as SessionProtoGrpcType } from '@/generated/session_service'
import { ProtoGrpcType as TaskProtoGrpcType } from '@/generated/task_service'
import { ProtoGrpcType as NotificationProtoGrpcType } from '@/generated/notification_service'
import { ProtoGrpcType as ContainerProtoGrpcType } from '@/generated/container_service'

class AriaGrpcClient {
  private static instance: AriaGrpcClient
  private sessionClient: any
  private taskClient: any
  private notificationClient: any
  private containerClient: any
  private socketPath: string

  private constructor() {
    // Default path as per APICONTRACT.md, with env override support
    this.socketPath = process.env.ARIA_RUNTIME_SOCK || '~/.aria/runtime.sock'
    this.initializeClients()
  }

  public static getInstance(): AriaGrpcClient {
    if (!AriaGrpcClient.instance) {
      AriaGrpcClient.instance = new AriaGrpcClient()
    }
    return AriaGrpcClient.instance
  }

  private async initializeClients() {
    try {
      // Load proto definitions
      const protoPath = path.join(process.cwd(), 'src/proto')
      
      const sessionPackage = protoLoader.loadSync(
        path.join(protoPath, 'session_service.proto'),
        {
          keepCase: true,
          longs: String,
          enums: String,
          defaults: true,
          oneofs: true,
        }
      )

      const taskPackage = protoLoader.loadSync(
        path.join(protoPath, 'task_service.proto'),
        {
          keepCase: true,
          longs: String,
          enums: String,
          defaults: true,
          oneofs: true,
        }
      )

      const notificationPackage = protoLoader.loadSync(
        path.join(protoPath, 'notification_service.proto'),
        {
          keepCase: true,
          longs: String,
          enums: String,
          defaults: true,
          oneofs: true,
        }
      )

      const containerPackage = protoLoader.loadSync(
        path.join(protoPath, 'container_service.proto'),
        {
          keepCase: true,
          longs: String,
          enums: String,
          defaults: true,
          oneofs: true,
        }
      )

      // Load gRPC package definitions
      const sessionProto = grpc.loadPackageDefinition(sessionPackage) as unknown as SessionProtoGrpcType
      const taskProto = grpc.loadPackageDefinition(taskPackage) as unknown as TaskProtoGrpcType
      const notificationProto = grpc.loadPackageDefinition(notificationPackage) as unknown as NotificationProtoGrpcType
      const containerProto = grpc.loadPackageDefinition(containerPackage) as unknown as ContainerProtoGrpcType

      // Create Unix socket target - format: unix:path
      const target = `unix:${this.socketPath.replace('~', process.env.HOME || '')}`

      // Initialize clients for each service
      this.sessionClient = new sessionProto.aria.v1.SessionService(
        target,
        grpc.credentials.createInsecure()
      )

      this.taskClient = new taskProto.aria.v1.TaskService(
        target,
        grpc.credentials.createInsecure()
      )

      this.notificationClient = new notificationProto.aria.v1.NotificationService(
        target,
        grpc.credentials.createInsecure()
      )

      this.containerClient = new containerProto.aria.v1.ContainerService(
        target,
        grpc.credentials.createInsecure()
      )

      console.log(`gRPC clients initialized for socket: ${target}`)
    } catch (error) {
      console.error('Failed to initialize gRPC clients:', error)
      throw error
    }
  }

  // Session Service methods
  public getSessionClient() {
    return this.sessionClient
  }

  // Task Service methods  
  public getTaskClient() {
    return this.taskClient
  }

  // Notification Service methods
  public getNotificationClient() {
    return this.notificationClient
  }

  // Container Service methods
  public getContainerClient() {
    return this.containerClient
  }

  // Health check method
  public async isConnected(): Promise<boolean> {
    try {
      // Try a simple call to check connectivity
      return new Promise((resolve) => {
        this.sessionClient.CreateSession({}, (error: any) => {
          // We expect this to fail with permissions or not found, not connection error
          resolve(!error || !error.message.includes('UNAVAILABLE'))
        })
      })
    } catch (error) {
      return false
    }
  }
}

export default AriaGrpcClient