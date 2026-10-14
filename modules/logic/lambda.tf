locals {
  function_name = "${var.name_prefix}-${var.function_name}"
  source_dir    = "${path.module}/../../lambda/${var.function_name}"
  build_dir     = "${local.source_dir}/build"
  binary_path   = "${local.build_dir}/bootstrap"
  zip_path      = "${local.build_dir}/lambda.zip"
}

resource "null_resource" "build_lambda" {
  triggers = {
    main_go = filesha256("${local.source_dir}/main.go")
    go_mod  = filesha256("${local.source_dir}/go.mod")
    go_sum  = filesha256("${local.source_dir}/go.sum")
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      mkdir -p ${local.build_dir}
      cd ${local.source_dir}
      GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o ${local.binary_path} .
    EOT
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = local.binary_path
  output_path = local.zip_path

  depends_on = [null_resource.build_lambda]
}

resource "aws_lambda_function" "process" {
  function_name    = local.function_name
  role             = aws_iam_role.lambda_execution.arn
  runtime          = "provided.al2023"
  handler          = "bootstrap"
  architectures    = ["arm64"]
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      REDIS_ADDR = var.redis_address
      REDIS_PORT = tostring(var.redis_port)
      S3_BUCKET  = var.s3_bucket_name
    }
  }

  logging_config {
    log_format            = "JSON"
    log_group             = aws_cloudwatch_log_group.lambda.name
    application_log_level = "INFO"
  }

  tags = merge(var.tags, {
    Name = local.function_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_iam_role_policy.lambda_s3_access,
    aws_cloudwatch_log_group.lambda,
  ]
}
