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

const (
	cacheTTL       = 60 * time.Second
	requestTimeout = 5 * time.Second
)

var (
	logger = slog.New(slog.NewJSONHandler(os.Stdout, nil))
	deps   dependencies
)

func init() {
	redisClient := redis.NewClient(&redis.Options{
		Addr:         fmt.Sprintf("%s:%s", os.Getenv("REDIS_ADDR"), os.Getenv("REDIS_PORT")),
		DialTimeout:  2 * time.Second,
		ReadTimeout:  2 * time.Second,
		WriteTimeout: 2 * time.Second,
		MaxRetries:   2,
	})

	awsConfig, err := awsconfig.LoadDefaultConfig(context.Background())
	if err != nil {
		logger.Error("error cargando la configuracion de AWS", "error", err)
		os.Exit(1)
	}

	deps = dependencies{
		cache: redisBackend{client: redisClient},
		store: s3Backend{client: s3.NewFromConfig(awsConfig), bucket: os.Getenv("S3_BUCKET")},
	}
}

type dependencies struct {
	cache cacheBackend
	store resultsStore
}

type cacheBackend interface {
	get(ctx context.Context, key string) (string, error)
	setEx(ctx context.Context, key string, value string, ttl time.Duration) error
}

type redisBackend struct {
	client *redis.Client
}

func (b redisBackend) get(ctx context.Context, key string) (string, error) {
	return b.client.Get(ctx, key).Result()
}

func (b redisBackend) setEx(ctx context.Context, key string, value string, ttl time.Duration) error {
	return b.client.SetEx(ctx, key, value, ttl).Err()
}

type resultsStore interface {
	put(ctx context.Context, objectKey string, payload []byte) error
}

type s3Backend struct {
	client *s3.Client
	bucket string
}

func (b s3Backend) put(ctx context.Context, objectKey string, payload []byte) error {
	_, err := b.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(b.bucket),
		Key:         aws.String(objectKey),
		Body:        bytes.NewReader(payload),
		ContentType: aws.String("application/json"),
	})
	return err
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

func cachedValue(ctx context.Context, backend cacheBackend, key string) (string, bool, error) {
	cached, err := backend.get(ctx, key)
	if err == nil {
		return cached, true, nil
	}
	if errors.Is(err, redis.Nil) {
		return "", false, nil
	}
	return "", false, fmt.Errorf("consultando Redis: %w", err)
}

func cacheMiss(ctx context.Context, d dependencies, key string, input string) (events.APIGatewayProxyResponse, error) {
	payload := processResponse{
		CacheKey: key,
		Result:   reverse(input),
	}

	payloadJSON, err := json.Marshal(payload)
	if err != nil {
		return internalServerError(fmt.Sprintf("error serializando el resultado: %v", err))
	}

	objectKey := fmt.Sprintf("results/%s/%s.json", time.Now().UTC().Format("2006-01-02"), key)
	if err := d.store.put(ctx, objectKey, payloadJSON); err != nil {
		return internalServerError(fmt.Sprintf("error guardando el resultado en S3: %v", err))
	}

	if err := d.cache.setEx(ctx, key, string(payloadJSON), cacheTTL); err != nil {
		return internalServerError(fmt.Sprintf("error escribiendo en Redis: %v", err))
	}

	response, err := jsonResponse(http.StatusOK, map[string]string{"X-Cache": "MISS"}, payload)
	if err != nil {
		return internalServerError(fmt.Sprintf("error generando la respuesta: %v", err))
	}

	return response, nil
}

func process(ctx context.Context, d dependencies, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	input := requestInput(request)
	key := cacheKey(input)

	cached, found, err := cachedValue(ctx, d.cache, key)
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

	return cacheMiss(ctx, d, key, input)
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

	ctx, cancel := context.WithTimeout(ctx, requestTimeout)
	defer cancel()

	return process(ctx, deps, request)
}

func main() {
	lambda.Start(handler)
}
