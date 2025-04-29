# Azure AI Agent Service metric collection

Metrics contained in the **Azure AI agent service** [metric collection](./metrics-azure-ai-agent-v0.1.0.json) provide observability over AI-powered agent interactions, including usage volume, cost (token consumption), performance (latency), and tool usage effectiveness. They are meant to be used, in combination with the same [provided](../summaryrules-v0.1.0.yaml) Log Analytics [summary rule](https://learn.microsoft.com/azure/azure-monitor/logs/summary-rules?tabs=api), directly out-of-the-box with minimal edits. They consume spans and attributes created automatically by instrumentation libraries that adhere to the [**OpenTelemetry semantic conventions for AI agent**](https://github.com/microsoft/opentelemetry-semantic-conventions/blob/main/docs/gen-ai/azure-ai-agent-spans.md) spans—specifically, those that emit events named `gen_ai.agent.otel.span`.

> [!NOTE]
> The AI agent semantic conventions are in active development and marked as experimental. For experimental semantic conventions, there is risk of breaking changes due to updates in either the conventions themselves or in instrumentation libraries. The Online Experimentation team will release updates to align to major changes in these conventions. 

> [!Warning]
> Do not deploy multiple Online Experimentation summary rule versions at the same time. If in doubt, choose the most recent version.

| AI Agent metric collection version | OTel semantic convention version | Creation date | Metric collection | Summary rule |
|---------------------------------------|----------------------------------|---------------|-------------------|--------------|
| v0.1.0                                | Version 1.31.1 (experimental)       | Feb 2025      | [metrics-azure-ai-agent-v0.1.0](./metrics-azure-ai-agent-v0.1.0.json) | [summaryrules-v0.1.0](../summaryrules-v0.1.0.yaml) |

---

## Prerequisites

### Instrumentation

1. **Azure AI Agent Service**  
    This metric is supposed to be used with [Azure AI Agent service](https://learn.microsoft.com/en-us/azure/ai-services/agents/overview). [Tracing](https://learn.microsoft.com/en-us/azure/ai-services/agents/concepts/tracing) should also be enabled through AI foundary portal.
2. **TargetingId on spans**  
   **to be determined

### GitHub Action for metric deployment

Deployment of online experimentation metrics is managed by configuring the [Deploy Metrics](https://github.com/Azure/online-experimentation-deploy-metrics) GitHub Action in your experimentation-enabled repository.

### Log Analytics summary rule

A summary rule is used to pre-process AI agent spans for metric computation.  
- You should have or provision a summary rule that maps `gen_ai.agent.otel.span` data into the `AppEvents_CL` table in your Log Analytics workspace.  
- If you already have an existing summary rule for standard AI agent spans, you can optionally consolidate them, or create a new rule for agent spans.  
- Ensure that the rule name stays consistent if you are updating an existing rule—this prevents duplication.

If you do not see the `AppEvents_CL` table or no data flows in for agent spans, verify:
1. You have pushed AI agent instrumentation data into Application Insights.
2. You have created or updated the summary rule to capture `gen_ai.agent.otel.span`.
3. You are waiting at least an hour after traffic flows for the rule to produce summary data.

If you have never configured a summary rule, see [root `README.md`](../README.md) for a detailed guide on creating it, or consult the [Online Experimentation documentation](https://aka.ms/exp/public/docs).

---

## Deploy metrics

1. Add the contents of `metrics-azure-ai-agent-v0.1.0.json` into your experimentation-enabled repository (e.g., under an `infra` or `metrics` folder).
2. Optionally modify the metrics:
   - **Rename** or **update descriptions** of metrics if needed.
   - Change the lifecycle of any `Inactive` metrics to `Active` if you want them computed.
   - **Caution:** The metric definitions rely on your summary rule output format (e.g. eventName, property names). If you adjust the summary rule or the instrumentation attributes, update the metric definitions accordingly.
3. If this is your first time deploying a summary rule for AI agent data, see the [root `README.md`](../README.md) for general instructions on metric and summary rule deployment.

---

## Azure AI Agent metrics

The following metrics are defined in `metrics-azure-ai-agent-v0.1.0.json`:

| Display name                                                        | Metric type | Description                                                                                                                                                             | Default lifecycle |
|---------------------------------------------------------------------|-------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------|
| **Number of AI agent spans**                                     | EventCount  | The total number of AI agent spans captured. This metric provides a baseline measure of your agent activity and usage volume across your application.                 | Active            |
| **Number of AI agent users**                                     | UserCount   | The number of users producing at least one AI agent span. This metric measures discovery/adoption of your AI agent features.                                      | Active            |
| **Number of calls for creating new thread with AI agent**        | EventCount  | The total number of AI agent operations that create new threads in your AI agent implementation.                                                                    | Active            |
| **Number of calls for creating new message with AI agent**       | EventCount  | The total number of AI agent operations that create new messages in your AI agent implementation.                                                                  | Active            |
| **Number of calls for processing thread run with AI agent**      | EventCount  | The total number of AI agent operations that process thread runs in your AI agent implementation.                                                                  | Active            |
| **Total AI agent input tokens**                                  | Sum         | The total input tokens used across all AI agent calls.                                                                                                              | Active            |
| **Average AI agent input tokens**                                | Average     | The average number of input tokens used per AI agent call.                                                                                                           | Active            |
| **90th percentile AI agent input tokens**                        | Percentile  | The 90th percentile of input tokens per AI agent call, showing usage near the upper end of the distribution.                                                         | Inactive          |
| **Median AI agent input tokens**                                 | Percentile  | The median (50th percentile) input tokens per AI agent call.                                                                                                         | Inactive          |
| **Total AI agent output tokens**                                 | Sum         | The total output tokens generated across all AI agent calls.                                                                                                         | Active            |
| **Average AI agent output tokens**                               | Average     | The average number of output tokens generated per AI agent call.                                                                                                     | Active            |
| **90th percentile AI agent output tokens**                       | Percentile  | The 90th percentile of output tokens per AI agent call, showing response lengths near the upper end of the distribution.                                             | Active            |
| **Median AI agent output tokens**                                | Percentile  | The median (50th percentile) output tokens per AI agent call.                                                                                                        | Inactive          |
| **Average AI agent duration**                                    | Average     | The average duration in milliseconds of AI agent calls (most relevant to `process_thread_run` operations).                                                          | Active            |
| **90th percentile AI agent duration**                            | Percentile  | The 90th percentile duration of AI agent calls, showing outliers in processing time.                                                                                 | Inactive          |
| **Median AI agent duration**                                     | Percentile  | The median duration of AI agent calls, showing typical processing times less influenced by outliers.                                                                | Inactive          |

> [!NOTE]
> Some metrics are marked as **Inactive** by default. You can activate them if you expect sufficient data volume and want to track the relevant distribution details or success rates.



## Summary rule for AI agent spans

If this is your first time adding a Log Analytics summary rule for Online Experimentation, see  [root `README`](../README.md).

For summary rules that are managed by GitHub Action:
1. Update the query in the corresponding summary rule object in `summaryrules.yaml` file in your experimentation-enabled repository under the `infra` folder. 
1. Do _not_ update the summary rule name: if you do, the old and new summary rules will both execute, producing duplicated logs which can skew metrics.
1. Confirm the summary rule destination table is `AppEvents_CL`: other destination tables will _not_ be consumed for metric computation.

    Upon deployment, the bicep template will create/update the summary rule: if a summary rule of the same name exists it will be updated. 

To update summary rules directly through Log Analytics API, or to manage or delete summary rules, see [Log Analytics](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api) documentation.

To preview the output of the summary rule in advance, copy the query from [`summaryrules-{version}.yaml`] and paste into your application's Log Analytics workspace.

## Getting help

For questions or issues with Application insights WebAPI metrics, contact [exp-preview-fb@microsoft.com](mailto:exp-preview-fb@microsoft.com).