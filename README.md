# Online Experimentation Metric Collections

> [!IMPORTANT]
> This repository is under active development and is subject to the [Azure AI Public Preview Terms - Online Experimentation](private-preview-terms.md).

Online experimentation enables you to evaluate feature variations in production. Quality evaluation requires setting up metrics that measure your application's performance, reliability, usage, and quality of engagement. The goal of this repository is to provide out-of-the-box metrics and custom metric samples that make it easy for you to get started with online experimentation.

This repository provides documentation and samples of online experimentation metrics and the required files for integrating with CI/CD.

## Features
Sample metric collections are organized into 5 directories:
| Folder | Purpose | Typical source telemetry |
| ------ | ------- | ------------------------ |
| [`genai-operational`](./genai-operational) | Out-of-box GenAI usage & cost metrics (token volume, latency, etc.). | Libraries adhere to [OpenTelemetry GenAI spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/) |
| [`appinsights-webapi`](./appinsights-webapi) | Core request / dependency metrics for Web APIs instrumented. | [Application Insights autoinstrumentation](https://learn.microsoft.com/en-us/azure/azure-monitor/app/codeless-overview) |
| [`azure-ai-agent-operational`](./azure-ai-agent-operational) | Metrics for Agent interactions (token usage, run latency, tool calls). | Libraries adhere to [Opentelemetry GenAI Agent Spans](https://github.com/microsoft/opentelemetry-semantic-conventions/blob/main/docs/gen-ai/azure-ai-agent-spans.md) such as [Azure AI Agent Tracing](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/concepts/tracing#observe-an-agent) |
| [`azure-ai-evaluation`](./azure-ai-evaluation) | AI-assisted quality & safety scores powered by [evaluators](https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/observability#what-are-evaluators). | [Azure AI evaluation continuous evaluation](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/monitor-applications) |
| [`custom`](./custom) | Sample metric definitions and code snippets to log custom events. | Any event sent to `AppEvents_CL` |

## Getting Started
To generate metrics with online experimentation, you must enable the feature in your Azure App Configuration resource. See [Get Started: Run Online Experimentations (Preview) in App Configuration](https://aka.ms/exp/public/TODO) for full setup instructions.

Each metric set has its own prerequisites; refer to the corresponding README under each directory for details.

You can also onboard through code using Bicep and a GitHub Action. Refer to the sample application [`OpenAI Chat App`](https://github.com/Azure-Samples/openai-chat-app-eval-ab) for a contextualized example of how telemetry, metrics, and summary rules fit into an application. 

To modify the metrics in this sample application:

* [Add (your customized) metrics to a json file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/tree/main/.config). Check your [GitHub Actions workflow file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/.github/workflows/azure-dev.yml) configured file path to ensure the file is processed by that GHA.
* Add the summary rule(s) necessary for consuming OTel-based GenAI spans into your repository's [infra path](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/la-summary-rules.yaml) and ensure your [main.bicep](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/main.bicep) has a module for summary rule deployment. For more clarity on deploying summary rules, a sample bicep template is referenced below, with placeholder support files in the [infra](./genai-operational/infra) folder of this samples repo.

Sample bicep module for summary rule deployment:

```
targetScope = 'subscription'

@description('Log Analytics Workspace name, location, and resource group')
param logAnalyticsWorkspaceName string = 'YOUR_WORKSPACE_NAME'
param logAnalyticsWorkspaceLocation string = 'YOUR_WORKSPACE_REGION'
param logAnalyticsWorkspaceResourceGroupName string = 'YOUR_WORKSPACE_RG'
resource logAnalyticsWorkspaceResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: logAnalyticsWorkspaceResourceGroupName
}


// summary rule module
var ruleDefinitions = loadYamlContent('./monitor/summaryrules.yaml')
module summaryRules './monitor/summaryrule.bicep' =  [ for (rule, i) in ruleDefinitions.summaryRules: if (!empty(logAnalyticsWorkspaceName) && !empty(logAnalyticsWorkspaceLocation)) {
  name: 'loganalytics-summaryrule-${i}'
  scope: logAnalyticsWorkspaceResourceGroup
  params: {
    location: logAnalyticsWorkspaceLocation  
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    summaryRuleName: rule.name
    description: rule.description
    query: rule.query
    binSize: rule.binSize
    destinationTable: rule.destinationTable
  }
} ]
```

> [!Important]
> Ensure destinationTable matches 'AppEvents_CL'. No other custom log tables are used for online experimentation metric computation.

This module requires two dependent files:
- [`summaryrule.bicep`](./genai-operational/infra/monitor/summaryrule.bicep) template (can be copied as-is from this repo)
- [`summaryrules.yaml`](./genai-operational/infra/monitor/summaryrules.yaml) -- a list of parameterized summary rules to create or update. Examples are provided in the [genai-operational directory](./genai-operational).

## Resources

- [Online experimentation documentation](https://aka.ms/exp/public/docs)
- [Sample online experimentation enabled OpenAI app](https://github.com/Azure-Samples/openai-chat-app-eval-ab)
- [GitHub Action to deploy metrics](https://github.com/Azure/online-experimentation-deploy-metrics)
- For continuous (online) evaluation in production environments, see [How to run evaluations online with the Azure AI Foundry SDK](./online_evaluation_doc.md).
- Contact [exp-preview-fb@microsoft.com](mailto:exp-preview-fb@microsoft.com) for assistance during private preview.