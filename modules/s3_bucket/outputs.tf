#
#(c) 2024 Digital Commercial Platform, Inc. All Rights Reserved.

#This code is subject to the terms of the AWS Professional- Framework Statement of Work between Digital Commercial
#Platform, Inc. and Amazon Web Services EMEA SARL and Amazon Web Services EMEA SARL, succursale française that
#supplements the Amended and Restated Enterprise Agreement signed November 20, 2022 between AXA Group Operations SAS
#and Amazon Web Services EMEA SARL.
#

output "id" {
  value       = aws_s3_bucket.bucket.id
  description = "ID of S3 bucket"
}

output "name" {
  value       = aws_s3_bucket.bucket.bucket
  description = "Name of S3 bucket"
}

output "arn" {
  value       = aws_s3_bucket.bucket.arn
  description = "ARN of S3 bucket"
}


output "regional_domain_name" {
  value       = aws_s3_bucket.bucket.bucket_regional_domain_name
  description = "Regional domain name of S3 bucket"
}