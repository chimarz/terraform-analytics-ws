# coding=utf-8
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ["JOB_NAME", "s3_raw_bucket", "s3_processed_bucket", "event_type"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

S3bucket_node1 = glueContext.create_dynamic_frame.from_options(
    format_options={"jsonPath": "$.detail", "multiline": False},
    connection_type="s3",
    format="json",
    connection_options={
        "paths": [args["s3_raw_bucket"]],
        "recurse": True,
    },
    transformation_ctx="S3bucket_node1",
)

S3bucket_node3 = glueContext.getSink(
    path=args["s3_processed_bucket"],
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=[],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(catalogDatabase="events", catalogTableName=args["event_type"])
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(S3bucket_node1)
job.commit()
