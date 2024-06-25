#
#(c) 2024 Digital Commercial Platform, Inc. All Rights Reserved.

#This code is subject to the terms of the AWS Professional- Framework Statement of Work between Digital Commercial
#Platform, Inc. and Amazon Web Services EMEA SARL and Amazon Web Services EMEA SARL, succursale française that
#supplements the Amended and Restated Enterprise Agreement signed November 20, 2022 between AXA Group Operations SAS
#and Amazon Web Services EMEA SARL.
#

locals {
  attributes = compact([var.hash_key, var.range_key])
}

data "aws_region" "current" {}


#
# CMK for table encryption
#
module "key" {
  source       = "../kms"
  alias        = "cmk/dynamodb/${var.table_name}"
  description  = "Key for dynamodb table"
  via_services = ["dynamodb.${data.aws_region.current.name}.amazonaws.com"]
  services     = ["dynamodb.amazonaws.com"]
}

#
# Dynamo table
#
resource "aws_dynamodb_table" "table" {
  name             = var.table_name
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = var.hash_key
  range_key        = var.range_key
  stream_enabled   = var.stream_enabled
  stream_view_type = "NEW_AND_OLD_IMAGES"

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = module.key.arn
  }

  dynamic "attribute" {
    for_each = local.attributes
    iterator = attribute
    content {
      name = attribute.value
      type = "S"
    }
  }

  dynamic "attribute" {
    for_each = var.attributes
    iterator = attribute
    content {
      name = attribute.value["name"]
      type = attribute.value["type"]
    }
  }

  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indices
    iterator = local_index
    content {
      name            = local_index.value["name"]
      range_key       = local_index.value["range_key"]
      projection_type = "ALL"
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indices
    iterator = global_index
    content {
      name            = global_index.value["name"]
      hash_key        = global_index.value["hash_key"]
      range_key       = global_index.value["range_key"]
      projection_type = "ALL"
    }
  }
}