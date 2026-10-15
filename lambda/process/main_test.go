package main

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"testing"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/redis/go-redis/v9"
)

type fakeCache struct {
	stored map[string]string
	ttls   map[string]time.Duration
	getErr error
	setErr error
}

func newFakeCache() *fakeCache {
	return &fakeCache{
		stored: map[string]string{},
		ttls:   map[string]time.Duration{},
	}
}

func (f *fakeCache) get(_ context.Context, key string) (string, error) {
	if f.getErr != nil {
		return "", f.getErr
	}
	value, ok := f.stored[key]
	if !ok {
		return "", redis.Nil
	}
	return value, nil
}

func (f *fakeCache) setEx(_ context.Context, key string, value string, ttl time.Duration) error {
	if f.setErr != nil {
		return f.setErr
	}
	f.stored[key] = value
	f.ttls[key] = ttl
	return nil
}

type fakeStore struct {
	objects map[string][]byte
	putErr  error
}

func newFakeStore() *fakeStore {
	return &fakeStore{objects: map[string][]byte{}}
}

func (f *fakeStore) put(_ context.Context, objectKey string, payload []byte) error {
	if f.putErr != nil {
		return f.putErr
	}
	f.objects[objectKey] = payload
	return nil
}

type panickingCache struct{}

func (panickingCache) get(context.Context, string) (string, error) {
	panic("boom")
}

func (panickingCache) setEx(context.Context, string, string, time.Duration) error {
	return nil
}

func TestCacheKey(t *testing.T) {
	want := "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
	if got := cacheKey("abc"); got != want {
		t.Errorf("cacheKey(\"abc\") = %q, want %q", got, want)
	}
	if cacheKey("x") == cacheKey("y") {
		t.Error("entradas distintas deben producir keys distintas")
	}
}

func TestReverse(t *testing.T) {
	cases := []struct{ input, want string }{
		{"hola", "aloh"},
		{"abc", "cba"},
		{"", ""},
		{"a", "a"},
		{"café", "éfac"},
		{"años", "soña"},
	}
	for _, c := range cases {
		if got := reverse(c.input); got != c.want {
			t.Errorf("reverse(%q) = %q, want %q", c.input, got, c.want)
		}
	}
}

func TestRequestInput(t *testing.T) {
	if got := requestInput(events.APIGatewayProxyRequest{Body: "body"}); got != "body" {
		t.Errorf("con body debe retornar el body, got %q", got)
	}

	request := events.APIGatewayProxyRequest{QueryStringParameters: map[string]string{"input": "param"}}
	if got := requestInput(request); got != "param" {
		t.Errorf("sin body debe usar el query param, got %q", got)
	}

	if got := requestInput(events.APIGatewayProxyRequest{}); got != "" {
		t.Errorf("sin body ni param debe ser vacio, got %q", got)
	}
}

func TestJSONResponse(t *testing.T) {
	response, err := jsonResponse(http.StatusOK, map[string]string{"X-Cache": "HIT"}, map[string]string{"ok": "true"})
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if response.StatusCode != http.StatusOK {
		t.Errorf("status = %d, want 200", response.StatusCode)
	}
	if response.Headers["Content-Type"] != "application/json" {
		t.Errorf("Content-Type = %q, want application/json", response.Headers["Content-Type"])
	}
	if response.Headers["Access-Control-Allow-Origin"] != "*" {
		t.Errorf("Access-Control-Allow-Origin = %q, want *", response.Headers["Access-Control-Allow-Origin"])
	}
	if response.Headers["X-Cache"] != "HIT" {
		t.Errorf("X-Cache = %q, want HIT", response.Headers["X-Cache"])
	}

	var body map[string]string
	if err := json.Unmarshal([]byte(response.Body), &body); err != nil {
		t.Fatalf("body no es JSON valido: %v", err)
	}
	if body["ok"] != "true" {
		t.Errorf("body = %q, want {\"ok\":\"true\"}", response.Body)
	}
}

func TestProcessCacheMiss(t *testing.T) {
	cache := newFakeCache()
	store := newFakeStore()
	request := events.APIGatewayProxyRequest{Body: "hola"}

	response, err := process(context.Background(), dependencies{cache: cache, store: store}, request)
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if response.StatusCode != http.StatusOK {
		t.Errorf("status = %d, want 200", response.StatusCode)
	}
	if response.Headers["X-Cache"] != "MISS" {
		t.Errorf("X-Cache = %q, want MISS", response.Headers["X-Cache"])
	}

	var payload processResponse
	if err := json.Unmarshal([]byte(response.Body), &payload); err != nil {
		t.Fatalf("body no es JSON valido: %v", err)
	}
	if payload.Result != "aloh" {
		t.Errorf("result = %q, want aloh", payload.Result)
	}

	key := cacheKey("hola")
	objectKey := "results/" + time.Now().UTC().Format("2006-01-02") + "/" + key + ".json"
	if _, ok := store.objects[objectKey]; !ok {
		t.Errorf("objeto %q no fue persistido en S3", objectKey)
	}
	if _, ok := cache.stored[key]; !ok {
		t.Error("el resultado no fue escrito en Redis")
	}
	if ttl := cache.ttls[key]; ttl != 60*time.Second {
		t.Errorf("TTL = %v, want 60s", ttl)
	}
}

func TestProcessCacheHit(t *testing.T) {
	cache := newFakeCache()
	store := newFakeStore()
	key := cacheKey("hola")
	cached := `{"cache_key":"` + key + `","result":"aloh"}`
	cache.stored[key] = cached

	response, err := process(context.Background(), dependencies{cache: cache, store: store}, events.APIGatewayProxyRequest{Body: "hola"})
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if response.StatusCode != http.StatusOK {
		t.Errorf("status = %d, want 200", response.StatusCode)
	}
	if response.Headers["X-Cache"] != "HIT" {
		t.Errorf("X-Cache = %q, want HIT", response.Headers["X-Cache"])
	}
	if response.Body != cached {
		t.Errorf("body = %q, want el valor cacheado", response.Body)
	}
	if len(store.objects) != 0 {
		t.Error("un HIT no debe escribir en S3")
	}
}

func TestProcessRedisError(t *testing.T) {
	cache := newFakeCache()
	cache.getErr = errors.New("conexion rechazada")
	store := newFakeStore()

	response, err := process(context.Background(), dependencies{cache: cache, store: store}, events.APIGatewayProxyRequest{Body: "hola"})
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if response.StatusCode != http.StatusInternalServerError {
		t.Errorf("status = %d, want 500", response.StatusCode)
	}
	if response.Headers["X-Cache"] != "MISS" {
		t.Errorf("X-Cache = %q, want MISS", response.Headers["X-Cache"])
	}

	var payload errorResponse
	if err := json.Unmarshal([]byte(response.Body), &payload); err != nil {
		t.Fatalf("body no es JSON valido: %v", err)
	}
	if payload.Error == "" {
		t.Error("el 500 debe incluir un mensaje descriptivo")
	}
}

func TestProcessS3Error(t *testing.T) {
	cache := newFakeCache()
	store := newFakeStore()
	store.putErr = errors.New("acceso denegado")

	response, err := process(context.Background(), dependencies{cache: cache, store: store}, events.APIGatewayProxyRequest{Body: "hola"})
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if response.StatusCode != http.StatusInternalServerError {
		t.Errorf("status = %d, want 500", response.StatusCode)
	}
	if len(cache.stored) != 0 {
		t.Error("si S3 falla no se debe escribir en Redis")
	}
}

func TestProcessRedisWriteError(t *testing.T) {
	cache := newFakeCache()
	cache.setErr = errors.New("memoria llena")
	store := newFakeStore()

	response, err := process(context.Background(), dependencies{cache: cache, store: store}, events.APIGatewayProxyRequest{Body: "hola"})
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if response.StatusCode != http.StatusInternalServerError {
		t.Errorf("status = %d, want 500", response.StatusCode)
	}
}

func TestInternalServerError(t *testing.T) {
	response, err := internalServerError("algo exploto")
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if response.StatusCode != http.StatusInternalServerError {
		t.Errorf("status = %d, want 500", response.StatusCode)
	}
	if response.Headers["X-Cache"] != "MISS" {
		t.Errorf("X-Cache = %q, want MISS", response.Headers["X-Cache"])
	}

	var payload errorResponse
	if err := json.Unmarshal([]byte(response.Body), &payload); err != nil {
		t.Fatalf("body no es JSON valido: %v", err)
	}
	if payload.Error != "algo exploto" {
		t.Errorf("error = %q, want el mensaje descriptivo", payload.Error)
	}
}

func TestHandlerPanicRecovery(t *testing.T) {
	original := deps
	defer func() { deps = original }()

	deps = dependencies{cache: panickingCache{}, store: newFakeStore()}

	response, err := handler(context.Background(), events.APIGatewayProxyRequest{Body: "hola"})
	if err != nil {
		t.Fatalf("error inesperado: %v", err)
	}
	if response.StatusCode != http.StatusInternalServerError {
		t.Errorf("status = %d, want 500", response.StatusCode)
	}
	if response.Headers["X-Cache"] != "MISS" {
		t.Errorf("X-Cache = %q, want MISS", response.Headers["X-Cache"])
	}
}
