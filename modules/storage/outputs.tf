output "bucket_name" {
  description = "Nombre del bucket S3 de resultados"
  value       = aws_s3_bucket.results.id
}

output "bucket_arn" {
  description = "ARN del bucket S3 de resultados"
  value       = aws_s3_bucket.results.arn
}
