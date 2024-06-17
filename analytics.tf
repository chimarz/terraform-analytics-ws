module "analytics" {
  source        = "./modules/analytics"
  workload_name = "event-processing"
  s3_arn        = module.source.arn
  partitioning_key = ""
}

module "source" {
  source      = "./modules/s3_bucket"
  name_prefix = "event-processing-source-"
}