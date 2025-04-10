# AppInsights Web API Metric Collection

The [AppInsights Web API metric collection](./metrics-appinsights-webapi-v0.1.0.json) defines common telemetry-based measures on HTTP dependencies and requests for backend services. It is meant to be used alongside the [provided summary rule](./summaryrules-v0.1.0.yaml), which processes and forwards these events to the `AppEvents_CL` table in Log Analytics for evaluation by Online Experimentation.

| AppInsights Web API metric collection version | Creation date | Metric collection | Summary rule |
| -------- | --------------| -------- | ------- |
| webapi | April 2025 | [metrics-appinsights-webapi-v0.1.0](./metrics-appinsights-webapi-v0.1.0.json) | [summaryrules-v0.1.0](./summaryrules-v0.1.0.yaml)

## Prerequisites

Ensure your application supports autoinstrumentation in Azure Monitor Application Insights and that it is enabled. For more details, refer to the documentation: [What is autoinstrumentation for Azure Monitor Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/codeless-overview).

## Metrics

The following metrics are defined in `metrics-appinsights-webapi-v0.1.0.json`:

| Display name | Metric type | Description | Default lifecycle |
| ------- | ------- | ------ | ------ | 
| Number of users | UserCount | Counts unique users who made at least one request to your application. Essential for understanding application reach, adoption, and usage patterns. | Active |
| Number of request calls | EventCount | Counts the total number of incoming HTTP requests received by your application. This fundamental metric helps comparing traffic, understand usage patterns, and monitor system load. | Active |
| Number of dependency calls | EventCount | Counts the total number of outbound calls from your application to external dependencies such as databases, APIs, or other services. Useful for comparing system load and identifying potential bottlenecks. | Active |
| Number of exceptions | EventCount | Tracks all exceptions captured by Application Insights. This metric is essential for identifying stability issues, monitoring error trends, and improving application reliability. | Inactive |
| Request success rate | EventRate | Measures the percentage of successful HTTP requests to your application. This metric is crucial for understanding application reliability. A high success rate indicates a healthy application, while a low rate may signal issues that need attention. | Active |
| Dependency success rate | EventRate | Measures the percentage of successful calls to external dependencies. This metric is crucial for understanding the reliability of your application's interactions with external services. | Active |
| Average dependency call duration [ms] | Average | Measures the average time in milliseconds required to complete calls to external dependencies like databases, external APIs, or other services. This is a fundamental performance indicator that helps identify slowdowns in external systems. | Active |
| Average request call duration [ms] | Average | Measures the average time in milliseconds required to process incoming HTTP requests from receipt to response completion. This core performance metric directly impacts user experience and perceived application speed. | Active |
| Median dependency call duration [ms] | Percentile | Measures the median (50th percentile) time in milliseconds required to complete calls to external dependencies. Unlike average duration, median is less affected by outliers, providing a more representative view of typical performance. | Active |
| Median request call duration [ms] | Percentile | Measures the median (50th percentile) time in milliseconds required to process incoming HTTP requests. Unlike average duration, median is less affected by outliers, providing a more representative view of typical performance. | Active |
| P90 dependency call duration [ms] | Percentile | A performance metric where 90% of all dependencies complete faster than this value (measured in milliseconds). This provides visibility into slower user experiences while filtering out extreme outliers. | Inactive |
| P90 request call duration [ms] | Percentile | A performance metric where 90% of all requests complete faster than this value (measured in milliseconds). This provides visibility into slower user experiences while filtering out extreme outliers. | Inactive |

## Summary rule

If this is your first time adding a Log Analytics summary rule for Online Experimentation, see  [root `README`](../README.md). An example of setting up the configured bicep template can be found in the Online Experimentation [sample application code](https://github.com/Azure-Samples/openai-chat-app-eval-ab/blob/main/infra/main.bicep).

To update summary rules directly through Log Analytics API, or to manage or delete summary rules, see [Log Analytics](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/summary-rules?tabs=api) documentation.

To preview the output of the summary rule in advance, copy the query from [`summaryrules-{version}.yaml`] and paste into your application's Log Analytics workspace.

## Help
For questions or issues with Application insights WebAPI metrics, contact [exp-preview-fb@microsoft.com](mailto:exp-preview-fb@microsoft.com).
