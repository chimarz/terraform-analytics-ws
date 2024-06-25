#
#(c) 2024 Digital Commercial Platform, Inc. All Rights Reserved.

#This code is subject to the terms of the AWS Professional- Framework Statement of Work between Digital Commercial
#Platform, Inc. and Amazon Web Services EMEA SARL and Amazon Web Services EMEA SARL, succursale française that
#supplements the Amended and Restated Enterprise Agreement signed November 20, 2022 between AXA Group Operations SAS
#and Amazon Web Services EMEA SARL.
#

variable "table_name" {
  type        = string
  description = "Name of the table"
}

variable "hash_key" {
  type        = string
  description = "Hash key"
}

variable "range_key" {
  type        = string
  default     = null
  description = "Sort key"
}

variable "stream_enabled" {
  type        = bool
  default     = false
  description = "Enable streaming of changes (defaults to false)"
}

variable "attributes" {
  type        = list(any)
  default     = []
  description = "Include additional attributes and those used for secondary indices here"
}

variable "local_secondary_indices" {
  type        = list(any)
  default     = []
  description = "List of objects which each describe a local secondary index"
}

variable "global_secondary_indices" {
  type        = list(any)
  default     = []
  description = "List of objects which each describe a global secondary index"
}