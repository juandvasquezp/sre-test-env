#############################################
# VPC Endpoint Gateway para S3
# El trafico hacia S3 no sale a internet
#############################################

data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.main_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-endpoint"
  })
}
