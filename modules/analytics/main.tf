#
# EventBridge resources (previously named CloudWatch Event)
# EventBridge rule, contains a pattern defining how to filter events
resource "aws_cloudwatch_event_rule" "events_capture_rule" {
  name_prefix    = "${var.workload_name}_"
  description    = "Capture events and trigger firehose execution."
  event_bus_name = "default"
  role_arn       = aws_iam_role.eventbridge_role.arn
  event_pattern  = jsonencode({
      "source": ["aws.s3"]
  })
}

# EventBridge target. Defines where events that match the rule should be delivered.
resource "aws_cloudwatch_event_target" "events_capture_target" {
  rule           = aws_cloudwatch_event_rule.events_capture_rule.name
  event_bus_name = "default"
  arn            = aws_kinesis_firehose_delivery_stream.firehose_stream.arn
  role_arn       = aws_iam_role.eventbridge_role.arn
}

#
# Firehose resources
#
# Firehose delivery stream that processes events received and uploads to S3.
# TODO: edit prefix/key if any
resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name        = "${var.workload_name}-firehose-stream"
  destination = "extended_s3"

  server_side_encryption {
    enabled  = "true"
    key_type = "CUSTOMER_MANAGED_CMK"
    key_arn  = module.firehose_key.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = module.s3_sink_bucket.arn
    buffering_size = 64
    buffering_interval = var.buffering_interval

    dynamic_partitioning_configuration {
      enabled = "true"
    }

    prefix              = "events/!{partitionKeyFromQuery:key}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/"

    processing_configuration {
      enabled = "true"

        processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # JQ processor
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{key:.detail.bucket.name}"
        }

      }
    }
  }
}

# KMS key for Firehose
module "firehose_key" {
  source      = "../kms"
  alias       = "cmk/firehosekey"
  description = "Firehose KMS key"
  roles       = [aws_iam_role.firehose_role.arn]
}

#
# IAM resources to allow EventBridge to deliver to Firehose
#
# IAM role for EventBridge
resource "aws_iam_role" "eventbridge_role" {
  name_prefix = "${var.workload_name}-role-"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "events.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
  })
}

# IAM inline policy attached to EventBridge role to invoke Firehose actions
resource "aws_iam_role_policy" "eventbridge_invoke_firehose_policy" {
  name_prefix = "${var.workload_name}-policy-"
  role        = aws_iam_role.eventbridge_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        "Resource" : [
          "${aws_kinesis_firehose_delivery_stream.firehose_stream.arn}"
        ]
      }
    ]
  })
}

# IAM role for Firehose
resource "aws_iam_role" "firehose_role" {
  name = "firehose-put-s3"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "firehose.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# IAM inline policy attached to Firehose role to invoke S3 actions
resource "aws_iam_role_policy" "firehose_put_s3_policy" {
  name = "firehose-put-s3-policy"
  role = aws_iam_role.firehose_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Action" : [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        "Resource" : [
          "${module.s3_sink_bucket.arn}",
          "${module.s3_sink_bucket.arn}/*"
        ]
      }
    ]
  })
}

#
# S3 bucket containing processed events
#
module "s3_sink_bucket" {
  source      = "../s3_bucket"
  name_prefix = "${var.workload_name}-sink-"
}
