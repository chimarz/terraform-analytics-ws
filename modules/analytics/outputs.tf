output "processed_bucket_name" {
  value = module.s3_sink_bucket.name
}

output "processed_bucket_arn" {
  value = module.s3_sink_bucket.arn
}

output "eventbridge_bus_name" {
  value = "${var.workload_name}_bus"
}
