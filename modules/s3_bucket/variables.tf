#
#(c) 2024 Digital Commercial Platform, Inc. All Rights Reserved.

#This code is subject to the terms of the AWS Professional- Framework Statement of Work between Digital Commercial
#Platform, Inc. and Amazon Web Services EMEA SARL and Amazon Web Services EMEA SARL, succursale française that
#supplements the Amended and Restated Enterprise Agreement signed November 20, 2022 between AXA Group Operations SAS
#and Amazon Web Services EMEA SARL.
#

variable "name_prefix" {
  type        = string
  description = "Prefix for the S3 Bucket's name, ensuring it's full name is unique"

}

variable "log_bucket" {
  type        = string
  description = "Target bucket for access logs (optional). If not provided, bucket will store log in itself"
  default     = null
}

variable "access_policy" {
  type        = string
  description = "Access policy for the bucket (in json)"
  default     = null
}

variable "kms_key_id" {
  type        = string
  description = "Optional ID of the KMS key"
  default     = null
}

variable "enable_eventbridge_notifications" {
  type        = bool
  default     = false
  description = "Enable or disable EventBridge notifications from the biucket. Defaults to false"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the bucket"
}