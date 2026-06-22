import json
import urllib.parse
import boto3

print("Loading function")

s3 = boto3.client("s3")
ecs = boto3.client("ecs")


def lambda_handler(event, context):
    # print("Received event: " + json.dumps(event, indent=2))

    # Get the object from the event and show its content type
    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    key = urllib.parse.unquote_plus(
        event["Records"][0]["s3"]["object"]["key"], encoding="utf-8"
    )

    print(f"File uploaded: s3://{bucket}/{key}")

    try:
        response = ecs.run_task(
            cluster="hello-ecs",
            launchType="FARGATE",
            taskDefinition="hello-ecs-task-def",
            overrides={
                "containerOverrides": [
                    {
                        "name": "hello-ecs-container",
                        "environment": [
                            {"name": "TARGET_S3_BUCKET", "value": bucket},
                            {"name": "TARGET_S3_KEY", "value": key},
                        ],
                    }
                ]
            },
        )

        task_arn = response["tasks"][0]["taskArn"]
        print(f"🎉 Triggered ECS Task successfully on Floci! Task ARN: {task_arn}")

        return {"statusCode": 200, "body": json.dumps(f"ECS Task started: {task_arn}")}

    except Exception as e:
        print(f"Error triggering ECS task for file {key} from bucket {bucket}.")
        print("Error details:", e)
        raise e
