resource "aws_lambda_permission" "process_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_stage.process_api.execution_arn}/POST${aws_api_gateway_resource.process.path}"
}
