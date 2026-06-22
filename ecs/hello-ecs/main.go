package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Println("Hello ECS! 👋")

	bucket := os.Getenv("TARGET_S3_BUCKET")
	key := os.Getenv("TARGET_S3_KEY")

	fmt.Printf("Target: s3://%s/%s\n", bucket, key)

	fmt.Println("Finished!")
}
