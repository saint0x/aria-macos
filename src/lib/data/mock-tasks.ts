import type { Task } from "@/lib/types"
import { TaskStatus } from "@/lib/types"

export const mockTasks: Task[] = [
  {
    id: "task-1",
    name: "Analyze Q1 Sales Data and Identify Key Trends",
    status: TaskStatus.COMPLETED,
    agent: "DataInsight Pro",
    tools: ["Salesforce API", "Advanced Charting"],
    currentStepDescription: "Final report generated and saved.",
    fullDescription:
      "Comprehensive analysis of first-quarter sales data to identify significant trends, anomalies, and key performance indicators. The final report includes visualizations and actionable insights.",
    startTime: "2024-07-15T09:00:00Z",
    endTime: "2024-07-15T11:30:00Z",
    detailIdentifier: "TASK_DETAIL_task-1",
  },
  {
    id: "task-2",
    name: "Draft Marketing Brief: Summer Campaign",
    status: TaskStatus.IN_PROGRESS,
    agent: "CreativeAI Writer",
    tools: ["Market Research DB", "Competitor Analysis Suite"],
    currentStepDescription: "Awaiting stakeholder feedback on initial draft.",
    fullDescription:
      "Develop a detailed marketing brief for the upcoming 'Summer Splash' campaign. Initial draft completed and shared; currently paused pending review and feedback from the marketing lead.",
    startTime: "2024-07-16T10:00:00Z",
    detailIdentifier: "TASK_DETAIL_task-2",
  },
  {
    id: "task-3",
    name: "Query: Latest EU regulations on data privacy",
    status: TaskStatus.FAILED,
    agent: "LegalEagle Bot",
    tools: ["EU Legal Database API", "Compliance Checker"],
    currentStepDescription: "API connection to legal database timed out.",
    fullDescription:
      "Retrieve and summarize the latest European Union regulations concerning data privacy and GDPR updates. Task failed due to persistent API connection issues with the primary legal database.",
    startTime: "2024-07-16T14:00:00Z",
    detailIdentifier: "TASK_DETAIL_task-3",
  },
  {
    id: "task-4",
    name: "Generate: Social media content calendar for August",
    status: TaskStatus.RUNNING,
    agent: "SocialSpark AI",
    tools: ["TrendTracker", "ContentScheduler", "ImageGen"],
    currentStepDescription: "Currently drafting posts for week 2.",
    fullDescription:
      "Create a comprehensive social media content calendar for August, including engaging posts for Twitter, Instagram, and LinkedIn, aligned with current marketing themes. Process is actively running.",
    startTime: "2024-07-18T09:00:00Z",
    detailIdentifier: "TASK_DETAIL_task-4",
  },
  {
    id: "task-5",
    name: "Research: Top 5 AI advancements in healthcare for 2024",
    status: TaskStatus.PENDING,
    agent: "ResearchAI Pro",
    tools: ["PubMed API", "TechCrunch Scraper", "Academic Journals DB"],
    currentStepDescription: "Awaiting allocation of research resources.",
    fullDescription:
      "Conduct thorough research to identify and summarize the top 5 most impactful AI advancements in the healthcare sector reported or significantly progressed in 2024. Task is pending resource allocation.",
    detailIdentifier: "TASK_DETAIL_task-5",
  },
  {
    id: "task-6",
    name: "Action: Summarize customer feedback from last 7 days",
    status: TaskStatus.COMPLETED,
    agent: "FeedbackAnalyzer",
    tools: ["Zendesk API", "Sentiment Analysis Model"],
    currentStepDescription: "Summary report delivered.",
    fullDescription:
      "Extract customer feedback from all support channels over the past week, perform sentiment analysis, and generate a concise summary report highlighting key issues and praises.",
    startTime: "2024-07-17T09:00:00Z",
    endTime: "2024-07-17T10:30:00Z",
    detailIdentifier: "TASK_DETAIL_task-6",
  },
]
