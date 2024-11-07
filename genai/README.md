# GenAI metric collection

Metrics contained in the GenAI metric collection are common GenAI-related measures such as token consumption and request latency. They are meant to be used, in combination with the associated [Log Analytics summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api) directly out-of-box with minimal edits. They consume GenAI spans and attributes created automatically by instrumentation libraries that adhere strictly to the [OpenTelemetry GenAI semantic conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/).

>[!Warning]
> While any instrumentation provider that follows the Open Telemetry GenAI semantic conventions will generate some value from this metric collection, not every instrumentation library strictly adheres to the semantic conventions. Therefore, some of the metrics in this collection may require editing or marking as 'Inactive' for your application. 

Azure AI Tracing and OpenLLMetry Traceloop both have high alignment with the semantic conventions

>[!Warning]
> The semantic conventions for GenAI are still in active development and are marked as experimental. Therefore, there is risk in breaking changes to this metric collection due to either semantic conventions or GenAI instrumentation library updates. The Online Experimentation team will release updates to align to any major updates of the semantic conventions.

## Prerequisites

`TargetingId` must be added to the GenAI spans. Traceloop supports this by [association entity](https://www.traceloop.com/docs/openllmetry/tracing/association) onto Traceloop logs. The naming convention of the attribute must be one of:
* `TargetingId`
* `targeting_id`
* `targetingid`
* `targetingId`

or `traceloop.association.properties.{one of the list above}`

> [!IMPORTANT]
> Summary rule provisioning is required to use metrics in this collection. If this is your first time adding a [Log Analytics summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api) for Online Experimentation, see [root `README`](../README.md) for overall guidance.

To update an _existing_ summary rule:
1. Update the query in the corresponding summary rule object in `summaryrules.json` file in your experimentation-enabled workspace under the `infra` folder. Upon deployment, the bicep template will initiate summary rule provisioning. 
1. Do _not_ update the summary rule name: if you do, the old and new summary rules will both execute, producing duplicated logs and increasing your data processing costs.


## GenAI metrics

The following metrics are provided:

| Display name | Metric kind | Description |
| ------- | ------- | ------ | 
| Number of GenAI spans | EventCount | The number of GenAI spans. This is an approximation of the number of total GenAI requests made, as a single span _may_ incorporate multiple related GenAI calls depending on the instrumentation.  |
| Number of GenAI users | UserCount | The number of users producing at least one GenAI span. This metric measures discovery/adoption of your GenAI features.  |
| Number of GenAI chat calls | EventCount | Though there are additional GenAI operation types, chat is a common operation and so this metric is provided as an example of how to filter general GenAI metrics to a particular operation name. Filtered to GenAI spans with gen_ai.operation.name =='chat' |
| Number of GenAI chat users | UserCount | The number of users with at least one GenAI span with gen_ai.operation.name =='chat'. |
| Average GenAI usage tokens | Average | The average usage tokens (both input and output) per GenAI call of any type. |
| 95th percentile GenAI usage tokens | Percentile | The 95th percentile usage tokens (both input and output) per GenAI call of any type. This gives an indication of the usage near the upper end of the distribution. Because percentile metrics can be less sensitive and more costly to compute, we mark this metric as 'Inactive' by default. |
| Average GenAI usage input tokens | Average | The average tokens used on input (prompt) per GenAI call of any type. | 
| Average GenAI usage output tokens | Average | The average tokens used on output (response) per GenAI call of any type. | 
| Total GenAI usage tokens| Sum | While average usage tokens gives an indication of per-call efficiency, your cost is based on the total token usage. This metric show total usage tokens (both input and output) for any type of GenAI calls. Assuming equal number of GenAI calls, we want total token usage to reduce or remain constant. The statistical test on this metric compares the token usage per event: meaning increased usage may increase the total usage tokens without flagging this metric as statistically significant.|
| Total chat usage tokens| Sum | The same as previous, but restricted to 'chat' GenAI operations only.|
| Average chat call duration (ms) | Average | The average duration in milliseconds per GenAI operation. Duration is measured by the DurationMS property of the span capturing GenAI call completion. |
| Number of GenAI calls with content filter finish reason | EventCount | The number of GenAI calls that listed 'content_filter' among their finish reason. Note that while listing this is a recommended semantic convention, not all telemetry instrumenters do include it. Therefore this metric is marked as 'Inactive' by default. We recommend checking your logs to determine if your instrumentation provider does log in this fashion. If not, this metric may need to be edited or will always return '0' incorrectly. | 
| Number of GenAI calls with length restriction finish reason | EventCount | The number of GenAI calls that listed 'length' among their finish reason. Similar to previous, this is marked as 'Inactive' by default. | 
| Number of GenAI calls with tool call finish reason | EventCount | The number of GenAI calls that listed 'tool_calls' among their finish reason. Similar to previous, this is marked as 'Inactive' by default. |

## Usage

1. Append the contents of `metrics.json` and `summaryrules.json` to corresponding files in your experimentation-enabled repository.
1. Rename or update description of metrics. Caution should be exercised when editing the metric definition itself, as the definition is dependent on summary rule output format.
1. If this is your first time adding summary rules for Online experimentation, see [root `README.md`](../README.md) to overview metric synchronization and summary rule update.


## GenAI summary rule

The provided GenAI summary rule transforms all GenAI spans meeting OpenTelemetry semantic conventions into event-like logs consumable for Online Experimentation metrics.

To preview the output of this summary rule, run the query below on your application's log analytics workspace.

```sql
let otel_genai_semantic_convention_keys = dynamic(['gen_ai.operation.name','gen_ai.request.model', 'gen_ai.system','error.type','server.port','gen_ai.request.frequency_penalty', 'gen_ai.request.max_tokens','gen_ai.request.presence_penalty','gen_ai.request.stop_sequences','gen_ai.request.temperature','gen_ai.request.top_k','gen_ai.request.top_p','gen_ai.response.finish_reasons','gen_ai.response.id','gen_ai.response.model','gen_ai.usage.input_tokens','gen_ai.usage.output_tokens','server.address','gen_ai.openai.request.response_format','gen_ai.openai.request.seed','gen_ai.openai.request.service_tier','gen_ai.openai.response.service_tier']);
let otel_genai_deprecated_keys = dynamic(['gen_ai.usage.completion_tokens','gen_ai.usage.prompt_tokens']);
let other_supported_keys = dynamic(['gen_ai.response.model','gen_ai.openai.api_version']);
let supported_keys = set_union(otel_genai_semantic_convention_keys, otel_genai_deprecated_keys, other_supported_keys);
let targetingid_keys = dynamic(['traceloop.association.properties.TargetingId', 'traceloop.association.properties.targetingid', traceloop.association.properties.targeting_id' 'TargetingId','targetingid','targeting_id','targetingId']);
AppDependencies
| where Properties has "gen_ai.system"
| where Properties has "targetingid" or Properties has "targeting_id"
| extend  keys = bag_keys(Properties)
| extend newProperties = bag_remove_keys(Properties, set_difference(keys,supported_keys))
| extend TargetingId = max_of(tostring(Properties['TargetingId']),tostring(Properties['targetingid']),tostring(Properties['targeting_id']),tostring(Properties['traceloop.association.properties.TargetingId']),tostring(Properties['traceloop.association.properties.targetingid']),tostring(Properties['traceloop.association.properties.targeting_id']),tostring(Properties['traceloop.association.properties.targetingId']),tostring(Properties['targetingId']))
| extend OTELVersion = extract("otel([0-9.]+[0-9])",1,SDKVersion)
| extend newProperties = bag_merge(newProperties, bag_pack('SDKVersion',SDKVersion,'OTELVersion',OTELVersion, 'TargetingId',TargetingId, 'DurationMs',DurationMs, 'Success',Success,'Name',Name, 'ResutCode',ResultCode,'PerformanceBucket',PerformanceBucket, 'gen_ai.usage.tokens',max_of(toint(Properties['gen_ai.usage.input_tokens']),toint(Properties['gen_ai.usage.prompt_tokens']))+ max_of(toint(Properties['gen_ai.usage.output_tokens']),toint(Properties['gen_ai.usage.completion_tokens'])), 
'gen_ai.finish_reason.has.stop', Properties['gen_ai.response.finish_reasons'] has 'stop' , 
'gen_ai.finish_reason.has.tool_calls', Properties['gen_ai.response.finish_reasons'] has 'tool_calls', 
'gen_ai.finish_reason.has.content_filter', Properties['gen_ai.response.finish_reasons'] has 'content_filter', 
'gen_ai.finish_reason.has.length', Properties['gen_ai.response.finish_reasons'] has 'length'))
| extend Properties = newProperties
| project-away keys, newProperties, TargetingId, Data, DurationMs, Success, ResultCode, PerformanceBucket, Measurements, SyntheticSource, ReferencedType, Target, DependencyType, OTELVersion
| extend Name = 'gen_ai.otel.span'
```

## Extensions beyond semantic conventions:
For advanced use cases, it is possible to adapt the metric definitions and the summary rule query for use with instrumentation libraries that do not follow the current OpenTelemetry semantic conventions, or to push other types of spans into the custom `AppEvents_CL` table.
