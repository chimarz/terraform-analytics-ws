import boto3
from botocore.exceptions import ClientError
import uuid
import json

# Initialize DynamoDB resource
table_name = 'Assets'
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
table = dynamodb.Table(table_name)
# Initialize the table
table = dynamodb.Table(table_name)
event_bus = "default"

def create_random_id():
    uuid.uuid4()
    # Convert a UUID to a string of hex digits in standard form
    return str(uuid.uuid4())

def send_event(content):
    content_json = json.dumps(content)
    print("content_json")
    print(content_json)
    events = boto3.client("events", region_name='us-east-1')

    entries = [
        {
            "Source": "asset-service",
            "DetailType": "new-asset-event",
            "Detail": content_json,
            "EventBusName": event_bus,
        }
    ]
    event_response = events.put_events(Entries=entries)
    print("event_Response")
    print(event_response)
    return event_response


def add_sample_items():

    for item in range(100):
        try:
            item = {
                        'tenantId': create_random_id(),
                        'assetId': create_random_id()
                    }
            response = table.put_item(Item=item)
            print(f"Added item: {item}")
            # send an event
            send_event(item)
            # Send an event to the analytics event bus

        except ClientError as e:
            print(f"Error adding item {item}: {e.response['Error']['Message']}")

if __name__ == '__main__':
    add_sample_items()