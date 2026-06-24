# POC Floci

## Get Started

1. Start Container
```bash
docker-compose up -d
```

2. Setup 
```bash
make setup
```

3. Upload a file to trigger the Lambda function
> You must create a file to upload before running the command below.
```bash
make upload-file FILE=<path-to-your-file>
```

When lambda function code is changed, you can run the following command to update the function code.
```bash
make zip-function
make update-function
```