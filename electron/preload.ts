import { contextBridge, ipcRenderer } from 'electron'

// Expose the same API as Tauri to maintain compatibility
contextBridge.exposeInMainWorld('__ELECTRON_API__', {
  invoke: async (command: string, args?: unknown): Promise<unknown> => {
    switch (command) {
      case 'create_session':
        return ipcRenderer.invoke('create_session')
      case 'execute_turn':
        return ipcRenderer.invoke('execute_turn', (args as { sessionId: string; input: string })?.sessionId, (args as { sessionId: string; input: string })?.input)
      case 'health_check':
        return ipcRenderer.invoke('health_check')
      case 'launch_task':
        return ipcRenderer.invoke('launch_task', args)
      default:
        throw new Error(`Unknown command: ${command}`)
    }
  }
})