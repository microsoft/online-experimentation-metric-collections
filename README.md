# Online Experimentation Metric Collections

This repository provides versioned samples of online experimentation metrics, sample support files for integrating with CI/CD, and documentation for online experimentation metrics.

> [!CAUTION]
> Contents in this repository are actively updated during private preview. 

## Features

Sample metric collections are organized into 2 directories:

1. **[genai](./genai):** Pre-built GenAI metric collection compatible with instrumentation libraries that adhere to [OpenTelemetry semantic conventions for GenAI spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/). Contents include configuration for GenAI metrics such as usage frequency, token usage and response latency. 
The `summaryrules.json` file is necessary to provision a corresponding [Log Analytics summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api) for data extraction and transformation on GenAI spans. Details are in the GenAI collection's `README.md` file.

2. **[custom](./custom):** Sample metric collections based on Azure Monitor custom events (with corresponding instrumentation samples). These samples demonstrate how to instrument custom events and then use them in metric definitions. They can also be used directly in your application.

## Getting Started

### Prerequisites

To generate metrics with Online Experimentation, you must:

* Provision an online experimentation workspace.
* Integrate Azure AppConfig and instrument key events for metrics using AppConfig's track event.
* Use the [azure/online-experimentation-deploy-metrics](https://github.com/Azure/online-experimentation-deploy-metrics) GitHub Action in your CI/CD workflows.
* [For GenAI metrics] utilize a OpenTelemetry GenAI instrumentation library which follows the [OpenTelemetry semantic convents](https://opentelemetry.io/docs/specs/semconv/gen-ai/). Enrich with custom attribute `TargetingId` (required): AppConfig's TargetingId must be attached to GenAI traces in order to consume them for Online Experimentation.



## Demo

The sample application [`Open AI Chat App`](https://github.com/Azure-Samples/openai-chat-app-eval-ab) for evaluation and Online Experimentation provides a contextualized example of how metrics, summary rules and event tracking fit into an application. We reference these to provide the contextualized demo.

* [Add (your customized) metrics to a json file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/tree/main/.config). Edit your [GitHub Actions workflow file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/.github/workflows/azure-dev.yml) configured file path to ensure metrics in the file are deployed.
* Add the summary rule(s) necessary for consuming OTEL-based GenAI spans into your repository's [infra path](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/la-summary-rules.json) and ensure your [main.bicep](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/main.bicep) has a module for summary rule deployment. For more clarity on deploying summary rules, a sample bicep template is referenced below, with placeholder support files in the [infra](./genai/infra) folder of this samples repo.


In the [`./genai/infra/main.bicep`](./genai/infra/main.bicep) file of your target, add in the summary rule module:

```yaml
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

This module requires two dependent files:
- [`summaryrule.bicep`](./genai/infra/monitor/summaryrule.bicep) template (can be copied as-is from this repo)
- [`summaryrules.json`](./genai/infra/monitor/summaryrules.json`) -- a list of parameterized summary rules to create or update, as in [`genai`](./genai/summaryrules.json) metric collections.

## Resources

- [Online Experimentation documentation](https://aka.ms/exp/public/docs)
- [Sample Online Experimentation enabled OpenAI app](https://github.com/Azure-Samples/openai-chat-app-eval-ab)
- [Github Action to deploy metrics](https://github.com/Azure/online-experimentation-deploy-metrics)

