# Custom metric collections

Custom metric collections are organized by metric topic. It is recommended for most products to adopt at least one metric from each topic in order to broaden measurement coverage.

## Prerequisites

### Instrumentation
Custom metrics rely on custom event logs that are instrumented via App Configuration's `TrackEvent` (or `track_event` in Python) and sent to Azure Monitor Analytics Logs. App Configuration's extension on [Azure Monitor custom event tracking](https://learn.microsoft.com/en-us/dotnet/api/microsoft.applicationinsights.telemetryclient.trackevent) accepts an event name (string) and an optional string dictionary of key:value properties and automatically attaches `TargetingId` as a property for each event. Events without `TargetingId` cannot be used for online experimentation metrics. 

Required event name and property references for each metric collection are stated in each section. If events use alternative naming conventions, the metric definition field should be edited to match existing instrumentation.

* The sample application [`OpenAI Chat App`](https://github.com/Azure-Samples/openai-chat-app-eval-ab) contains examples for custom event tracking in python applications.
* The [supplemental tutorial](.instrumentation-tutorial-from-app-configuration.md) demonstrates instrumentation in context for a .NET application. 
* Azure Monitor Logs charge based on data ingested. See [pricing](https://azure.microsoft.com/en-us/pricing/details/monitor/).


### GitHub action for metric deployment

Deployment of online experimentation metrics is managed by configuring the [Deploy Metrics](https://github.com/Azure/online-experimentation-deploy-metrics) GitHub Action in your experimentation-enabled repository.

## Use

1. Browse for sample metrics similar to your intended target.
1. Review the `eventName(s)` and attributes referenced in `condition` and `filter` expressions.
    - [If necessary] add instrumentation in your app using [Azure Monitor custom event tracking](https://learn.microsoft.com/en-us/dotnet/api/microsoft.applicationinsights.telemetryclient.trackevent). App Configuration provides a telemetry client that automatically adds the required TargetingId property to every event.     A sample for Python is available [here](https://github.com/Azure-Samples/quote-of-the-day-python/blob/main/src/quoteoftheday/routes.py). 
1. Copy the desired metric configurations into your metric configuration file(s) under your experimentation-enabled repository. Edit with the following in mind:
    - Metrics depend on the event name (encoded as `EventName`) to identify the relevant event types. 
    - Most metrics also depend on selected attributes from the Track        as filters or numeric values. `StatusCode == 400` is equivalent to `Properties['StatusCode'] == 400`
    - Ensure the `"lifecycle"` is set to `"Active"` in order to enable the metric computation.
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
|`UserFeedback` | `Score` (numeric): the numeric score. Recommended to use +1 for positive feedback and -1 for negative feedback. |


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
| `ErrorLLM` | `Code` (str): the descriptive code of the error e.g. "content_filter", `StatusCode` (int): the numeric code of the error e.g. 400 | 

A generic error event (not specific to LLM calls) is a good alternative if adding instrumentation for all error handling.

