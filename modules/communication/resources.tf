resource "aws_api_gateway_resource" "process" {
  rest_api_id = aws_api_gateway_rest_api.process_api.id
  parent_id   = aws_api_gateway_rest_api.process_api.root_resource_id
  path_part   = "process"
}

resource "aws_api_gateway_method" "process_post" {
  rest_api_id   = aws_api_gateway_rest_api.process_api.id
  resource_id   = aws_api_gateway_resource.process.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "process_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.process_api.id
  resource_id             = aws_api_gateway_resource.process.id
  http_method             = aws_api_gateway_method.process_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
  timeout_milliseconds    = 29000
}
