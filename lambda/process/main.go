package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	awsconfig "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/redis/go-redis/v9"
)

const cacheTTL = 60 * time.Second

var (
	logger      = slog.New(slog.NewJSONHandler(os.Stdout, nil))
	redisClient *redis.Client
	s3Client    *s3.Client
	s3Bucket    string
)

func init() {
	redisClient = redis.NewClient(&redis.Options{
		Addr: fmt.Sprintf("%s:%s", os.Getenv("REDIS_ADDR"), os.Getenv("REDIS_PORT")),
	})

	awsConfig, err := awsconfig.LoadDefaultConfig(context.Background())
	if err != nil {
		logger.Error("error cargando la configuracion de AWS", "error", err)
		os.Exit(1)
	}

	s3Client = s3.NewFromConfig(awsConfig)
	s3Bucket = os.Getenv("S3_BUCKET")
}

type processResponse struct {
	CacheKey string `json:"cache_key"`
	Result   string `json:"result"`
}

type errorResponse struct {
	Error string `json:"error"`
}

func requestInput(request events.APIGatewayProxyRequest) string {
	if request.Body != "" {
		return request.Body
	}
	return request.QueryStringParameters["input"]
}

func cacheKey(input string) string {
	sum := sha256.Sum256([]byte(input))
	return hex.EncodeToString(sum[:])
}

func reverse(input string) string {
	runes := []rune(input)
	for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
		runes[i], runes[j] = runes[j], runes[i]
	}
	return string(runes)
}

func jsonResponse(status int, headers map[string]string, payload any) (events.APIGatewayProxyResponse, error) {
	body, err := json.Marshal(payload)
	if err != nil {
		return events.APIGatewayProxyResponse{}, fmt.Errorf("serializando respuesta: %w", err)
	}

	merged := map[string]string{
		"Content-Type":                "application/json",
		"Access-Control-Allow-Origin": "*",
	}
	for key, value := range headers {
		merged[key] = value
	}

	return events.APIGatewayProxyResponse{
		StatusCode: status,
		Headers:    merged,
		Body:       string(body),
	}, nil
}

func cachedValue(ctx context.Context, key string) (string, bool, error) {
	cached, err := redisClient.Get(ctx, key).Result()
	if err == nil {
		return cached, true, nil
	}
	if errors.Is(err, redis.Nil) {
		return "", false, nil
	}
	return "", false, fmt.Errorf("consultando Redis: %w", err)
}

func cacheMiss(ctx context.Context, key string, input string) (events.APIGatewayProxyResponse, error) {
	payload := processResponse{
		CacheKey: key,
		Result:   reverse(input),
	}

	payloadJSON, err := json.Marshal(payload)
	if err != nil {
		return internalServerError(fmt.Sprintf("error serializando el resultado: %v", err))
	}

	objectKey := fmt.Sprintf("results/%s/%s.json", time.Now().UTC().Format("2006-01-02"), key)
	_, err = s3Client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s3Bucket),
		Key:         aws.String(objectKey),
		Body:        bytes.NewReader(payloadJSON),
		ContentType: aws.String("application/json"),
	})
	if err != nil {
		return internalServerError(fmt.Sprintf("error guardando el resultado en S3: %v", err))
	}

	if err := redisClient.SetEx(ctx, key, payloadJSON, cacheTTL).Err(); err != nil {
		return internalServerError(fmt.Sprintf("error escribiendo en Redis: %v", err))
	}

	response, err := jsonResponse(http.StatusOK, map[string]string{"X-Cache": "MISS"}, payload)
	if err != nil {
		return internalServerError(fmt.Sprintf("error generando la respuesta: %v", err))
	}

	return response, nil
}

func process(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	input := requestInput(request)
	key := cacheKey(input)

	cached, found, err := cachedValue(ctx, key)
	if err != nil {
		return internalServerError(fmt.Sprintf("error %v", err))
	}

	if found {
		response, err := jsonResponse(http.StatusOK, map[string]string{"X-Cache": "HIT"}, json.RawMessage(cached))
		if err != nil {
			return internalServerError(fmt.Sprintf("error generando la respuesta: %v", err))
		}
		return response, nil
	}

	return cacheMiss(ctx, key, input)
}

func internalServerError(message string) (events.APIGatewayProxyResponse, error) {
	logger.Error("error procesando la peticion", "error", message)

	response, err := jsonResponse(http.StatusInternalServerError, map[string]string{"X-Cache": "MISS"}, errorResponse{Error: message})
	if err != nil {
		logger.Error("error serializando la respuesta de error", "error", err)
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Headers: map[string]string{
				"Content-Type":                "application/json",
				"Access-Control-Allow-Origin": "*",
				"X-Cache":                     "MISS",
			},
			Body: `{"error":"error interno del servidor"}`,
		}, nil
	}

	return response, nil
}

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (response events.APIGatewayProxyResponse, err error) {
	defer func() {
		if recovered := recover(); recovered != nil {
			response, err = internalServerError(fmt.Sprintf("panic interno: %v", recovered))
		}
	}()

	return process(ctx, request)
}

func main() {
	lambda.Start(handler)
}
