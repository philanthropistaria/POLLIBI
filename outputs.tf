output "frontend_url" {
  description = "URL of the POLLIBI frontend"
  value       = aws_s3_bucket.pollibi_frontend.website_endpoint
}

output "api_url" {
  description = "URL of the POLLIBI API"
  value       = aws_apigatewayv2_api.pollibi_api.api_endpoint
}

output "audio_bucket_name" {
  description = "Name of the audio S3 bucket"
  value       = aws_s3_bucket.pollibi_audio.bucket
}

output "frontend_bucket_name" {
  description = "Name of the frontend S3 bucket"
  value       = aws_s3_bucket.pollibi_frontend.bucket
}
