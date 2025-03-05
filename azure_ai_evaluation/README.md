# Azure AI Evaluation metric collection

Metrics contained in the Azure AI Evaluation [metric collection](./metric-azure-ai-evaluation.json) are quality and safety measures for large language model outputs. They are meant to be used, in combination with the [provided](./summary_rules-v0.1.0.yaml) Log Analytics [summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api), directly out-of-box with minimal edits. They consume evaluation spans created by the [Azure AI Foundry SDK](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/online-evaluation?tabs=windows).

## Prerequisites

### Instrumentation

1. To use these metrics and summary rule, you must use the Azure AI Evaluation services which are part of the Azure AI Foundry SDK.

   [Azure AI Evaluation](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/online-evaluation?tabs=windows) provides automatic online evaluation of LLM responses for quality and safety measures.

2. `TargetingId` must be associated with your GenAI spans that are being evaluated.
   
   You can add the TargetingId to your GenAI spans the same way as described in the [GenAI documentation](../genai/README.md). The evaluation spans will be automatically associated with the TargetingId of the original GenAI call.

3. Azure AI Evaluation spans must be sent to Azure Monitor, and be accessible in the Log Analytics workspace configured for use with Online Experimentation. Confirm this by running a query like the one below in your Log Analytics workspace:

   ```kusto
   AppTraces
   | where TimeGenerated > ago(3d)
   | where Properties has "gen_ai.evaluation."
   | take 10
   ```

   Results should be non-empty and show evaluation events with scores.

### GitHub action for metric deployment

Deployment of online experimentation metrics is managed by configuring the [Deploy Metrics](https://github.com/Azure/online-experimentation-deploy-metrics) GitHub Action in your experimentation-enabled repository.

### Log Analytics summary rule

A summary rule is used to preprocess Azure AI Evaluation traces for metric computation. To confirm if your product has already configured a valid summary rule for Azure AI Evaluation, look for the `AppEvents_CL` table in your Log Analytics workspace and results with rule name `Online-Experimentation-GenAI-eval`.

If you do not see the table:
* If you provisioned the summary rule within the last 1 hour, you may need to wait for traces to be processed.
* If you have not added targeting id to the GenAI spans that are being evaluated, the summary rule will have no outputs.
* If you have never configured a valid summary rule for Azure AI Evaluation spans, you will need to provision this. This can be done via Log Analytics API call, or via bicep, as described in [root `README`](../README.md).

## Deploy metrics

1. Add the contents of `metric-azure-ai-evaluation.json` to corresponding files in your experimentation-enabled repository.
2. Optionally: modify metrics. Rename or update description of metrics. You can set desired Inactive metrics as Active if they apply to your scenario.
3. If this is your first time adding summary rules for Online Experimentation, see [root `README.md`](../README.md) to overview metric and summary rule deployment, with more details in [Online Experimentation documentation](https://aka.ms/exp/public/docs).

## Azure AI Evaluation metrics

The following metrics are defined in `metric-azure-ai-evaluation.json`:

| Display name | Metric kind | Description | Default lifecycle |
| ------------ | ----------- | ----------- | ---------------- |
| Protected material score | Average | Uses the Azure AI content safety API to scan LLM outputs for protected material. It detects and flags sensitive content, helping ensure compliance with content safety standards. | Active |
| Hate unfairness score | Average | Evaluates hateful and unfair language, addressing biases related to race, gender, ethnicity, and more. The score, derived from a 0-7 scale, helps in mitigating inequitable representations. | Active |
| Sexual content score | Average | Quantifies the presence of sexual content in generated text. The score ranges from 0 (no content) to 7 (high content), providing a basis for moderating explicit output. | Active |
| Violent content score | Average | Assesses the level of violent content within LLM outputs. With a range from 0 to 7, it supports moderation efforts by flagging high-violence scenarios. | Active |
| Relevance score | Average | Measures how well the response captures the key points of the input context. Scores range from 1 to 5, where higher scores indicate more contextually accurate and coherent outputs. | Active |
| Fluency score | Average | Evaluates the grammatical correctness, syntax, and overall fluency of generated text. Rated on a scale from 1 to 5, this metric reflects the linguistic quality of the output. | Active |
| Coherence score | Average | Assesses the logical flow and natural readability of generated responses. It indicates how well the text is structured and if it resembles human-like language. | Active |

## Summary rule for Azure AI Evaluation spans

The summary rule for Azure AI Evaluation spans processes evaluation data and prepares it for metric calculation. To preview the output of the summary rule in advance, copy the query from `summary_rules-v0.1.0.yaml` and paste it into your application's Log Analytics workspace.

The rule extracts evaluation events from `AppTraces`, captures the evaluation scores, and associates them with the corresponding GenAI response and TargetingId.

## Help
For questions or issues with Azure AI Evaluation metrics, contact [exp-preview-fb@microsoft.com](mailto:exp-preview-fb@microsoft.com).

### Azure AI Evaluation

[Metric file](./metric-azure-ai-evaluation.json)

This metric collection is powered by the [Azure AI Foundry SDK](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/online-evaluation?tabs=windows) and is designed to assess the quality and safety of outputs generated by large language models. The metrics evaluate content safety (e.g., detection of protected material, hate/unfair content, sexual and violent content) as well as linguistic quality measures (relevance, fluency, and coherence).