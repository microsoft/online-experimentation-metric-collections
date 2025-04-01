# AppInsights metric collection

The [AppInsights metric collection](./metrics-appinsights-v0.1.0.json) defines common telemetry-based measures on HTTP dependencies and requests. It is meant to be used alongside the [provided summary rule](./summaryrules-v0.1.0.yaml), which processes and forwards these events to the `AppEvents_CL` table in Log Analytics for evaluation by Online Experimentation.

## Prerequisites

1. Ensure your application sends `request` and `dependency` telemetry to Application Insights. By default, Azure Monitor instrumentation libraries do this automatically.
2. Ensure you are using the latest preview app config SDK. This SDK log AllocationId and VariantAssignmentPercentage in property for summary rule to work properly.

## Metrics

The JSON file [metrics-appinsights-v0.1.0.json](./metrics-appinsights-v0.1.0.json) contains definitions for:
- Count of dependency calls
- Average duration of dependency calls
- Count of request calls
- Average duration of request calls

Metrics are computed via the summary rule output in `AppEvents_CL`. Adjust filters to match your needs or rename them to fit your naming conventions.

### Errors
For error-related events, see [metrics-appinsights-errors-v0.1.0.json](./metrics-appinsights-errors-v0.1.0.json). It includes sample metrics focusing on HTTP status checks (e.g., 403, 404).

## Summary rule

The [summaryrules-v0.1.0.yaml](./summaryrules-v0.1.0.yaml) file contains a query that brings relevant dependency/request data from Application Insights into `AppEvents_CL`, which Online Experimentation automatically consumes. Ensure you keep the rule name consistent so only one valid summary rule is active.

## Deployment

1. Include these files in your GitHub repository used for experimentation.
2. Run your GitHub Actions deployment that calls [azure/online-experimentation-deploy-metrics](https://github.com/Azure/online-experimentation-deploy-metrics).
3. Verify the `AppEvents_CL` table in Log Analytics for data. Adjust filters or event names as needed.

## Questions or Feedback
Contact your team’s Azure Monitor or Online Experimentation owners for help with customizing metrics, or refer to the [Online Experimentation documentation](https://aka.ms/exp/public/docs).
