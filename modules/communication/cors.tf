resource "aws_api_gateway_method" "process_options" {
  rest_api_id   = aws_api_gateway_rest_api.process_api.id
  resource_id   = aws_api_gateway_resource.process.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "process_options" {
  rest_api_id = aws_api_gateway_rest_api.process_api.id
  resource_id = aws_api_gateway_resource.process.id
  http_method = aws_api_gateway_method.process_options.http_method
  status_code = "204"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "process_options" {
  rest_api_id = aws_api_gateway_rest_api.process_api.id
  resource_id = aws_api_gateway_resource.process.id
  http_method = aws_api_gateway_method.process_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_integration_response" "process_options" {
  rest_api_id = aws_api_gateway_rest_api.process_api.id
  resource_id = aws_api_gateway_resource.process.id
  http_method = aws_api_gateway_method.process_options.http_method
  status_code = aws_api_gateway_method_response.process_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Requested-With'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.process_options]
}
