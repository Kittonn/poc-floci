export AWS_ENDPOINT_URL=http://localhost:4566

ZIP_FILE=lambda_function.zip
FUNCTION_NAME=s3-trigger-create-ecs
BUCKET_NAME=my-bucket
REGION=ap-southeast-1

ACCOUNT_ID = $(shell aws sts get-caller-identity --query "Account" --output text --endpoint-url $(AWS_ENDPOINT_URL))
ROLE_ARN = $(shell aws iam get-role --role-name lambda-role --query "Role.Arn" --output text --endpoint-url $(AWS_ENDPOINT_URL) 2>/dev/null)

create-bucket:
	aws s3 mb s3://${BUCKET_NAME} --endpoint-url ${AWS_ENDPOINT_URL} --region ${REGION}

create-lambda-role:
	aws iam create-role \
	--role-name lambda-role \
	--assume-role-policy-document file://lambda/trust-policy.json \
	--endpoint-url ${AWS_ENDPOINT_URL} \
	--region ${REGION}

zip-function:
	cd ./lambda && zip -r ../${ZIP_FILE} . && cd ..

deploy-function:
	aws lambda create-function \
	--function-name ${FUNCTION_NAME} \
	--handler main.lambda_handler \
	--runtime python3.13 \
	--role ${ROLE_ARN} \
	--zip-file fileb://${ZIP_FILE} \
  --timeout 30 \
	--endpoint-url ${AWS_ENDPOINT_URL} \
	--region ${REGION}

update-function:
	aws lambda update-function-code \
	--function-name ${FUNCTION_NAME} \
	--zip-file fileb://${ZIP_FILE} \
	--endpoint-url ${AWS_ENDPOINT_URL} \
	--region ${REGION}

lambda-trigger-config:
	aws lambda add-permission \
    --function-name ${FUNCTION_NAME} \
    --statement-id s3-invoke \
    --action lambda:InvokeFunction \
		--principal s3.amazonaws.com \
		--source-arn "arn:aws:s3:::${BUCKET_NAME}" \
		--source-account ${ACCOUNT_ID} \
		--endpoint-url ${AWS_ENDPOINT_URL} \
		--region ${REGION}

s3-send-event-to-lambda:
	aws s3api put-bucket-notification-configuration \
	--bucket ${BUCKET_NAME} \
	--notification-configuration file://s3/config-trigger.json \
	--endpoint-url ${AWS_ENDPOINT_URL} \
	--region ${REGION}


upload-file:
	aws s3 cp ./data/sample.txt s3://${BUCKET_NAME} --endpoint-url ${AWS_ENDPOINT_URL} --region ${REGION}
