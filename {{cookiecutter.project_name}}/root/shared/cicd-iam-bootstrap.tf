/*
  CI/CD IAM Permissions bootstrap:
  Terraform backend resources [bucket, key] deployed from a
  seed CloudFormation template [stack: tf-remote-state]
 */

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"] // Note: this is correct (ffff...)
}

locals {
  tfstate_param_prefix = "/infra/tfstate"
  gh_actions_role_name = "github-actions-${local.region}"

  tag_infra_management_key   = "infrastructure-management"
  tag_infra_management_value = "true"

  ## TODO: add org name
  # github_org = ""

  ## TODO: enable to configure GitHub repository access
  ## (Optionally restrict allowed repos)
  # gh_actions_allowed_subjects = [
  #   "repo:${local.github_org}/*:*",
  # ]
}

/* [tf-remote-state] The SSM params below are populated by the CloudFormation stack "tf-remote-state" */
data "aws_ssm_parameter" "tfstate_bucket" {
  name = "/infra/tfstate/bucket"
}

data "aws_ssm_parameter" "tfstate_key" {
  name = "/infra/tfstate/key"
}
/* end [tf-remote-state] */

data "aws_s3_bucket" "tfstate" {
  bucket = data.aws_ssm_parameter.tfstate_bucket.value
}

data "aws_kms_alias" "tfstate" {
  name = "alias/${data.aws_ssm_parameter.tfstate_key.value}"
}


data "aws_iam_policy_document" "tfstate_access" {

  statement {
    sid     = "Bucket"
    actions = ["s3:ListBucket"]
    resources = [
      data.aws_s3_bucket.tfstate.arn
    ]
  }

  statement {
    sid     = "Objects"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "${data.aws_s3_bucket.tfstate.arn}/*"
    ]
  }

  statement {
    sid     = "Key"
    actions = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"]
    resources = [
      data.aws_kms_alias.tfstate.target_key_arn
    ]
  }

}

data "aws_iam_policy_document" "infra_roles_access" {
  statement {
    sid = "Roles"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
    resources = ["arn:${local.partition}:iam::*:role/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/${local.tag_infra_management_key}"
      values   = [local.tag_infra_management_value]
    }
  }
}

module "iam_policy_document_ecr_private_push" {
  source = "../../modules/iam-policy-documents/ecr-private-push"
}

module "iam_policy_document_codebuild" {
  source = "../../modules/iam-policy-documents/codebuild"
}

module "iam_policy_document_tfstate_params_access" {
  source = "../../modules/iam-policy-documents/ssm-parameters-access"
  parameter_names = [
    local.tfstate_param_prefix,
  ]
}

data "aws_iam_policy_document" "github_actions_permissions" {
  source_policy_documents = [
    module.iam_policy_document_tfstate_params_access.json,
    data.aws_iam_policy_document.tfstate_access.json,
    data.aws_iam_policy_document.infra_roles_access.json,
    module.iam_policy_document_ecr_private_push.json,
    module.iam_policy_document_codebuild.json,
  ]
}

data "aws_iam_policy_document" "github_actions_trust" {
  ## Note: enable this after first apply to allow the role to assume itself
  #
  # statement {
  #   actions = ["sts:AssumeRole"]
  #   principals {
  #     type = "AWS"
  #     identifiers = [
  #       "arn:aws:iam::${local.account_id}:root",
  #       "arn:aws:iam::${local.account_id}:role/${local.gh_actions_role_name}"
  #     ]
  #   }
  # }

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.${local.dns_suffix}"]
    }
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.${local.dns_suffix}"]
    }

    ## TODO: enable after setting the correct locals
    # condition {
    #   test     = "StringLike"
    #   variable = "token.actions.githubusercontent.com:sub"
    #   values   = local.gh_actions_allowed_subjects
    # }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = local.gh_actions_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
  description        = "Base role for GitHub Actions, used to assume roles in the target LZ accounts"
  tags               = module.config.tag_infra_management
}

resource "aws_iam_role_policy" "github_actions_permissions" {
  name   = "github-actions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
