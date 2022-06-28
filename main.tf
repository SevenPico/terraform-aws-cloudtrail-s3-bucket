
module "access_log_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name = "cloudtrail-access-log"

  context = module.this.context
}

module "s3_bucket" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "0.28.0"
  enabled = module.this.enabled

  access_log_bucket_name        = local.access_log_bucket_name
  acl                           = var.acl
  allow_ssl_requests_only       = var.allow_ssl_requests_only
  block_public_acls             = var.block_public_acls
  block_public_policy           = var.block_public_policy
  bucket_notifications_enabled  = var.bucket_notifications_enabled
  bucket_notifications_prefix   = var.bucket_notifications_prefix
  bucket_notifications_type     = var.bucket_notifications_type
  force_destroy_enabled         = var.force_destroy
  force_destroy                 = var.force_destroy
  ignore_public_acls            = var.ignore_public_acls
  kms_master_key_arn            = var.kms_master_key_arn
  lifecycle_configuration_rules = var.lifecycle_configuration_rules
  restrict_public_buckets       = var.restrict_public_buckets
  source_policy_documents       = [join("", data.aws_iam_policy_document.default.*.json)]
  sse_algorithm                 = var.sse_algorithm
  versioning_enabled            = var.versioning_enabled

  context = module.this.context
}

module "s3_access_log_bucket" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "0.28.0"
  enabled = module.this.enabled && var.create_access_log_bucket

  access_log_bucket_name        = ""
  acl                           = var.acl
  allow_ssl_requests_only       = var.allow_ssl_requests_only
  block_public_acls             = var.block_public_acls
  block_public_policy           = var.block_public_policy
  force_destroy_enabled         = var.force_destroy
  force_destroy                 = var.force_destroy
  ignore_public_acls            = var.ignore_public_acls
  kms_master_key_arn            = var.kms_master_key_arn
  lifecycle_configuration_rules = var.lifecycle_configuration_rules
  restrict_public_buckets       = var.restrict_public_buckets
  source_policy_documents       = []
  sse_algorithm                 = var.sse_algorithm
  versioning_enabled            = var.versioning_enabled

  attributes = ["access-logs"]
  context    = module.this.context
}

data "aws_iam_policy_document" "default" {
  count       = module.this.enabled ? 1 : 0
  source_policy_documents = compact([var.policy])

  statement {
    sid = "AWSCloudTrailAclCheck"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      "${local.arn_format}:s3:::${module.this.id}",
    ]
  }

  statement {
    sid = "AWSCloudTrailWrite"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${local.arn_format}:s3:::${module.this.id}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control",
      ]
    }
  }
}

data "aws_partition" "current" {}

locals {
  access_log_bucket_name = var.create_access_log_bucket == true ? "${module.this.id}-access-logs" : var.access_log_bucket_name
  arn_format             = "arn:${data.aws_partition.current.partition}"
}
