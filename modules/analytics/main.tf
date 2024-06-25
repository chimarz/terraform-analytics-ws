data "aws_region" "current" {}

#
# EventBridge resources (previously named CloudWatch Event)
# EventBridge rule, contains a pattern defining how to filter events
resource "aws_cloudwatch_event_rule" "events_capture_rule" {
  name_prefix    = "${var.workload_name}_"
  description    = "Capture events and trigger firehose execution."
  event_bus_name = "default"
  role_arn       = aws_iam_role.eventbridge_role.arn
  event_pattern  = jsonencode({
    "source" : ["asset-service"],
    "detail-type" : ["new-asset-event"]
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
    bucket_arn = module.s3_source_bucket.arn
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
        "Sid" : "S3Access",
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
          "${module.s3_source_bucket.arn}",
          "${module.s3_source_bucket.arn}/*"
        ]
      },
            {
        "Sid" : "LambdaAccess",
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

#
# S3 bucket containing source
#
module "s3_source_bucket" {
  source      = "../s3_bucket"
  name_prefix = "${var.workload_name}-source-"
}

#
# S3 bucket containing source
#
module "s3_sink_bucket" {
  source      = "../s3_bucket"
  name_prefix = "${var.workload_name}-sink-"
}

#
# S3 bucket containing code for Glue job
#
module "etl_bucket" {
  source      = "../s3_bucket"
  name_prefix = "${var.workload_name}-etl-"
}

resource "aws_s3_object" "etl_bucket_execution_code" {
  bucket = module.etl_bucket.name
  key    = "etl.py"
  source = "etl.py"
  etag   = filemd5("etl.py")
}

# Glue job
#
resource "aws_glue_job" "transformation_job" {
  name         = "transformation_job"
  role_arn     = aws_iam_role.glue_service_role.arn
  glue_version = "3.0"

  command {
    script_location = "s3://${module.etl_bucket.name}/etl.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"        = "python"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--s3_raw_bucket"       = "s3://${module.s3_source_bucket.name}/"
    "--s3_processed_bucket" = "s3://${module.s3_sink_bucket.name}/"
    "--event_type"          = "executions_parquet_table"
  }

  execution_property {
    max_concurrent_runs = 10
  }

  number_of_workers      = 10
  worker_type            = "G.1X"

}

# Glue service role
resource "aws_iam_role" "glue_service_role" {
  name = "glue-service-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "glue.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [data.aws_iam_policy.aws_glue_service_role.arn]
}

#
# Policy document
#
data "aws_iam_policy_document" "glue_s3_access_role_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [module.etl_bucket.arn, module.s3_sink_bucket.arn, module.s3_source_bucket.arn, "${module.etl_bucket.arn}/*", "${module.s3_sink_bucket.arn}/*", "${module.s3_source_bucket.arn}/*"]
  }
}

#
# Managed glue service role policy
#
data "aws_iam_policy" "aws_glue_service_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

#
# Policy allowing acess to s3
#
resource "aws_iam_role_policy" "glue_s3_access_role_policy" {
  name   = "glue-access-s3-policy"
  role   = aws_iam_role.glue_service_role.id
  policy = data.aws_iam_policy_document.glue_s3_access_role_policy_document.json
}

#
# Glue Catalog DB and table
#
resource "aws_glue_catalog_database" "glue_database" {
  name = "events"
}

resource "aws_glue_catalog_table" "executions_table" {
  name          = "eventss_parquet_table"
  database_name = aws_glue_catalog_database.glue_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = "s3://${module.s3_sink_bucket.name}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "executions"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "assetid"
      type = "string"
    }

    columns {
      name = "tenantid"
      type = "string"
    }
  }
}

