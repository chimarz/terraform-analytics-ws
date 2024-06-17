# What is this module for?
This module creates following resources:
* EventBridge rule
* Kinesis Firehose 
* S3 bucket containing processed events


# How do I use it?
Simple usage:

```hcl
module "analytics" {
  source         = "../../modules/analytics"
  workload_name = "event_processing"
  s3_arn = "arn"
}
```

# Inputs
|Variable name|Required|Description|
|-------------|--------|-----------|
|s3_arn|Yes|ARN of S3 bucket receiving to be monitored.|
|workload_name|No|Name of workload. Used to name resources. **NOTE:** Does not accept spaces or uppercase characters!|
|
|lambda_arn|No|Optional ARN of lambda function performing the processing.|

# Outputs
|Output|Description|
|------|-----------|
|processed_bucket_name|Name of bucket that contains processed events.|
|processed_bucket_arn|ARN of bucket that contains processed events.|
|eventbridge_bus_name|Name of EventBridge bus created.|


# Ignored checkov warnings
|Warning|Description|Reason|
|---|---|---|



