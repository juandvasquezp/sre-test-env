resource "aws_cloudwatch_log_group" "api_access_logs" {
  name              = "API-Gateway-Access-Logs_${aws_api_gateway_rest_api.process_api.id}/${var.stage_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-access-logs"
  })
}

data "aws_iam_policy_document" "api_gateway_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name               = "${var.name_prefix}-apigw-cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-apigw-cloudwatch-role"
  })
}

data "aws_iam_policy_document" "api_gateway_cloudwatch" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  name   = "cloudwatch-logs"
  role   = aws_iam_role.api_gateway_cloudwatch.name
  policy = data.aws_iam_policy_document.api_gateway_cloudwatch.json
}

resource "aws_api_gateway_account" "cloudwatch_logging" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn

  depends_on = [aws_iam_role_policy.api_gateway_cloudwatch]
}
