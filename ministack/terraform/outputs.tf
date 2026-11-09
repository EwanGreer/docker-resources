output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.example.bucket
}

output "queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.example.url
}

output "db_endpoint" {
  description = "Postgres endpoint (host:port)"
  value       = aws_db_instance.example.endpoint
}

output "db_secret_name" {
  description = "Secrets Manager secret holding the database credentials"
  value       = aws_secretsmanager_secret.db.name
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.example.id
}
