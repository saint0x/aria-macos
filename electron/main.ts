import { app, BrowserWindow, ipcMain } from 'electron'
import * as path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

// Keep a global reference of the window object
let mainWindow: BrowserWindow | null = null

const createWindow = (): void => {
  // Create the browser window with transparency and vibrancy
  mainWindow = new BrowserWindow({
    width: 800,
    height: 200, // Increased height to show the chatbar
    resizable: true, // Allow resizing for development
    frame: false,
    alwaysOnTop: true,
    transparent: true,
    vibrancy: 'hud', // macOS vibrancy effect
    visualEffectState: 'active',
    titleBarStyle: 'hidden',
    show: false, // Don't show until ready
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
      webSecurity: false // Disable for development
    }
  })

  // Center the window on screen
  mainWindow.center()

  // Load the app
  const isDev = process.env.NODE_ENV === 'development'
  
  if (isDev) {
    mainWindow.loadURL('http://localhost:5173')
    mainWindow.webContents.openDevTools()
  } else {
    mainWindow.loadFile(path.join(__dirname, '../dist/index.html'))
  }

  // Show window only after content is loaded
  mainWindow.once('ready-to-show', () => {
    console.log('Window ready to show')
    mainWindow?.show()
  })

  // Debug: Log any loading errors
  mainWindow.webContents.on('did-fail-load', (_event, errorCode, errorDescription) => {
    console.error('Failed to load:', errorCode, errorDescription)
  })

  mainWindow.webContents.on('did-finish-load', () => {
    console.log('Content loaded successfully')
    // Inject some JavaScript to check if React is loaded
    mainWindow?.webContents.executeJavaScript(`
      console.log('DOM elements:', document.body.innerHTML.length > 0 ? 'Found' : 'Empty');
      console.log('React root:', document.getElementById('root') ? 'Found' : 'Not found');
      document.body.style.border = '2px solid red'; // Debug border
    `).catch(console.error)
  })

  // Log console messages from the renderer
  mainWindow.webContents.on('console-message', (_event, level, message) => {
    console.log(`[Renderer ${level}]:`, message)
  })

  mainWindow.on('closed', () => {
    mainWindow = null
  })
}

// This method will be called when Electron has finished initialization
app.whenReady().then(() => {
  createWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow()
    }
  })
})

// Quit when all windows are closed, except on macOS
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

// IPC handlers to maintain the same API as Tauri
ipcMain.handle('create_session', async () => {
  // Mock session creation - replace with actual gRPC client
  return {
    id: `session-${Date.now()}`,
    created_at: new Date().toISOString()
  }
})

ipcMain.handle('execute_turn', async (_event, sessionId: string, input: string) => {
  // Mock execute turn - replace with actual gRPC client
  await new Promise(resolve => setTimeout(resolve, 1000)) // Simulate processing
  
  return {
    messages: [
      {
        id: `msg-${Date.now()}`,
        role: 'assistant',
        content: `You said: "${input}". This is a mock response from Electron.`,
        timestamp: new Date().toISOString()
      }
    ]
  }
})

ipcMain.handle('health_check', async () => {
  return 'Electron backend is healthy'
})

ipcMain.handle('launch_task', async (_event, taskData: unknown) => {
  // Mock task launch - replace with actual implementation
  return {
    id: `task-${Date.now()}`,
    status: 'launched',
    timestamp: new Date().toISOString()
  }
})