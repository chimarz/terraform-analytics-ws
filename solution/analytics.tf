module "analytics" {
  source               = "./modules/analytics"
  workload_name        = "event-processing"
  buffering_interval   = 100
}

module "dynamo" {
  source = "./modules/dynamodb"
  table_name = "Assets"
  hash_key   = "tenantId"
  range_key  = "assetId"
}

