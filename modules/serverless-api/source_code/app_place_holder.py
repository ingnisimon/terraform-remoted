import json
import os
import boto3
from decimal import Decimal

# Initialize the DynamoDB resource outside the handler for connection reuse (Cold Start optimization)
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME')
environment = os.environ.get('ENVIRONMENT')
table = dynamodb.Table(table_name)

# Helper class to convert DynamoDB Decimals to standard Python integers for JSON serialization
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    try:
        # Atomic update: Increments 'visitor_count' by 1. 
        # If the item or attribute doesn't exist, DynamoDB creates it automatically.
        response = table.update_item(
            Key={
                'id': 'visits' # Ensure your Terraform dynamo schema uses 'id' as the partition key (String)
            },
            UpdateExpression='ADD visitor_count :inc',
            ExpressionAttributeValues={
                ':inc': 1
            },
            ReturnValues='UPDATED_NEW'
        )
        
        # Extract the newly incremented count
        current_count = response['Attributes']['visitor_count']
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*' # Required for web browsers to accept the response
            },
            'body': json.dumps({
                'message': f'Visitor counter active in {environment}. Connected to: {table_name}',
                'count': current_count
            }, cls=DecimalEncoder)
        }
        
    except Exception as e:
        print(f"Error updating DynamoDB: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Could not update visitor count'})
        }
