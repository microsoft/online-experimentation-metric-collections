# Online Experimentation Metric Collections

> [!CAUTION]
> Contents in this repository are actively updated during private preview. 

Sample configuration of metrics for Online Experimentation. 
Summary rules for data transformation on common GenAI instrumentation logs. Documentation for usage. 




## Features

Sample metric collections are organized into 2 directories:

1. **[genai](./genai):** Pre-built GenAI metric collections for supported GenAI instrumentation providers. Contents include configuration for GenAI metrics such as token usage and response latency. 

   Each collection also has a `summaryrules.json` file. When added to a repository with Online Experimentation enabled, this will be used to provision a corresponding [Log Analytics summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api) for data extraction and transformation. This summary rule is customized to the insturmentation provider and is required for metric computation. Details are in each collection's `README.md` file.

2. Samples for custom metric definitions off of custom Azure AppConfig's event tracking, along with corresponding sample telemetry implementation. See [custom](./custom/README.md)

## Getting Started

### Prerequisites

To generate metrics with Online Experimentation, you must:

* Provision an online experimentation workspace.
* Integrate Azure AppConfig and instrument key events for metrics using AppConfig's track event.
* [For custom metrics] set up the [online experimentation metric deployment Github Action](https://github.com/Azure/online-experimentation-deploy-metrics/blob/main/README.md) as part of your CI/CD.
* [For GenAI metrics] utilize a supported OpenTelemetry GenAI instrumentation provider. Enrich with custom attributes to ensure AppConfig `TargetingId`, `InstrumentationProvider` and `InstrumentationProvider.version` are contained in the log. 

>[!Tip]
> If you do not have an existing GenAI instrumentation provider: [Traceloop with OpenLLMetry](https://www.traceloop.com/openllmetry) is recommended as a provider which is vetted for ease of use, alignment with online experimentation requirements and for consistency of following OpenTelemetry semantic conventions.


## Demo

The sample application [`Open AI Chat App`](https://github.com/Azure-Samples/openai-chat-app-eval-ab) for evaluation and Online Experimentation provides a contextualized example of how metrics, summary rules and event tracking fit into an application. We reference these to provide the contextualized demo.

* [Add (your customized) metrics to a json file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/tree/main/.config). Edit your [metric deployment GHA](https://github.com/Azure/online-experimentation-deploy-metrics/blob/main/README.md) configured file path to ensure the file is discoverable.
* Add the summary rule(s) necessary for your instrumentation provider to your repository's [infra path](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/la-summary-rules.json) and ensure your [main.bicep](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/main.bicep) has a module for summary rule deployment. For more clarity on deploying summary rules, a sample bicep template is referenced below, with placeholder support files in the [infra](./infra) folder of this samples repo.


In the [`./infra/main.bicep`](./infra/main.bicep) file of your target, add in the summary rule module:

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
- [`summaryrule.bicep`](./infra/monitor/summaryrule.bicep) template (can be copied as-is from this repo)
- [`summaryrules.json`](./infra/monitor/summaryrules.json`) -- a list of parameterized summary rules to create or update, which should be customized based on the GenAI instrumentation provider(s) used: supported providers' summary rules are found under the [`genai`](./genai) metric collections.

## Resources

- [Online Experimentation documentation](https://github.com/MicrosoftDocs/online-experimentation-docs)
- [Sample Online Experimentation enabled OpenAI app](https://github.com/Azure-Samples/openai-chat-app-eval-ab)
- [Github Action to deploy metrics](https://github.com/Azure/online-experimentation-deploy-metrics)

