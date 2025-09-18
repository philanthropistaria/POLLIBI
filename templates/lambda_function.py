import json
import boto3
import uuid
from datetime import datetime
import os
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
polly_client = boto3.client('polly')

def lambda_handler(event, context):
    logger.info(f"Full event received: {json.dumps(event)}")
    
    try:
        # Get bucket name from environment variable
        bucket_name = os.environ.get('BUCKET_NAME')
        logger.info(f"Bucket name from environment: {bucket_name}")
        
        if not bucket_name:
            return error_response(500, 'Bucket name not configured in environment variables')
        
        # Parse the request body
        if 'body' not in event:
            return error_response(400, 'No body in event')
        
        try:
            body = json.loads(event['body'])
            logger.info(f"Parsed body: {json.dumps(body)}")
        except json.JSONDecodeError as e:
            return error_response(400, f'Invalid JSON in body: {str(e)}')
        
        text = body.get('text', '')
        voice_id = body.get('voiceId', 'Joanna')
        output_format = body.get('outputFormat', 'mp3')
        engine = body.get('engine', 'standard')
        
        if not text:
            return error_response(400, 'Text is required')
        
        # Synthesize speech using Polly
        try:
            logger.info(f"Calling Polly with text: {text[:100]}...")
            response = polly_client.synthesize_speech(
                Text=text,
                OutputFormat=output_format,
                VoiceId=voice_id,
                Engine=engine
            )
            logger.info("Successfully synthesized speech with Polly")
        except Exception as e:
            logger.error(f"Polly error: {str(e)}")
            return error_response(500, f'Polly synthesis failed: {str(e)}')
        
        # Generate unique filename
        filename = f"{voice_id}_{uuid.uuid4()}.{output_format}"
        logger.info(f"Generated filename: {filename}")
        
        # Upload to S3
        try:
            audio_data = response['AudioStream'].read()
            s3_client.put_object(
                Bucket=bucket_name,
                Key=filename,
                Body=audio_data,
                ContentType=f'audio/{output_format}',
                ACL='public-read'
            )
            logger.info(f"Successfully uploaded to S3: {filename}")
        except Exception as e:
            logger.error(f"S3 upload error: {str(e)}")
            return error_response(500, f'S3 upload failed: {str(e)}')
        
        # Generate presigned URL
        try:
            audio_url = s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': bucket_name,
                    'Key': filename
                },
                ExpiresIn=3600
            )
            logger.info(f"Generated presigned URL: {audio_url}")
        except Exception as e:
            logger.error(f"Presigned URL error: {str(e)}")
            return error_response(500, f'URL generation failed: {str(e)}')
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({
                'audioUrl': audio_url,
                'filename': filename,
                'voiceId': voice_id,
                'timestamp': datetime.utcnow().isoformat()
            })
        }
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return error_response(500, f'Internal server error: {str(e)}')

def error_response(status_code, message):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': json.dumps({'error': message})
    }

