# Azure AI Evaluation Metric Collection

Metrics contained in the Azure AI Evaluation [metric collection](./metric-azure-ai-evaluation.json) are quality and safety measures for AI agent outputs. They are meant to be used, in combination with the [provided](./summary_rules-v0.1.0.yaml) Log Analytics [summary rule](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api), directly out-of-the-box with minimal edits. They consume evaluation spans created by the [Azure AI Foundry SDK](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/online-evaluation?tabs=windows).

## Prerequisites

### Instrumentation

1. To use these metrics and the summary rule, you must use the Azure AI Evaluation services, which are part of the Azure AI Foundry SDK.

   [Azure AI Continuous Evaluation](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/online-evaluation?tabs=windows) provides automatic online evaluation of LLM responses for quality and safety measures.

2. `TargetingId` must be associated with the GenAI spans that are being evaluated.
   
   You can add the TargetingId to your GenAI spans the same way as described in the [GenAI documentation](../genai/README.md). The evaluation spans will be automatically associated with the TargetingId of the original GenAI call.

3. Azure AI Evaluation spans must be sent to Azure Monitor and be accessible in the Log Analytics workspace configured for use with online experimentation. Confirm this by running a query like the one below in your Log Analytics workspace:

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

A summary rule is used to preprocess Azure AI Evaluation traces for metric computation. To confirm whether your product has already configured a valid summary rule for Azure AI Evaluation, look for the `AppEvents_CL` table in your Log Analytics workspace and verify results with the rule name `Online-Experimentation-GenAI-eval`.

If you do not see the table:
* If you provisioned the summary rule within the last 1 hour, you may need to wait for traces to be processed.
* If you have not added a `TargetingId` to the GenAI spans that are being evaluated, the summary rule will have no outputs.
* If you have never configured a valid summary rule for Azure AI Evaluation spans, you will need to provision this. This can be done via Log Analytics API call, or via bicep, as described in [root `README`](../README.md).

## Deploy metrics

1. Add the contents of `metric-azure-ai-evaluation.json` to the corresponding files in your experimentation-enabled repository.
2. Optionally, modify the metrics: rename or update metric descriptions, and set any desired inactive metrics to active if they apply to your scenario.
3. If this is your first time adding summary rules for online experimentation, see [root `README.md`](../README.md) to overview metric and summary rule deployment, with more details in [online experimentation documentation](https://aka.ms/exp/public/docs).

## Azure AI Evaluation metrics

The following metrics are defined in `metrics-azure-ai-evaluation-v0.1.0.json`:

| Display Name | Metric Type | Description | Default Lifecycle |
| ------------ | ----------- | ----------- | ---------------- |
| Task adherence score | Average | Task adherence score given by Azure AI evaluation. The Task Adherence evaluator assesses how well an AI-generated response follows the assigned task in terms of alignment with instructions and definitions, accuracy and clarity, and proper use of provided tool definitions. Scoring is on a five-level integer scale: 0 – Fully Inadherent, 1 – Barely Adherent, 2 – Moderately Adherent, 3 – Mostly Adherent, and 4 – Fully Adherent. | Active |
| Self-harm score | Average | Self-harm score given by Azure AI evaluation. The evaluator analyzes a single turn or multi-turn conversation for content related to self-injury or suicide and returns an integer score from 0 (Very Low) to 7 (High). Higher values represent increasingly explicit, encouraging, or instructional self-harm content, while lower values cover purely informational mentions. | Active |
| Hate unfairness score | Average | Hate and unfair score given by Azure AI evaluation. Hateful and unfair content refers to any language pertaining to hate toward or unfair representations of individuals and social groups along factors including but not limited to race, ethnicity, nationality, gender, sexual orientation, religion, immigration status, ability, personal appearance, and body size. Unfairness occurs when AI systems treat or represent social groups inequitably, creating or contributing to societal inequities. Safety evaluations annotate self-harm-related content using a 0-7 scale. | Active |
| Sexual content score | Average | Score for sexual content given by Azure AI evaluation. Sexual score is range from 0 to 7. | Active |
| Violent content score | Average | Violence score given by Azure AI evaluation, Violence score is range from 0 to 7. | Active |
| Relevance score | Average | Relevance score given by Azure AI evaluation. The relevance measure assesses the ability of answers to capture the key points of the context. High relevance scores signify the AI system's understanding of the input and its capability to produce coherent and contextually appropriate outputs. Conversely, low relevance scores indicate that generated responses might be off-topic, lacking in context, or insufficient in addressing the user's intended queries. Relevance scores range from 1 to 5. | Active |
| Fluency score | Average | Fluency score given by Azure AI evaluation. The fluency measure assesses the extent to which the generated text conforms to grammatical rules, syntactic structures, and appropriate vocabulary usage, resulting in linguistically correct responses. The fluency score range from 1 to 5. | Active |
| Coherence score | Average | Coherence score given by Azure AI evaluation. The coherence measure assesses the ability of the language model to generate text that reads naturally, flows smoothly, and resembles human-like language in its responses. Use it when assessing the readability and user-friendliness of a model's generated responses in real-world applications. | Active |
| Indirect attack score | Average | Indirect attack score given by Azure AI evaluation. This evaluator analyzes a single-turn or multi-turn conversation to detect cross-domain prompt-injection attacks (also called indirect or XPIA jailbreaks) that are embedded in the supplied context. Indirect attacks are grouped into three subcategories: (1) Manipulated Content – commands that alter, fabricate, hide, or emphasize information to mislead or deceive; (2) Intrusion – commands that attempt to breach systems, gain unauthorized access, or escalate privileges (e.g., traditional jailbreaks, backdoors, vulnerability exploits); and (3) Information Gathering – actions that access, delete, or modify data without authorization, including data exfiltration and record tampering. The evaluator returns a boolean value where true indicates that the response contains an indirect attack. | Active |
| Code vulnerability score | Average | Performs a single-turn vulnerability assessment on the assistant's code completion. Given the original user query (or pre-completion code) and the assistant's response, this metric scans the response for security flaws in Python, Java, C++, C#, Go, JavaScript, and SQL. It detects issues such as path, SQL, and code injection; reflected XSS; full SSRF; incomplete sanitization or hostname validation; server- or client-side open redirects; stack-trace exposure; Flask debug mode; clear-text logging or storage of sensitive data; tarslip; binding to all network interfaces; weak cryptographic algorithms; insecure randomness; hard-coded credentials; and other likely bugs. | Active |
| Intent resolution score | Average | The intent resolution evaluator assesses whether the user intent was correctly identified and resolved, spanning from 1 to 5. | Active |
| Tool call accuracy score | Average | Tool call accuracy score given by Azure AI evaluation. The Tool Call Accuracy evaluator measures whether tool calls made by the AI assistant are relevant to the conversation and use parameters exactly as defined. It returns 0 when the call is irrelevant or includes parameters not present in the conversation/definition, and 1 when the call is relevant with correctly extracted parameters. | Active |

## Summary rule for Azure AI Evaluation spans

The summary rule for Azure AI Evaluation spans processes evaluation data and prepares it for metric calculation. To preview the output of the summary rule in advance, copy the query from `summary_rules-v0.1.0.yaml` and paste it into your application's Log Analytics workspace.

The rule extracts evaluation events from `AppTraces`, captures the evaluation scores, and associates them with the corresponding GenAI response and TargetingId.

## Help
For questions or issues with Azure AI Evaluation metrics, contact [exp-preview-fb@microsoft.com](mailto:exp-preview-fb@microsoft.com).

### Azure AI Evaluation

[Metric file](./metric-azure-ai-evaluation.json)

This metric collection is powered by the [Azure AI Foundry SDK](https://learn.microsoft.com/en-us/azure/ai-studio/how-to/online-evaluation?tabs=windows) and is designed to assess the quality and safety of outputs generated by large language models. The metrics evaluate content safety (e.g., detection of protected material, hate/unfair content, sexual and violent content) as well as linguistic quality measures (relevance, fluency, and coherence).