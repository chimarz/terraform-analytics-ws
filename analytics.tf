module "analytics" {
  source             = "./modules/analytics"
  workload_name      = "event-processing"
  s3_arn             = module.source.arn
  partitioning_key   = "event"
  buffering_interval = 100
}

module "source" {
  source                           = "./modules/s3_bucket"
  name_prefix                      = "event-processing-source-"
  enable_eventbridge_notifications = "true"
}