export AWS_DEFAULT_REGION=ap-southeast-1
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_PAGER=

ZIP_FILE=lambda_function.zip
FUNCTION_NAME=s3-trigger-create-ecs
BUCKET_NAME=my-bucket
REGION=ap-southeast-1
CLUSTER_NAME=hello-ecs
TASK_DEF_NAME=hello-ecs-task-def

setup: \
	create-bucket \
	create-lambda-role \
	zip-function \
	deploy-function \
	lambda-trigger-config \
	s3-send-event-to-lambda \
	create-ecs-cluster \
	register-task-def \
	build-ecs
	
create-bucket:
	aws s3 mb s3://${BUCKET_NAME}

create-lambda-role:
	aws iam create-role \
	--role-name lambda-role \
	--assume-role-policy-document file://lambda/trust-policy.json

zip-function:
	cd ./lambda && zip -r ../${ZIP_FILE} . && cd ..

deploy-function:
	ROLE_ARN=$$(aws iam get-role --role-name lambda-role --query "Role.Arn" --output text 2>/dev/null) && \
	aws lambda create-function \
	--function-name ${FUNCTION_NAME} \
	--handler main.lambda_handler \
	--runtime python3.13 \
	--role $$ROLE_ARN \
	--zip-file fileb://${ZIP_FILE} \
	--timeout 30

update-function:
	aws lambda update-function-code \
	--function-name ${FUNCTION_NAME} \
	--zip-file fileb://${ZIP_FILE}

lambda-trigger-config:
	ACCOUNT_ID=$$(aws sts get-caller-identity --query "Account" --output text) && \
	aws lambda add-permission \
	--function-name ${FUNCTION_NAME} \
	--statement-id s3-invoke \
	--action lambda:InvokeFunction \
	--principal s3.amazonaws.com \
	--source-arn "arn:aws:s3:::${BUCKET_NAME}" \
	--source-account $$ACCOUNT_ID

s3-send-event-to-lambda:
	aws s3api put-bucket-notification-configuration \
	--bucket ${BUCKET_NAME} \
	--notification-configuration file://s3/config-trigger.json


upload-file:
	aws s3 cp ${FILE} s3://${BUCKET_NAME}

create-ecs-cluster:
	aws ecs create-cluster \
	--cluster-name ${CLUSTER_NAME} 

register-task-def:
	aws ecs register-task-definition \
	--cli-input-json file://ecs/ecs-task-def.json

build-ecs:
	docker build -t hello-ecs ./ecs/hello-ecs