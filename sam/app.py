import json

def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "headers": { "Content-Type": "application/json" },
        "body": json.dumps({ "message": "Serverless SAM application is live via manual AWS CodeBuild!" }),
    }
