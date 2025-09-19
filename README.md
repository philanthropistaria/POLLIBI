#POLLIBI A cloud-native text to speech application powered by Amazon Polly's neural voices, built on AWS serverless infrastructure with Terraform.

✨ Features 🎙️ Multiple Neural Voices - Joanna, Matthew, Ivy, Justin, Kendra, Kimberly etc.

📁 Multiple Formats - MP3, OGG, PCM output support

⚡ Real-time Processing - Instant audio generation

📱 Responsive Design

🌐 RESTful API - Easy integration with other applications

🔒 Secure - IAM roles, S3 policies, and secure presigned URLs

🚀 Serverless - Auto-scaling, pay-per-use infrastructure

#🏗️ Architecture 
#┌─────────────────────────────────────────────────────────────────────────────┐
│                            POLLIBI ARCHITECTURE                             │
│                     Text-to-Speech AWS Serverless Application               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────┐    HTTPS     ┌──────────────────┐    Invoke    ┌─────┴─────┐
│   │   Frontend      │──────────────│   API Gateway    │──────────────│  AWS      │
│   │   (S3 Static    │◄─────────────│   (HTTP API)     │◄─────────────│  Lambda   │
│   │   Website)      │  JSON Response│                  │  Polly Response│ Function │
│   └─────────────────┘              └──────────────────┘              └─────┬─────┘
│        │                                           │                       │
│        │ HTML/CSS/JS                              │                       │ AWS SDK
│        │                                           │                       │
│        ▼                                           │                       ▼
│   ┌─────────────┐                                  │              ┌─────────────────┐
│   │   User      │                                  │              │   Amazon Polly  │
│   │   Browser   │                                  │              │  (TTS Engine)   │
│   └─────────────┘                                  │              └────────┬────────┘
│        │                                           │                       │
│        │ Audio Playback                            │                       │ Audio Stream
│        │                                           │                       │
│        ▼                                           │                       ▼
│   ┌─────────────────────────────────┐              │              ┌─────────────────┐
│   │   CloudFront CDN (Optional)     │              │              │   S3 Bucket     │
│   │   for Global Audio Delivery     │◄─────────────┼──────────────│   (Audio Store) │
│   └─────────────────────────────────┘   Presigned URL             └─────────────────┘
│                                                                             │
│                                                                             │ IAM Role
│                                                                             │
│                                                                   ┌─────────┴─────────┐
│                                                                   │   IAM Roles &     │
│                                                                   │   Permissions     │
│                                                                   └───────────────────┘
│                                                                             │
│                                                                   ┌─────────┴─────────┐
│                                                                   │   CloudWatch      │
│                                                                   │   (Logging &      │
│                                                                   │   Monitoring)     │
│                                                                   └───────────────────┘
│                                                                             │
│                                                                   ┌─────────┴─────────┐
│                                                                   │   Terraform       │
│                                                                   │   (Infrastructure │
│                                                                   │   as Code)        │
│                                                                   └───────────────────┘
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

LEGEND:
┌───────────────┐
│   Component   │  → HTTPS/API Calls
└───────────────┘  → Data Flow
                  → IAM Permissions



Quick Start Prerequisites AWS Account with appropriate permissions

Terraform v1.0+

AWS CLI configured

Git

Deployment Clone the repository

bash git clone https://github.com/your-username/pollibi.git cd pollibi Initialize Terraform

bash terraform init Review deployment plan

bash terraform plan Deploy infrastructure

bash terraform apply -auto-approve Access your application

Frontend URL: (http://pollibi-frontend-afe1dccb.s3-website-us-east-1.amazonaws.com/#)

API Endpoint: https://[api-id].execute-api.us-east-1.amazonaws.com/prod/synthesize

Usage Web Interface Visit the frontend URL

Enter text in the text area

Select your preferred voice

Choose output format

Click "Generate Speech"

Play and also download the generated audio if neccessary

🆘 Contact 📧 Email: aatandoh56@gmail.com

🙏 Acknowledgments Amazon Web Services for the powerful infrastructure

Amazon Polly team for amazing TTS technology

HashiCorp for Terraform IaC tools
