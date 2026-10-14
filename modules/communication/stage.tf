resource "aws_api_gateway_deployment" "process_api" {
  rest_api_id = aws_api_gateway_rest_api.process_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.process.id,
      aws_api_gateway_method.process_post.id,
      aws_api_gateway_integration.process_lambda.id,
      aws_api_gateway_method.process_options.id,
      aws_api_gateway_integration.process_options.id,
      aws_api_gateway_integration_response.process_options.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.process_lambda,
    aws_api_gateway_integration_response.process_options,
  ]
}

resource "aws_api_gateway_stage" "process_api" {
  rest_api_id   = aws_api_gateway_rest_api.process_api.id
  deployment_id = aws_api_gateway_deployment.process_api.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access_logs.arn

    format = jsonencode({
      requestId       = "$context.requestId"
      requestTime     = "$context.requestTime"
      sourceIp        = "$context.identity.sourceIp"
      httpMethod      = "$context.httpMethod"
      path            = "$context.path"
      status          = "$context.status"
      responseLength  = "$context.responseLength"
      responseLatency = "$context.responseLatency"
      errorMessage    = "$context.error.message"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.stage_name}-stage"
  })
}

resource "aws_api_gateway_method_settings" "stage_default" {
  rest_api_id = aws_api_gateway_rest_api.process_api.id
  stage_name  = aws_api_gateway_stage.process_api.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit
    metrics_enabled        = true
  }
}
