# Custom metric collections

Metric samples in this folder are evolving, based on experimenter input. 

Custom metric collections are organized by metric topic. It is recommended for most products to adopt at least one metric from each topic in order to broaden measurement coverage.

## Prerequisites

Custom metrics rely on event logs that are instrumented via AppConfig's `TrackEvent` (or `track_event` in Python). This instrumentation through AppConfig is a wrapper of Azure Monitoring event tracking and guarantees the `TargetingId` will be attached to events. This attachment of `TargetingId` is required in order to attribute events to each user's assigned feature flags.

Metrics in this collection will not work out-of-box. Event logging must be added. Event name and property references are stated in each section and should be implemented in telemetry; or the metric itself should be edited to match existing instrumentation.


## Use

1. Browse for sample metrics similar to your intended target.
2. Review the `eventName(s)` and attributes referenced in `condition` and `filter` expressions.
    - [If necessary] add instrumentation in your app using [custom event tracking for AppConfig](https://learn.microsoft.com/en-us/azure/azure-app-configuration/run-experiments-aspnet-core). A sample for Python is available [here](https://github.com/Azure-Samples/quote-of-the-day-python/blob/main/src/quoteoftheday/routes.py). 
4. Copy the desired metric configurations into your metric configuration file(s) under your experimentaton-enabled repository. Edit with the following in mind:
    - Metrics depend on the `Name` (encoded as `EventName`) to identify the relevant event types. 
    - Most metrics also depend on selected attributes from the `Properties` property bag as filters or numeric values. `StatusCode == 400` is equivalent to `Properties['StatusCode'] == 400`
    - Ensure the `"lifecycle"` is set to `"Active"` in order to enable the metric computation.
5. Upon next run of your metric sync action, the metrics will be pushed for computation in all subsequent scorecards. Metrics can be disabled later through deletion or by setting the `"lifecycle"` to `"Inactive"`.



## User sentiment metrics
[Metric file](./metrics/user-sentiment.json) 

Metrics in this collection measure user sentiment. User sentiment can be inferred or collected directly via user feedback.

<details open>
<summary>User feedback</summary>

User feedback should be logged as a numeric score from -1(negative) to +1(positive). Common implementation is thumbs-up/thumbs-down which translate to +1/-1 scores.

Sample (AppConfig, via python) implementation of telemetry for user feedback metrics defined in this folder:

```
track_event("UserFeedback", chat_id, {"Score": score})
```

This event tracking is triggered after user hits a thumbs up/down feedback button on a chat response.

| Display name| Metric kind | Description |
| ----- | -----| ----------------|
| Feedback event count | EventCount |  The total number of feedbacks received from users (clicked thumbs-up or thumbs-down). |
| Users who gave feedback | UserCount | The number of users who gave at least one feedback (clicked thumbs-up or thumbs-down).|
| Positive feedback rate | EventRate | The percentage of feedback which is positive (thumbs-up). |
| Negative feedback rate | EventRate | The percentage of feedback which is negative (thumbs-down).|
</details>


## Errors

[Metric file](./metrics/errors.json)

Metrics in this collection illustrate metrics for tracking errors and related events as guardrails to limit unintended degradation in system performance. Metrics in this category require customized AppConfig event tracking for error handling.

<details open>
<summary>Error metrics</summary>

A sample `ErrorLLM` event is referenced in all error metrics, which has properties `Code` (str) and `StatusCode` (int). A generic error event (not specific to LLM calls) is a good alternative if adding instrumentation for all error handling.

| Display name| Metric kind | Description |
| ----- | -----| ----------------|
| LLM error count | EventCount | The total number of errors resulting from LLM calls. |
| LLM 400 error count | EventCount | The number of LLM requests that resulted in a 400 error. |
| Users with LLM 400 error | UserCount | The number of users with at least one LLM request that resulted in a 400 error. |
| LLM error count -- content filter | EventCount | The total number of errors with code indicating content filtering blocked LLM response. |

</details>
