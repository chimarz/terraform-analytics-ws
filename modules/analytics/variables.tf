variable "workload_name"{
    type = string
    description = "Name of the workload, is used to name resources. Does not accept spaces or uppercase characters."
    default = "analytics_workload"
}

variable "partitioning_key" {
    type = string
    description = "Partitioning key."
}

variable "buffering_interval" {
    type = string
    description = "Firehose buffering interval. Optional, defaults to 300 seconds."
    default = 300
}