# Custom metric collections

Custom metric collections are organized by metric topic. It is recommended for most products to adopt at least one metric from each topic in order to broaden measurement coverage.

## Prerequisites

1. Instrumentation. See sample application [`OpenAI Chat App`](https://github.com/Azure-Samples/openai-chat-app-eval-ab) for example custom event tracking and configuring Azure Monitor OpenTelemetry to ensure events are sent to Log Analytics.
   
    * Azure Monitor Logs charge based on data ingested. See [pricing](https://azure.microsoft.com/en-us/pricing/details/monitor/).
    * If you use alternative instrumentation, ensure events are sent to Log Analytics `AppEvents` table, and ensure that App Configuration's `TargetingId` is provided as a property for each event. Events without this attribute cannot be used for online experimentation metrics. App Configuration's `TrackEvent` (`track_event` in Python) automatically adds this TargetingId.

       


1. GitHub action for metric deployment. See [Deploy Metrics](https://github.com/Azure/online-experimentation-deploy-metrics) GHA.

## Use

1. Browse for sample metrics similar to your intended target.
1. Add the desired metric configurations into your metric configuration file(s) under your experimentation-enabled repository. Edit metrics with the following in mind:
    * For full documentation about syntax for expressions in Online Experimentation metric definitions, see [Create and Manage Metrics](https://github.com/MicrosoftDocs/online-experimentation-docs/blob/54a6d5ef8ee1d124f3370d12d07d4c32858c1217/Documentation/Create%20and%20manage%20metrics.md)
    * Metrics depend on the event name (encoded as `EventName`) to identify the relevant event types.
    * Event attributes (properties) are used as filters to restrict events beyond the event name, values to provide a numeric value for average or sum metric aggregations, and conditions to provide the 'success' condition for an event rates.
        *  Reference attributes directly by their name. `StatusCode == 400` or `['StatusCode'] == 400`. Not `Properties['StatusCode'] == 400`
    * Ensure the `"lifecycle"` is set to `"Active"` in order to enable the metric computation.
1. Upon the next run of your GitHub Action Workflow, the metrics will be deployed for computation in all subsequent scorecards. Metrics can be disabled later through deletion or by setting the `"lifecycle"` to `"Inactive"`.


## Metric collections 

### User sentiment
[Metric file](./metrics-user-sentiment.json) 

This metric collection measures user sentiment. User sentiment can be inferred or collected directly via user feedback.

#### User feedback: metrics 
This set of metrics measures user thumbs up/down feedback button on a chat response.

| Display name| Metric kind | Description | Dependent logging event(s) |
| ----- | -----| ----------------|------|
| Feedback event count | EventCount |  The total number of feedbacks received from users (clicked thumbs-up or thumbs-down). | `UserFeedback`|
| Users who gave feedback | UserCount | The number of users who gave at least one feedback (clicked thumbs-up or thumbs-down).| `UserFeedback`|
| Positive feedback rate | EventRate | The percentage of feedback which is positive (thumbs-up). | `UserFeedback`|
| Negative feedback rate | EventRate | The percentage of feedback which is negative (thumbs-down).| `UserFeedback`|


#### User feedback: logging 
User feedback should be logged as a numeric score from -1(negative) to +1(positive). Common implementation is thumbs-up/thumbs-down which translate to +1/-1 scores.

| Event Name | Properties |
| -------- | -------- |
|`UserFeedback` | `Score` (numeric): the numeric score. <br> +1 for positive feedback, -1 for negative feedback. |


### Errors

[Metric file](./metrics-errors.json)

Metrics in this collection illustrate metrics for tracking errors and related events as guardrails to limit unintended degradation in system performance. Metrics in this category require customized App Configuration event tracking for error handling.

#### Errors: metrics

| Display name| Metric kind | Description | Dependent logging event(s) |
| ----- | -----| ----------------|------|
| LLM error count | EventCount | The total number of errors resulting from LLM calls. | `ErrorLLM` |
| LLM 400 error count | EventCount | The number of LLM requests that resulted in a 400 error. | `ErrorLLM` |
| Users with LLM 400 error | UserCount | The number of users with at least one LLM request that resulted in a 400 error. | `ErrorLLM` |
| LLM error count -- content filter | EventCount | The total number of errors with code indicating content filtering blocked LLM response. | `ErrorLLM` |

#### Errors: logging
Although errors may be logged by default in AppDependencies, Online Experimentation default consumes only the `AppEvents` table from Log Analytics Workspace.

Therefore, we recommend enriching with custom event logging for key error handling. Use App Configuration event tracking in order to attach the `TargetingId` by default.

| Event Name | Properties |
| -------- | -------- | 
| `ErrorLLM` | `Code` (str): the descriptive code of the error e.g. "content_filter" <br> `StatusCode` (int): the numeric code of the error e.g. 400 | 

A generic error event (not specific to LLM calls) is a good alternative if adding instrumentation for all error handling.

