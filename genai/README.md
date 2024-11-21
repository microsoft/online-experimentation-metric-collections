# GenAI metric collection

Metrics contained in the GenAI [metric collection](./metrics-v0.json) are common GenAI-related measures such as token consumption and request latency. They are meant to be used, in combination with the [provided](./summaryrules-v0.json) Log Analytics [summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api), directly out-of-box with minimal edits. They consume GenAI spans and attributes created automatically by instrumentation libraries that adhere strictly to the [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/).


The semantic conventions for GenAI are in active development and are marked as experimental. For experimental semantic conventions there is risk in breaking changes due to either semantic conventions or GenAI instrumentation library updates. The Online Experimentation team will release updates to align to any major updates of the semantic conventions. 

> [!Warning]
> Do not deploy multiple Online Experimentation summary rule versions at the same time. If in doubt, choose the most recent version.


| GenAI metric collection version | OTEL semantic convention version | Creation date | Metric collection | Summary rule |
| --------| ---------------------------------| --------------| -------- | ------- |
| v0 | Version 1.27+ | November 2024 | [metrics-v0](./metrics-v0.json) | [summaryrules-v0](./summaryrules-v0.json)

## Prerequisites

### Instrumentation 

1. To use these metrics and summary rule without edits you must use a GenAI instrumentation library which adheres to OpenTelemtry semantic conventions.

    [Azure AI Inference](https://learn.microsoft.com/en-us/azure/ai-studio/reference/reference-model-inference-api?tabs=python#inference-sdk-support) with [tracing via OpenTelemetry](https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-inference/README.md) and [Traceloop OpenLLMetry](https://www.traceloop.com/openllmetry) both have high alignment with the OpenTelemetry semantic conventions.

1. `TargetingId` must be added to the GenAI spans. 
    
    Traceloop supports this by [association entity](https://www.traceloop.com/docs/openllmetry/tracing/association) onto Traceloop logs.
    
    Azure AI Inference supports this by [adding custom properties to spans](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-add-modify?tabs=aspnetcore#add-a-custom-property-to-a-span) which may require a custom span processor. The naming convention of the attribute must be one of:
    * `TargetingId`
    * `targeting_id`
    * `targetingid`
    * `targetingId`

    or `traceloop.association.properties.{one of the list above}`

1. GenAI spans must be sent to Azure Monitor, and be accessible in the Log Analytics Workspace configured for use with Online Experimentation. Confirm this by running a query like the one below in your Log Analytics Workspace:

    ```kusto
    AppDependencies
    | where TimeGenerated > ago(3d)
    | where Properties has "gen_ai.system"
    | take 10
    ```

    Results should be non-empty and the `Properties` column should contain attributes like:

    ```json
    { 
        gen_ai.operation.name: "chat",
        gen_ai.request.model: "gpt-4",
        gen_ai.system: "openai",
        gen_ai.usage.input_tokens: 100,
        gen_ai.usage.output_tokens: 180
    }
    ```

    If GenAI spans are enabled but not sent to Application Insights and Log Analytics, configure the [Azure Monitor OpenTelemetry Distro](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable).

   
### GitHub action for metric deployment

Deployment of online experimentation metrics is managed by configuring the [Deploy Metrics](https://github.com/Azure/online-experimentation-deploy-metrics) GitHub Action in your experimentation-enabled repository.


### Log Analytics summary rule

A summary rule is used to preprocess GenAI spans for metric computation. To confirm if you have an active summary rule for Online Experimentation, look for the `AppEvents_CL` table in your Log Analytics workspace. If this table is not present, you have not configured the necessary summary rule. See the section [Summary rule for GenAI spans](#summary-rule-for-genai-spans) for more information.

### Deploy metrics

1. Add the contents of `metrics-{version}.json` to corresponding files in your experimentation-enabled repository.
1. Optionally: modify metrics. Rename or update description of metrics. Set desired `Inactive` metrics as `Active`. 
    
    Caution should be exercised when customizing the metric definition field. The definition is dependent on summary rule output format.
1. If this is your first time adding summary rules for Online Experimentation, see [root `README.md`](../README.md) to overview metric and summary rule deployment, with more details in [Online Experimentation documentation](https://aka.ms/exp/public/docs).
   
## GenAI metrics

The following metrics are defined in `metrics-{version}.json`:

| Display name | Metric kind | Description | Default lifecycle |
| ------- | ------- | ------ | ------ | 
| Number of GenAI spans | EventCount | The number of GenAI spans. This is an approximation of the number of total GenAI requests made, as a single span _may_ incorporate multiple related GenAI calls depending on the instrumentation. | Active | 
| Number of GenAI users | UserCount | The number of users producing at least one GenAI span. This metric measures discovery/adoption of your GenAI features.  | Active | 
| Number of GenAI chat calls | EventCount | Though there are additional GenAI operation types, chat is a common operation and so this metric is provided as an example of how to filter general GenAI metrics to a particular operation name. Filtered to GenAI spans with gen_ai.operation.name =='chat' | Active | 
| Number of GenAI chat users | UserCount | The number of users with at least one GenAI span with gen_ai.operation.name =='chat'. | Active | 
| Average GenAI usage tokens | Average | The average usage tokens (both input and output) per GenAI call of any type. | Active | 
| 95th percentile GenAI usage tokens | Percentile | The 95th percentile usage tokens (both input and output) per GenAI call of any type. This gives an indication of the usage near the upper end of the distribution. | Inactive [\[1\]](#genai-metric-footnotes-1)  | 
| Average GenAI usage input tokens | Average | The average tokens used on input (prompt) per GenAI call of any type. |  Active | 
| Average GenAI usage output tokens | Average | The average tokens used on output (response) per GenAI call of any type. |  Active | 
| Total GenAI usage tokens| Sum | While average usage tokens gives an indication of per-call efficiency, your cost is based on the total token usage. This metric show total usage tokens (both input and output) for any type of GenAI calls. Assuming equal number of GenAI calls, we want total token usage to reduce or remain constant. The statistical test on this metric compares the token usage per TargetingId, thereby accounting for unequal traffic allocation across variants.| Active | 
| Total chat usage tokens| Sum | The same as previous, but restricted to 'chat' GenAI operations only.| Active | 
| Average chat call duration (ms) | Average | The average duration in milliseconds per GenAI operation. Duration is measured by the DurationMS property of the span capturing GenAI call completion. | Active | 
| Number of GenAI operations that end in an error | EventCount | The number of GenAI calls that have a non-empty 'error.type' attribute. | Active |
| Number of GenAI operations that end in a timeout error | EventCount | The number of GenAI calls that have 'error.type' equal to 'timeout'. This is an example metric for how to customize GenAI error type metrics to particular error classes. | Inactive [\[2\]](#genai-metric-footnotes-2) | 
| Number of GenAI calls with content filter finish reason | EventCount | The number of GenAI calls that listed 'content_filter' among their finish reason. |  Inactive [\[2,3\]](#genai-metric-footnotes-2) |
| Number of GenAI calls with length restriction finish reason | EventCount | The number of GenAI calls that listed 'length' among their finish reason. |  Inactive [\[2,3\]](#genai-metric-footnotes-2) |
| Number of GenAI calls with tool call finish reason | EventCount | The number of GenAI calls that listed 'tool_calls' among their finish reason. |  Inactive [\[2,3\]](#genai-metric-footnotes-2) |


### Reasons for `Inactive` metrics
<a id="genai-metric-footnotes-1"></a>
\[1\] Percentile metrics are set as `Inactive` by default as they require higher sample size in order to provide trustworthy results, are less statistically sensitive than average metrics on the same signal and can be less efficient to compute.

<a id="genai-metric-footnotes-2"></a>
\[2\] Although attributes are standardized by semantic conventions, the values they take may not be. Metrics which directly reference such attribute values are set as `Inactive` by default. Edit attribute values in the metric definition to match your application GenAI spans.

<a id="genai-metric-footnotes-3"></a>
\[3\]  Due to availability of recommended GenAI span attributes, these metrics are supported for Azure AI Inference but not Traceloop OpenLLMetry. If you are using Azure AI Inference, you can set these as `Active`. For other providers: check your application's GenAI spans to verify whether they include attributes referenced in the metric definition.





## Summary rule for GenAI spans

If this is your first time adding a Log Analytics summary rule for Online Experimentation, see  [root `README`](../README.md). An example of setting up the configured bicep template can be found in the Online Experimentation [sample application code](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/main.bicep).

If you have changed or updated instrumentation libraries, you may need to update an _existing_ summary rule.

For summary rules that are managed by GitHub Action:
1. Update the query in the corresponding summary rule object in `summaryrules.json` file in your experimentation-enabled repository under the `infra` folder. 
1. Do _not_ update the summary rule name: if you do, the old and new summary rules will both execute, producing duplicated logs which can skew metrics.
1. Confirm the summary rule destination table (configured in bicep file) is `AppEvents_CL`: other destination tables will _not_ be consumed for metric computation.

    Upon deployment, the bicep template will create/update the summary rule: if a summary rule of the same name exists it will be updated. 

To update summary rules directly through Log Analytics API, or to manage or delete summary rules, see [Log Analytics](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api) documentation.

To preview the output of the summary rule you'd set up using [`summaryrules-v0.json`](./summaryrules-v0.json), run the query below on your application's Log Analytics workspace.

```kusto
let otel_genai_semantic_convention_keys = dynamic(["gen_ai.operation.name","gen_ai.request.model", "gen_ai.system","error.type","server.port","gen_ai.request.frequency_penalty", "gen_ai.request.max_tokens","gen_ai.request.presence_penalty","gen_ai.request.stop_sequences","gen_ai.request.temperature","gen_ai.request.top_k","gen_ai.request.top_p","gen_ai.response.finish_reasons","gen_ai.response.id","gen_ai.response.model","gen_ai.usage.input_tokens","gen_ai.usage.output_tokens","server.address","gen_ai.openai.request.response_format","gen_ai.openai.request.seed","gen_ai.openai.request.service_tier","gen_ai.openai.response.service_tier"]);
let otel_genai_deprecated_keys = dynamic(["gen_ai.usage.completion_tokens","gen_ai.usage.prompt_tokens"]);
let other_supported_keys = dynamic(["gen_ai.response.model","gen_ai.openai.api_version"]);
let supported_keys = set_union(otel_genai_semantic_convention_keys, other_supported_keys);
let targetingid_keys = dynamic(["traceloop.association.properties.TargetingId", "traceloop.association.properties.targetingid","traceloop.association.properties.targetingId", "traceloop.association.properties.targeting_id", "TargetingId","targetingid","targetingId","targeting_id"]);
AppDependencies
| where Properties has "gen_ai.system"
| where Properties has "targetingid" or Properties has "targeting_id"
| extend Properties = iff(Properties has "gen_ai.usage.completion_tokens" and Properties !has "gen_ai.usage.output_tokens", bag_merge(Properties, bag_pack("gen_ai.usage.output_tokens",toint(Properties["gen_ai.usage.completion_tokens"]), "gen_ai.usage.input_tokens",toint(Properties["gen_ai.usage.prompt_tokens"]))),Properties)
| extend  keys = bag_keys(Properties)
| extend newProperties = bag_remove_keys(Properties, set_difference(keys,supported_keys))
| extend TargetingId = max_of(tostring(Properties["TargetingId"]),tostring(Properties["targetingid"]),tostring(Properties["targeting_id"]),tostring(Properties["traceloop.association.properties.TargetingId"]),tostring(Properties["traceloop.association.properties.targetingid"]),tostring(Properties["traceloop.association.properties.targeting_id"]),tostring(Properties["traceloop.association.properties.targetingId"]),tostring(Properties["targetingId"]))
| extend OTELVersion = extract("otel([0-9.]+[0-9])",1,SDKVersion)
| extend newProperties = bag_merge(newProperties, bag_pack("OTELVersion",OTELVersion, "TargetingId",TargetingId, "DurationMs",DurationMs, "Success",Success,"Name",Name, "ResutCode",ResultCode, "gen_ai.usage.tokens",max_of(toint(Properties["gen_ai.usage.input_tokens"]),toint(Properties["gen_ai.usage.prompt_tokens"]))+ max_of(toint(Properties["gen_ai.usage.output_tokens"]),toint(Properties["gen_ai.usage.completion_tokens"]))))
| extend stop = iff(Properties["gen_ai.response.finish_reasons"] has "stop", bag_pack("gen_ai.response.finish_reason.stop", 1),dynamic({})), tool_calls = iff(Properties["gen_ai.response.finish_reasons"] has "tool_calls", bag_pack("gen_ai.response.finish_reason.tool_calls", 1),dynamic({})), content_filter = iff(Properties["gen_ai.response.finish_reasons"] has "content_filter", bag_pack("gen_ai.response.finish_reason.content_filter", 1),dynamic({})), length = iff(Properties["gen_ai.response.finish_reasons"] has "length", bag_pack("gen_ai.response.finish_reason.length", 1),dynamic({}))
| extend Properties = bag_merge(newProperties, stop, tool_calls, content_filter, length)
| extend Name = "gen_ai.otel.span"
| project Name, TimeGenerated, ItemCount, Properties
```

## Help
For questions or issues with GenAI metrics, contact <a href="mailto:exp-preview-fb\@microsoft.com">exp-preview-fb\@microsoft.com</a>.
