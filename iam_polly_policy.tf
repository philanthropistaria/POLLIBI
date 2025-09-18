resource "aws_iam_role_policy" "pollibi_polly_policy" {
  name = "pollibi-polly-policy"
  role = aws_iam_role.pollibi_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPollySynthesis"
        Effect = "Allow"
        Action = [
          "polly:SynthesizeSpeech"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowS3ForTTS"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.pollibi_audio.arn,
          "${aws_s3_bucket.pollibi_audio.arn}/*"
        ]
      }
    ]
  })
}
