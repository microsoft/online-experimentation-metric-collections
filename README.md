# Online Experimentation Metric Collections

> [!CAUTION]
> Contents in this repository are actively updated during private preview. 

Sample configuration of metrics for Online Experimentation. 
Summary rules for data transformation on common GenAI instrumentation logs. Documentation for usage. 




## Features

Sample metric collections are organized into 2 directories:

1. **[genai](./genai):** Pre-built GenAI metric collections for supported GenAI instrumentation providers. Contents include configuration for GenAI metrics such as token usage and response latency. 

   Each collection also has a `summaryrules.json` file. When added to a repository with Online Experimentation enabled, this will be used to provision a corresponding [Log Analytics summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api) for data extraction and transformation. This summary rule is customized to the instrumentation provider and is required for metric computation. Details are in each collection's `README.md` file.

2. **[custom](./custom):** Sample metric collections based on Azure Monitor custom events (with corresponding instrumentation samples). These samples demonstrate how to instrument custom events and then use them in metric definitions. They can also be used directly in your application.

## Getting Started

### Prerequisites

To generate metrics with Online Experimentation, you must:

* Provision an online experimentation workspace.
* Integrate Azure AppConfig and instrument key events for metrics using AppConfig's track event.
* Use the [azure/online-experimentation-deploy-metrics](https://github.com/Azure/online-experimentation-deploy-metrics) GitHub Action in your CI/CD workflows.
* [For GenAI metrics] utilize a supported OpenTelemetry GenAI instrumentation provider. Enrich with custom attribute `TargetingId` (required). AppConfig's TargetingId must be attached to GenAI traces in order to consume them for Online Experimentation.


>[!Tip]
> If you do not have an existing GenAI instrumentation provider: [Traceloop with OpenLLMetry](https://www.traceloop.com/openllmetry) is recommended as a provider which is vetted for ease of use, alignment with online experimentation requirements and for consistency of following OpenTelemetry semantic conventions.


## Demo

The sample application [`Open AI Chat App`](https://github.com/Azure-Samples/openai-chat-app-eval-ab) for evaluation and Online Experimentation provides a contextualized example of how metrics, summary rules and event tracking fit into an application. We reference these to provide the contextualized demo.

* [Add (your customized) metrics to a json file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/tree/main/.config). Edit your [GitHub Actions workflow file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/.github/workflows/azure-dev.yml) configured file path to ensure metrics in the file are deployed.
* Add the summary rule(s) necessary for your instrumentation provider to your repository's [infra path](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/la-summary-rules.json) and ensure your [main.bicep](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/main.bicep) has a module for summary rule deployment. For more clarity on deploying summary rules, a sample bicep template is referenced below, with placeholder support files in the [infra](./genai/infra) folder of this samples repo.


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
- [`summaryrules.json`](./genai/infra/monitor/summaryrules.json`) -- a list of parameterized summary rules to create or update, which should be customized based on the GenAI instrumentation provider(s) used: supported providers' summary rules are found under the [`genai`](./genai) metric collections.

## Resources

- [Online Experimentation documentation](https://aka.ms/exp/public/docs)
- [Sample Online Experimentation enabled OpenAI app](https://github.com/Azure-Samples/openai-chat-app-eval-ab)
- [Github Action to deploy metrics](https://github.com/Azure/online-experimentation-deploy-metrics)

