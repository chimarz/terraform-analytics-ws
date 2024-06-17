variable "workload_name"{
    type = string
    description = "Name of the workload, is used to name resources. Does not accept spaces or uppercase characters."
    default = "analytics_workload"
}

variable "s3_arn" {
    type = string
    description = "ARN of S3 bucket receiving to be monitored."
}

variable "partitioning_key" {
    type = string
    description = "Partitioning key."
}