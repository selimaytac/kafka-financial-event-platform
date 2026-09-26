output "state_bucket" {
  description = "Bucket for remote state."
  value       = aws_s3_bucket.state.bucket
}
