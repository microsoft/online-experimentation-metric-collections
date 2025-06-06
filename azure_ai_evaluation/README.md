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

The following metrics are defined in `metrics-azure-ai-evaluation-v0.1.0.json`:

| Display name | Metric kind | Description | Default lifecycle |
| ------------ | ----------- | ----------- | ---------------- |
| Task adherence score | Average | Assesses how well an AI-generated response follows the assigned task in terms of alignment with instructions and definitions, accuracy and clarity, and proper use of provided tool definitions. Scoring is on a five-level integer scale: 0 – Fully Inadherent, 1 – Barely Adherent, 2 – Moderately Adherent, 3 – Mostly Adherent, and 4 – Fully Adherent. | Active |
| Self-harm score | Average | Analyzes a single turn or multi-turn conversation for content related to self-injury or suicide and returns an integer score from 0 (Very Low) to 7 (High). Higher values represent increasingly explicit, encouraging, or instructional self-harm content, while lower values cover purely informational mentions. | Active |
| Protected material score | Average | Uses the Azure AI content safety API to scan the output of large language models to identify and flag known protected material. It detects and flags sensitive content, helping ensure compliance with content safety standards. | Active |
| Hate unfairness score | Average | Evaluates hateful and unfair language pertaining to hate toward or unfair representations of individuals and social groups along factors including but not limited to race, ethnicity, nationality, gender, sexual orientation, religion, immigration status, ability, personal appearance, and body size. Safety evaluations use a 0-7 scale. | Active |
| Sexual content score | Average | Quantifies the presence of sexual content in generated text. The score ranges from 0 to 7, providing a basis for moderating explicit output. | Active |
| Violent content score | Average | Assesses the level of violent content within LLM outputs. Violence score ranges from 0 to 7, supporting moderation efforts by flagging high-violence scenarios. | Active |
| Relevance score | Average | Assesses the ability of answers to capture the key points of the context. High relevance scores signify the AI system's understanding of the input and its capability to produce coherent and contextually appropriate outputs. Conversely, low relevance scores indicate that generated responses might be off-topic, lacking in context, or insufficient in addressing the user's intended queries. Relevance scores range from 1 to 5. | Active |
| Fluency score | Average | Assesses the extent to which the generated text conforms to grammatical rules, syntactic structures, and appropriate vocabulary usage, resulting in linguistically correct responses. The fluency score ranges from 1 to 5. | Active |
| Coherence score | Average | Assesses the ability of the language model to generate text that reads naturally, flows smoothly, and resembles human-like language in its responses. Use it when assessing the readability and user-friendliness of a model's generated responses in real-world applications. Scores range from 1 to 5. | Active |
| Retrieval score | Average | Measures how effectively an AI system selects and ranks the most relevant information for a query or multi-turn conversation (e.g., in RAG scenarios). Scores range from 1 (worst) to 5 (best). High scores indicate that the system surfaces the top-ranked, contextually relevant chunks without introducing bias from external knowledge, whereas low scores suggest poor ranking and/or biased, fact-insensitive retrieval. | Active |
| Groundedness score | Average | Checks how well each claim in the model's response is substantiated by the supplied context; factually correct but unsupported statements are marked ungrounded. Use this metric to verify that answers align with and are validated by the provided sources. Scores range from 1 (least grounded) to 5 (most grounded). | Active |

## Summary rule for Azure AI Evaluation spans

The summary rule for Azure AI Evaluation spans processes evaluation data and prepares it for metric calculation. To preview the output of the summary rule in advance, copy the query from `summary_rules-v0.1.0.yaml` and paste it into your application's Log Analytics workspace.

The rule extracts evaluation events from `AppTraces`, captures the evaluation scores, and associates them with the corresponding GenAI response and TargetingId.

## Help
For questions or issues with Azure AI Evaluation metrics, contact [exp-preview-fb@microsoft.com](mailto:exp-preview-fb@microsoft.com).

### Azure AI Evaluation

[Metric file](./metric-azure-ai-evaluation.json)

This metric collection is powered by the [Azure AI Foundry SDK](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/online-evaluation?tabs=windows) and is designed to assess the quality and safety of outputs generated by large language models. The metrics evaluate content safety (e.g., detection of protected material, hate/unfair content, sexual and violent content) as well as linguistic quality measures (relevance, fluency, and coherence).