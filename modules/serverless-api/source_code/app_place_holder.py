import json
import os

def lambda_handler(event, context):
    table_name = os.environ.get('TABLE_NAME')
    env = os.environ.get('ENVIRONMENT')
    
    return {
        'statusCode': 200,
        'body': json.dumps(f"Visitor counter active in {env}. Connected to: {table_name}")
    }
