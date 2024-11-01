# TraceloopSDK -- Generative AI Metric Collection
This metric collection provides foundation metrics for chats, embeddings, and tool calls when TraceloopSDK is used.

## Instrumentation provider details
- Instrumentation Provider: [Traceloop/OpenLLMetry](https://github.com/traceloop/openllmetry)
- Version(s) known to be supported: v0.33.2


## Prerequisites

`TargetingId` must be added. Traceloop supports this by [association entity](https://www.traceloop.com/docs/openllmetry/tracing/association) onto Traceloop logs. 

> [!IMPORTANT]
> Summary rule provisioning is required to use metrics in this collection. If this is your first time adding a [Log Analytics summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api) for Online Experimentation, see [root `README`](../README.md) for overall guidance.

To update an existing summary rule:
1. Copy the entry into the `summaryrules.json` file in your experimentation-enabled workspace under the `infra` folder.  
1. If necessary, modify the query `let` statement to reference your `TargetingId` property name.


## Sample of summary rule query output

Other columns are also included. Metrics primarily reference the event's Name and Properties.

| TimeGenerated| OperationId| Name | Properties |
|-----|---|----|----|
| 2024-10-21T23:46:18.850667Z | 25b8186c720e7d0d6e44aa92c7ccd02f | traceloop.chat | *See property bag below |

```json
Properties: 
{"llm.request.type":"chat",
"traceloop.association.properties.TargetingId":"f6f51071-1f4e-4487-b634-7b3d0996f91a",
"gen_ai.system":"OpenAI",
"gen_ai.request.model":"gpt-4o-mini",
"llm.headers":"None",
"llm.is_streaming":"True",
"gen_ai.openai.api_base":"https://uejch3htj6fxc-cog.openai.azure.com//openai/",
"gen_ai.openai.api_version":"2024-02-15-preview",
"gen_ai.prompt.0.role":"system",
"gen_ai.prompt.1.role":"user",
"gen_ai.usage.completion_tokens":"148",
"gen_ai.usage.prompt_tokens":"27",
"llm.usage.total_tokens":"175",
"gen_ai.response.model":"gpt-4o-mini",
"gen_ai.prompt.prompt_filter_results":"[{\"prompt_index\": 0, \"content_filter_results\": {\"hate\": {\"filtered\": false, \"severity\": \"safe\"}, \"jailbreak\": {\"filtered\": false, \"detected\": false}, \"self_harm\": {\"filtered\": false, \"severity\": \"safe\"}, \"sexual\": {\"filtered\": false, \"severity\": \"safe\"}, \"violence\": {\"filtered\": false, \"severity\": \"safe\"}}}]",
"gen_ai.completion.0.finish_reason":"stop",
"gen_ai.completion.0.content_filter_results":"{\"hate\": {\"filtered\": false, \"severity\": \"safe\"}, \"self_harm\": {\"filtered\": false, \"severity\": \"safe\"}, \"sexual\": {\"filtered\": false, \"severity\": \"safe\"}, \"violence\": {\"filtered\": false, \"severity\": \"safe\"}}",
"gen_ai.completion.0.role":"assistant",
"_MS.ResourceAttributeId":"5413f215-288e-4047-89e5-c666183171d4",
"gen_ai.completion.0.content_filter_results.hate.filtered":false,
"gen_ai.completion.0.content_filter_results.hate.severity":"safe",
"gen_ai.completion.0.content_filter_results.self_harm.filtered":false,
"gen_ai.completion.0.content_filter_results.self_harm.severity":"safe",
"gen_ai.completion.0.content_filter_results.sexual.filtered":false,
"gen_ai.completion.0.content_filter_results.sexual.severity":"safe",
"gen_ai.completion.0.content_filter_results.violence.filtered":false,
"TargetingId":"f6f51071-1f4e-4487-b634-7b3d0996f91a",
"gen_ai.usage.custom.io_tokens":null,
"DurationMS":2059,
"Success":true,
"ResultCode":"0",
"PerformanceBucket":"1sec-3sec"}
```
