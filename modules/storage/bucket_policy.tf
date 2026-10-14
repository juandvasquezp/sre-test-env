data "aws_iam_policy_document" "results_bucket_policy" {
  statement {
    sid       = "AllowLambdaRoleViaVpcEndpoint"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.results.arn}/results/*"]

    principals {
      type        = "AWS"
      identifiers = [var.lambda_role_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = [var.s3_vpc_endpoint_id]
    }
  }
}

resource "aws_s3_bucket_policy" "results" {
  bucket = aws_s3_bucket.results.id
  policy = data.aws_iam_policy_document.results_bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.results]
}
