# Azure.AI.Inference SDK --  Generative AI Metric Collection
This metric collection provides foundation metrics for chats, embeddings, and tool calls when Azure AI Inference is used.

## Instrumentation provider details
- Instrumentation Provider: [Azure.AI.Inference](https://www.nuget.org/packages/Azure.AI.Inference/) with OpenTelemetry extension.
   - Python package: [azure-ai-inference](https://pypi.org/project/azure-ai-inference/)
- Version(s) known to be supported: v1.0.0-beta.1

## Prerequisites
TargetingId must be added as a decorator onto Azure.AI.Inference spans. 
Use the OpenTelemetry tracer functionality `@tracer.start_as_current_span()` to start a span and add in the TargetingId as an attribute. The summary rule will by default join this TargetingId across associated parent spans. 


> [!IMPORTANT]
> Summary rule provisioning is required to use metrics in this collection. If this is your first time adding a [Log Analytics summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api) for Online Experimentation, see [root `README`](../README.md) for overall guidance.

To update an existing summary rule:
1. Copy the entry into the `summaryrules.json` file in your experimentation-enabled workspace under the `infra` folder.  
1. If necessary, modify the query `let` statement to reference your `TargetingId` property name.

