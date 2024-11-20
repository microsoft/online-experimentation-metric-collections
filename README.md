# Online Experimentation Metric Collections

> [!IMPORTANT]
> This repository is under active development and is subject to the [Azure AI Private Preview Terms - Online Experimentation](private-preview-terms.md).

Online Experimentation enables you to evaluate feature variations in production. Quality evaluation requires setting up metrics that measure your application's performance, reliability, usage and quality of engagement. The goal of this repository is to provide out-of-the-box GenAI metrics and custom metric samples that make it easy for you to get started with online experimentation.

This repository provides documentation and samples of online experimentation metrics and the required files for integrating with CI/CD.

## Features

Sample metric collections are organized into 2 directories:

1. **[genai](./genai):** Pre-built GenAI metric collection compatible with instrumentation libraries that adhere to [OpenTelemetry semantic conventions for GenAI spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/). Contents include configuration for GenAI metrics such as frequency of user engagement, token usage and response latency so that you can monitor usage volume, costs and varied operational metrics for GenAI integrations within your application. 
The `summaryrules.json` file is necessary to provision a corresponding [Log Analytics summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api) for data extraction and transformation on GenAI spans.

2. **[custom](./custom):** Sample metric collections based on Azure Monitor custom events (with corresponding sample code for instrumentation). These samples demonstrate how to instrument custom events and then use them in metric definitions. They can also be used directly in your application. This section also contains requirements around instrumentation for Online Experimentation metrics.

## Getting Started

### Prerequisites

To generate metrics with Online Experimentation you must integrate Online Experimentation offering. See [Online Experimentation documentation](https://aka.ms/exp/public/docs) for the full setup documentation.

You must have:

* Provisioned an online experimentation workspace. Follow documentation at[Online Experimentation documentation](https://aka.ms/exp/public/docs).
* Integrated with Azure App Configuration SDK to evaluate feature flags and instrument key events for metrics using track event.
* Set up the [azure/online-experimentation-deploy-metrics](https://github.com/Azure/online-experimentation-deploy-metrics) GitHub Action in your CI/CD workflows.
* [For GenAI metrics] integrated a GenAI instrumentation library which follows the [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/).
  - Enriched spans with custom attribute `TargetingId` (required): Azure App Configuration's TargetingId must be attached to GenAI traces in order to consume them for Online Experimentation metrics.
* [For GenAI metrics] created a summary rule which ouputs transformed GenAI spans into `AppEvents_CL` table. 
  - Select a single summary rule and metric configuration file from the version table in [`genai` directory](./genai/). Do not deploy multiple summary rule versions. If in doubt, choose the most recent version.

## Demo

The sample application [`OpenAI Chat App`](https://github.com/Azure-Samples/openai-chat-app-eval-ab) for Online Experimentation provides a contextualized example of how telemetry, metrics and summary rules fit into an application. 

To modify the metrics in this sample application:

* [Add (your customized) metrics to a json file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/tree/main/.config). Check your [GitHub Actions workflow file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/.github/workflows/azure-dev.yml) configured file path to ensure the file is processed by that GHA.
* Add the summary rule(s) necessary for consuming OTEL-based GenAI spans into your repository's [infra path](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/la-summary-rules.json) and ensure your [main.bicep](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/main.bicep) has a module for summary rule deployment. For more clarity on deploying summary rules, a sample bicep template is referenced below, with placeholder support files in the [infra](./genai/infra) folder of this samples repo.

Sample bicep module for summary rule deployment:

```
targetScope = 'subscription'

@description('Log Analytics Workspace name, location, and resource group')
param logAnalyticsWorkspaceName string = 'YOUR_WORKSPACE_NAMWE'
param logAnalyticsWorkspaceLocation string = 'YOUR_WORKSPACE_REGION'
param logAnalyticsWorkspaceResourceGroupName string = 'YOUR_WORKSPACE_RG'
resource logAnalyticsWorkspaceResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: logAnalyticsWorkspaceResourceGroupName
}


// summary rule module
var ruleDefinitions = loadJsonContent('./monitor/summaryrules.json')
module summaryRules './monitor/summaryrule.bicep' =  [ for (rule, i) in ruleDefinitions: if (!empty(logAnalyticsWorkspaceName) && !empty(logAnalyticsWorkspaceLocation)) {
  name: 'loganalytics-summaryrule-${i}'
  scope: logAnalyticsWorkspaceResourceGroup
  params: {
    location: logAnalyticsWorkspaceLocation  
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    summaryRuleName: rule.name
    description: rule.description
    query: rule.query
    binSize: 20 
    destinationTable: 'AppEvents_CL'
  }
} ]
```

> [!Important]
> Ensure destinationTable matches 'AppEvents_CL'. No other custom log tables are used for Online Experimentation metric computation.

This module requires two dependent files:
- [`summaryrule.bicep`](./genai/infra/monitor/summaryrule.bicep) template (can be copied as-is from this repo)
- [`summaryrules.json`](./genai/infra/monitor/summaryrules.json) -- a list of parameterized summary rules to create or update. For example, [`genai`](./genai/summaryrules.json).

## Resources

- [Online Experimentation documentation](https://aka.ms/exp/public/docs)
- [Sample Online Experimentation enabled OpenAI app](https://github.com/Azure-Samples/openai-chat-app-eval-ab)
- [GitHub Action to deploy metrics](https://github.com/Azure/online-experimentation-deploy-metrics)
- Contact <a href="mailto:exp-preview-fb\@microsoft.com">exp-preview-fb\@microsoft.com</a> for assistance during private preview.

