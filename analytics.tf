locals {
  processor = "processor"
}

module "analytics" {
  source               = "./modules/analytics"
  workload_name        = "event-processing"
  partitioning_key     = "event"
  buffering_interval   = 100
}

module "dynamo" {
  source = "./modules/dynamodb"
  table_name = "Assets"
  hash_key   = "tenantId"
  range_key  = "assetId"
}

