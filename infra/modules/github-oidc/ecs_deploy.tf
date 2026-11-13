data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  arn_prefix  = "arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}"
  cluster_arn = "${local.arn_prefix}:cluster/${var.ecs_cluster_name}"
}

data "aws_iam_policy_document" "ecs_deploy" {
  statement {
    sid       = "TaskDefinitions"
    actions   = ["ecs:RegisterTaskDefinition", "ecs:DescribeTaskDefinition"]
    resources = ["*"] # these actions do not support resource-level restrictions
  }

  statement {
    sid       = "RunMigration"
    actions   = ["ecs:RunTask"]
    resources = [for f in var.ecs_task_families : "${local.arn_prefix}:task-definition/${f}:*"]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [local.cluster_arn]
    }
  }

  statement {
    sid       = "ReadTasks"
    actions   = ["ecs:DescribeTasks"]
    resources = ["${local.arn_prefix}:task/${var.ecs_cluster_name}/*"]
  }

  statement {
    sid       = "UpdateService"
    actions   = ["ecs:UpdateService", "ecs:DescribeServices"]
    resources = ["${local.arn_prefix}:service/${var.ecs_cluster_name}/${var.ecs_service_name}"]
  }

  statement {
    sid       = "PassTaskRoles"
    actions   = ["iam:PassRole"]
    resources = var.pass_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid       = "ReadMigrationLogs"
    actions   = ["logs:GetLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}:log-stream:*"]
  }
}

resource "aws_iam_role_policy" "ecs_deploy" {
  name   = "ecs-deploy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.ecs_deploy.json
}