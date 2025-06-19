import type { LogEntry } from "@/lib/types"
import { LogLevel, ProcessStatus } from "@/lib/types"
import { subMinutes, subHours, addMinutes, formatISO } from "date-fns" // Import addMinutes

const now = new Date()

// --- Correctly calculate chained date operations ---
const pipelineStartTime = subHours(now, 1)
const pipelineEndTime = addMinutes(pipelineStartTime, 4) // Correctly add 4 minutes to the start time

export const mockLogs: LogEntry[] = [
  // --- Agent Task 1: Successful Research ---
  {
    id: "log-agent1-001",
    timestamp: formatISO(subMinutes(now, 10)),
    level: LogLevel.INFO,
    message: "Agent 'ResearchPro' received task: 'Analyze impact of quantum computing on finance'.",
    source: "Agent Core",
    entityName: "Task:QuantumFinanceImpact",
    actor: "User:Analyst1",
    status: ProcessStatus.STARTED,
    details: {
      taskId: "task_quantum_001",
      userInput: "Analyze the potential impact of quantum computing on the financial sector.",
      agentConfig: { model: "gpt-4o-mega", maxIterations: 5 },
    },
  },
  {
    id: "log-agent1-002",
    timestamp: formatISO(subMinutes(now, 50)),
    level: LogLevel.DEBUG,
    message: "Planning execution: 1. WebSearch for recent articles. 2. DataAnalysis of trends. 3. Synthesize report.",
    source: "Agent:ResearchPro",
    entityName: "Task:QuantumFinanceImpact",
    status: ProcessStatus.THINKING,
    details: {
      plan: [
        { step: 1, action: "ToolCall", tool: "WebSearch", inputs: ["quantum computing finance impact 2024"] },
        { step: 2, action: "ToolCall", tool: "DataAnalysis", inputs: ["search_results"] },
        { step: 3, action: "LLMCall", purpose: "SynthesizeReport" },
      ],
    },
  },
  {
    id: "log-agent1-003",
    timestamp: formatISO(subMinutes(now, 40)),
    level: LogLevel.INFO,
    message: "Calling tool 'WebSearch' with query: 'quantum computing finance impact 2024'.",
    source: "Agent:ResearchPro",
    entityName: "Tool:WebSearch",
    status: ProcessStatus.TOOL_CALL,
    details: {
      tool_name: "WebSearch",
      tool_input: { query: "quantum computing finance impact 2024", num_results: 5 },
    },
  },
  {
    id: "log-agent1-004",
    timestamp: formatISO(subMinutes(now, 10)),
    level: LogLevel.SUCCESS,
    message: "Tool 'WebSearch' executed successfully. Found 5 articles.",
    source: "Tool:WebSearch",
    entityName: "Task:QuantumFinanceImpact",
    status: ProcessStatus.COMPLETED,
    durationMs: 2850,
    details: {
      tool_output: {
        result_count: 5,
        results: [
          { title: "Quantum's Financial Frontier", url: "example.com/article1", relevance: 0.92 },
          { title: "Finance Braces for Quantum Leap", url: "example.com/article2", relevance: 0.88 },
        ],
      },
    },
  },
  {
    id: "log-agent1-005",
    timestamp: formatISO(subMinutes(now, 5)),
    level: LogLevel.DEBUG,
    message: "Received 5 search results. Proceeding to analyze.",
    source: "Agent:ResearchPro",
    entityName: "Task:QuantumFinanceImpact",
    status: ProcessStatus.TOOL_RESPONSE,
  },
  {
    id: "log-agent1-006",
    timestamp: formatISO(subMinutes(now, 30)),
    level: LogLevel.INFO,
    message: "Calling LLM for synthesis and report generation.",
    source: "Agent:ResearchPro",
    entityName: "LLM Interface",
    status: ProcessStatus.IN_PROGRESS,
    details: {
      model_provider: "OpenAI",
      model_name: "gpt-4o-mega",
      prompt_tokens: 1250,
      context_length: 4096,
    },
  },
  {
    id: "log-agent1-007",
    timestamp: formatISO(subMinutes(now, 50)),
    level: LogLevel.SUCCESS,
    message: "LLM generated report successfully.",
    source: "LLM Interface",
    entityName: "Task:QuantumFinanceImpact",
    status: ProcessStatus.COMPLETED,
    durationMs: 3800,
    details: {
      completion_tokens: 850,
      total_tokens: 2100,
      output_preview: "Quantum computing is poised to revolutionize finance by enhancing risk models...",
    },
  },
  {
    id: "log-agent1-008",
    timestamp: formatISO(subMinutes(now, 45)),
    level: LogLevel.SUCCESS,
    message: "Agent 'ResearchPro' completed task 'Analyze impact of quantum computing on finance'.",
    source: "Agent Core",
    entityName: "Task:QuantumFinanceImpact",
    status: ProcessStatus.COMPLETED,
    durationMs: 135000, // 2 min 15 sec
    details: {
      final_output_location: "/reports/quantum_finance_impact_001.pdf",
      confidence_score: 0.95,
    },
  },

  // --- Agent Task 2: Failed Tool Call ---
  {
    id: "log-agent2-001",
    timestamp: formatISO(subMinutes(now, 5)),
    level: LogLevel.INFO,
    message: "Agent 'MarketScanner' received task: 'Fetch real-time stock price for ACME Corp'.",
    source: "Agent Core",
    entityName: "Task:FetchStockACME",
    actor: "User:TraderJoe",
    status: ProcessStatus.STARTED,
    details: { taskId: "task_stock_002", ticker: "ACME" },
  },
  {
    id: "log-agent2-002",
    timestamp: formatISO(subMinutes(now, 50)),
    level: LogLevel.INFO,
    message: "Calling tool 'StockAPI' for ticker 'ACME'.",
    source: "Agent:MarketScanner",
    entityName: "Tool:StockAPI",
    status: ProcessStatus.TOOL_CALL,
    details: { tool_name: "StockAPI", tool_input: { symbol: "ACME" } },
  },
  {
    id: "log-agent2-003",
    timestamp: formatISO(subMinutes(now, 40)),
    level: LogLevel.ERROR,
    message: "Tool 'StockAPI' failed to execute. API returned 401 Unauthorized.",
    source: "Tool:StockAPI",
    entityName: "Task:FetchStockACME",
    status: ProcessStatus.FAILED,
    durationMs: 550,
    details: {
      error_code: "API_UNAUTHORIZED",
      error_message: "Invalid API key provided or subscription expired.",
      http_status: 401,
    },
  },
  {
    id: "log-agent2-004",
    timestamp: formatISO(subMinutes(now, 35)),
    level: LogLevel.WARN,
    message: "Attempting fallback tool 'BackupStockSource'.",
    source: "Agent:MarketScanner",
    entityName: "Task:FetchStockACME",
    status: ProcessStatus.THINKING,
    details: { reason: "Primary StockAPI failed." },
  },
  {
    id: "log-agent2-005",
    timestamp: formatISO(subMinutes(now, 30)),
    level: LogLevel.INFO,
    message: "Calling tool 'BackupStockSource' for ticker 'ACME'.",
    source: "Agent:MarketScanner",
    entityName: "Tool:BackupStockSource",
    status: ProcessStatus.TOOL_CALL,
    details: { tool_name: "BackupStockSource", tool_input: { symbol: "ACME" } },
  },
  {
    id: "log-agent2-006",
    timestamp: formatISO(subMinutes(now, 0)),
    level: LogLevel.SUCCESS,
    message: "Tool 'BackupStockSource' executed successfully. Price: $123.45",
    source: "Tool:BackupStockSource",
    entityName: "Task:FetchStockACME",
    status: ProcessStatus.COMPLETED,
    durationMs: 2850,
    details: {
      tool_output: {
        symbol: "ACME",
        price: 123.45,
        currency: "USD",
        timestamp: formatISO(subMinutes(now, 1)),
      },
    },
  },
  {
    id: "log-agent2-007",
    timestamp: formatISO(subMinutes(now, 55)),
    level: LogLevel.SUCCESS,
    message: "Agent 'MarketScanner' completed task 'Fetch real-time stock price for ACME Corp'.",
    source: "Agent Core",
    entityName: "Task:FetchStockACME",
    status: ProcessStatus.COMPLETED,
    durationMs: 65000, // 1 min 5 sec
    details: {
      final_output: { price: 123.45, source: "BackupStockSource" },
      notes: "Primary API failed, used backup.",
    },
  },

  // --- General System Logs ---
  {
    id: "log-sys-001",
    timestamp: formatISO(pipelineStartTime),
    level: LogLevel.INFO,
    message: "Pipeline 'HourlyDataIngest' started.",
    source: "SystemScheduler",
    entityName: "Pipeline:HourlyDataIngest",
    status: ProcessStatus.STARTED,
    details: { trigger: "cron:0 * * * *", expected_duration_min: 5 },
  },
  {
    id: "log-sys-002",
    timestamp: formatISO(pipelineEndTime),
    level: LogLevel.SUCCESS,
    message: "Pipeline 'HourlyDataIngest' completed successfully.",
    source: "SystemScheduler",
    entityName: "Pipeline:HourlyDataIngest",
    status: ProcessStatus.COMPLETED,
    durationMs: 240000, // 4 minutes
    details: { records_processed: 15230, data_source: "S3Bucket:raw-data" },
  },
]
