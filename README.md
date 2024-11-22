# Online Experimentation Metric Collections

> [!IMPORTANT]
> This repository is under active development and is subject to the [Azure AI Private Preview Terms - Online Experimentation](private-preview-terms.md).

Online Experimentation enables you to evaluate feature variations in production. Quality evaluation requires setting up metrics that measure your application's performance, reliability, usage and quality of engagement. The goal of this repository is to provide out-of-the-box GenAI metrics and custom metric samples that make it easy for you to get started with Online Experimentation.

This repository provides documentation and samples of online experimentation metrics. 

## Features

Sample metric collections are organized into 2 directories:

1. **[genai](./genai):** A collection of metrics for GenAI, compatible with instrumentation libraries that adhere to [OpenTelemetry semantic conventions for GenAI spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/). Includes out-of-box GenAI metric configurations to evaluate: frequency of user engagement with GenAI, token usage (cost). 

  This directory also contains corresponding `summaryrules-{version}.json` files which provide necessary data extraction and transformation logic on GenAI spans via a [Log Analytics summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api).

2. **[custom](./custom):** Sample metric collections that demonstrate how to track custom events with App Configuration and define corresponding metrics for Online Experimentation. User feedback and custom errors are both highlighted samples. Custom metrics and event tracking allow you to evaluate the user signals critical to success of your application: regardless of whether those signals are conventional or highly specialized to your application.

## Getting Started

### Prerequisites

To generate metrics with Online Experimentation you must integrate Online Experimentation offering. See [Online Experimentation documentation](https://aka.ms/exp/public/docs) for the full setup documentation.


* App Configuration with Online Experimentation and Azure Monitor resources. See this [quickstart guide](https://github.com/MicrosoftDocs/online-experimentation-docs/blob/aprilk/gh-actions-quickstart/Documentation/Quickstarts/Setup_Azure_AppConfig_Bicep.md) for details. 
* GitHub Action [azure/online-experimentation-deploy-metrics](https://github.com/Azure/online-experimentation-deploy-metrics) in your CI/CD workflow.
* Instrument your application. 
    * App Configuration provides a [custom event logger](https://github.com/microsoft/FeatureManagement-Python/blob/2982253c865208f49a8e9cd18f4bc5004376cd8e/featuremanagement/azuremonitor/_send_telemetry.py#L31) that automatically adds the App Configuration targeting id to each event. Targeting id is required for any event used in Online Experimentation metrics.
* Send tracked events to Azure Monitor.
    * Azure Monitor [OpenTelemetry Distro](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable) enables collection of OpenTelemtry-based logs.
    * Azure Monitor Logs charge based on data ingested. See [pricing](https://azure.microsoft.com/en-us/pricing/details/monitor/).
* [For GenAI metrics] integrate a GenAI instrumentation library which follows the [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/).
     * Enrich spans with custom attribute `TargetingId` (required): Azure App Configuration's TargetingId must be attached to GenAI traces in order to consume them for Online Experimentation metrics.
     * You must also create a summary rule which ouputs transformed GenAI spans into `AppEvents_CL` table. Summary rule and directions are provided in this repository. See [`genai` directory](./genai/). 

## Demo

The sample application [`OpenAI Chat App`](https://github.com/Azure-Samples/openai-chat-app-eval-ab) for Online Experimentation provides a contextualized example of how telemetry, metrics and summary rules fit into an application. 

### Custom metric demo
To add a new custom metric counting "Users who gave positive feedback" to your sample application:

First observe: the sample application already instruments user feedback scores, so no new instrumentation is needed. You can find the custom event tracking by searching `track_event` in the sample app repo.

1. Copy the metric configuration for this new metric.
  ```json
    {
      "id": "users_feedback_positive",
      "lifecycle": "Active",
      "displayName": "Users who gave positive feedback",
      "description": "The number of users who gave at least one positive feedback (clicked thumbs-up).",
      "tags": ["Feedback"],
      "desiredDirection": "Increase",
      "definition": {
        "kind": "UserCount",
        "event": {
          "eventName": "UserFeedback",
          "filter": "Score > 0"
        }
      }
    }
  ```
1. Add this metric object to a [metric JSON file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/tree/main/.config). 
    - Check your [GitHub Actions workflow file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/.github/workflows/azure-dev.yml) configured file path to ensure the file you edited is processed by that GHA.
1. Since the sample application already is set up to  deploy metrics via GHA, you just need to deploy the application. Your next scorecard from the sample application will contain this newly enabled metric.

### GenAI metric demo

The sample application already integrates Traceloop OpenLLMetry instrumentation library for GenAI spans. It also includes the collection of GenAI metrics and provisions the required summary rule. Here we'll walk through editing a GenAI metric as you might do for your product application.

1. Edit one of the GenAI metrics in [metrics-genai JSON file](https://github.com/Azure-Samples/openai-chat-app-eval-ab/tree/main/.config). We recommend enabling the "95th percentile GenAI usage tokens" metric by changing the lifecycle from "Inactive" (as below) to "Active". You might also consider adding a near-duplicate metric which measures the median (50th percentile).

    ```json
      {
        "id": "p95_genai_tokens",
        "displayName": "95th percentile GenAI usage tokens",
        "description": "The 95th percentile usage tokens (both input and output) per GenAI call of any type. This gives an indication of the usage near the upper end of the distribution. Because percentile metrics can be less sensitive and more costly to compute, we mark this metric as 'Inactive' by default.",
        "lifecycle": "Inactive",
        "tags": [
          "GenAI",
          "Cost"
        ],
        "desiredDirection": "Decrease",
        "definition": {
          "kind": "Percentile",
          "value": {
            "eventName": "gen_ai.otel.span",
            "eventProperty": "gen_ai.usage.tokens"
          },
          "percentile": 95
        }
      }
    ```

1. Since the sample application is set up to provision the summary rule and deploy metrics, you just need to deploy the application. Your next scorecard from the sample application will contain this newly enabled metric. 

>[!Note]
> Summary rules can take up to 2 hours to start processing data after their first setup. GenAI metric values may be zero in the very first one hour scorecard.



#### How did the sample application provision the summary rule for consuming OTel-based GenAI spans?

The configuration of summary rule is in the [infra path](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/la-summary-rules.json): this metrics collection repository maintains a versioned collection of summary rules under [genai](./genai). 

The [main.bicep](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/main.bicep) has a module for summary rule deployment. A demo bicep template module is referenced below, with placeholder support files in the [infra directory](./genai/infra) of this metric collection repo.

      Sample bicep module for summary rule deployment:

      ```
      targetScope = 'subscription'

      @description('Log Analytics Workspace name,   location,   and   resource group')
      param logAnalyticsWorkspaceName string =      'YOUR_WORKSPACE_NAMWE'
      param logAnalyticsWorkspaceLocation string =      'YOUR_WORKSPACE_REGION'
      param logAnalyticsWorkspaceResourceGroupName string   =     'YOUR_WORKSPACE_RG'
      resource logAnalyticsWorkspaceResourceGroup   'Microsoft.   Resources/resourceGroups@2021-04-01'  existing = {
        name: logAnalyticsWorkspaceResourceGroupName
      }


      // summary rule module
      var ruleDefinitions = loadJsonContent('./monitor/     summaryrules.json')
      module summaryRules './monitor/summaryrule.bicep' =   [    for (rule, i) in ruleDefinitions: if (!empty    (logAnalyticsWorkspaceName) && !empty     (logAnalyticsWorkspaceLocation)) {
        name: 'loganalytics-summaryrule-${i}'
        scope: logAnalyticsWorkspaceResourceGroup
        params: {
          location: logAnalyticsWorkspaceLocation  
          logAnalyticsWorkspaceName:  logAnalyticsWorkspaceName
          summaryRuleName: rule.name
          description: rule.description
          query: rule.query
          binSize: 20 
          destinationTable: 'AppEvents_CL'
        }
      } ]
      ```



This module requires two dependent files:
  - [`summaryrule.bicep`](./genai/infra/monitor/summaryrule.bicep) template. Use as-is from this repo.
  - [`summaryrules.json`](./genai/infra/monitor/summaryrules.json) -- a list of parameterized summary rules to create or update. For a directly usable instance, see    [`genai/summaryrules`](./genai/summaryrules-v0.1.0.json).


## Resources

- [Online Experimentation documentation](https://aka.ms/exp/public/docs)
- [Sample Online Experimentation enabled OpenAI app](https://github.com/Azure-Samples/openai-chat-app-eval-ab)
- [GitHub Action to deploy metrics](https://github.com/Azure/online-experimentation-deploy-metrics)
- Contact <a href="mailto:exp-preview-fb\@microsoft.com">exp-preview-fb\@microsoft.com</a> for assistance during private preview.

