resource "aws_api_gateway_rest_api" "process_api" {
  name        = "${var.name_prefix}-api"
  description = "REST API que expone POST /process"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rest-api"
  })
}
