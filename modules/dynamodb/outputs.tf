#
#(c) 2024 Digital Commercial Platform, Inc. All Rights Reserved.

#This code is subject to the terms of the AWS Professional- Framework Statement of Work between Digital Commercial
#Platform, Inc. and Amazon Web Services EMEA SARL and Amazon Web Services EMEA SARL, succursale française that
#supplements the Amended and Restated Enterprise Agreement signed November 20, 2022 between AXA Group Operations SAS
#and Amazon Web Services EMEA SARL.
#

output "arn" {
  value       = resource.aws_dynamodb_table.table.arn
  description = "ARN of the dynamo db table"
}

output "stream_arn" {
  value       = resource.aws_dynamodb_table.table.stream_arn
  description = "ARN of the dynamo db table stream"
}