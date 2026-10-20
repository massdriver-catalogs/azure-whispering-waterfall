// Command orders-processor is a hello-world Go service for AKS.
//
// GET  /         says hello and calls GET /api/hello on the Orders API.
// POST /orders   sends an order event to the queue and writes a receipt blob.
// GET  /healthz  answers 200.
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
	"github.com/Azure/azure-sdk-for-go/sdk/storage/azqueue"
)

type config struct {
	port         string
	serviceName  string
	ordersAPIURL string
	queueName    string
	queueConn    string
	container    string
	blobConn     string
}

func loadConfig() config {
	return config{
		port:         env("PORT", "8080"),
		serviceName:  env("SERVICE_NAME", "orders-processor"),
		ordersAPIURL: strings.TrimSuffix(os.Getenv("ORDERS_API_URL"), "/"),
		queueName:    os.Getenv("EVENTS_QUEUE_NAME"),
		queueConn:    os.Getenv("EVENTS_CONNECTION_STRING"),
		container:    os.Getenv("RECEIPTS_CONTAINER"),
		blobConn:     os.Getenv("RECEIPTS_CONNECTION_STRING"),
	}
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

type server struct {
	cfg    config
	http   *http.Client
	queue  *azqueue.QueueClient
	blobs  *azblob.Client
	logger *slog.Logger
}

type orderEvent struct {
	OrderID   string    `json:"orderId"`
	Item      string    `json:"item"`
	Quantity  int       `json:"quantity"`
	CreatedAt time.Time `json:"createdAt"`
	Source    string    `json:"source"`
}

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	cfg := loadConfig()
	s := &server{cfg: cfg, http: &http.Client{Timeout: 10 * time.Second}, logger: logger}

	if cfg.queueConn != "" && cfg.queueName != "" {
		q, err := azqueue.NewQueueClientFromConnectionString(cfg.queueConn, cfg.queueName, nil)
		if err != nil {
			logger.Error("queue client", "err", err)
			os.Exit(1)
		}
		s.queue = q
	}
	if cfg.blobConn != "" {
		b, err := azblob.NewClientFromConnectionString(cfg.blobConn, nil)
		if err != nil {
			logger.Error("blob client", "err", err)
			os.Exit(1)
		}
		s.blobs = b
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) })
	mux.HandleFunc("GET /{$}", s.hello)
	mux.HandleFunc("POST /orders", s.createOrder)

	logger.Info("listening", "port", cfg.port)
	srv := &http.Server{Addr: ":" + cfg.port, Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	if err := srv.ListenAndServe(); err != nil {
		logger.Error("server", "err", err)
		os.Exit(1)
	}
}

// hello calls the Orders API and returns both greetings.
func (s *server) hello(w http.ResponseWriter, r *http.Request) {
	resp := map[string]any{
		"service": s.cfg.serviceName,
		"message": "Hello from the Orders Processor (Go on AKS)",
	}
	if s.cfg.ordersAPIURL == "" {
		resp["ordersApi"] = "ORDERS_API_URL is not set"
	} else {
		api, err := s.callOrdersAPI(r.Context())
		if err != nil {
			resp["ordersApiError"] = err.Error()
		} else {
			resp["ordersApi"] = api
		}
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *server) callOrdersAPI(ctx context.Context) (any, error) {
	url := fmt.Sprintf("%s/api/hello?from=%s", s.cfg.ordersAPIURL, s.cfg.serviceName)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	res, err := s.http.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	body, err := io.ReadAll(io.LimitReader(res.Body, 1<<20))
	if err != nil {
		return nil, err
	}
	if res.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("orders api returned %d: %s", res.StatusCode, string(body))
	}
	var out any
	if err := json.Unmarshal(body, &out); err != nil {
		return string(body), nil
	}
	return out, nil
}

// createOrder sends an order event to the queue and writes a receipt blob.
func (s *server) createOrder(w http.ResponseWriter, r *http.Request) {
	if s.queue == nil || s.blobs == nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "the queue or the blob storage is not connected"})
		return
	}
	var in struct {
		Item     string `json:"item"`
		Quantity int    `json:"quantity"`
	}
	_ = json.NewDecoder(io.LimitReader(r.Body, 1<<16)).Decode(&in)
	if in.Item == "" {
		in.Item = "widget"
	}
	if in.Quantity <= 0 {
		in.Quantity = 1
	}
	event := orderEvent{
		OrderID:   fmt.Sprintf("ord-%d", time.Now().UnixNano()),
		Item:      in.Item,
		Quantity:  in.Quantity,
		CreatedAt: time.Now().UTC(),
		Source:    s.cfg.serviceName,
	}
	body, _ := json.Marshal(event)

	if _, err := s.queue.EnqueueMessage(r.Context(), string(body), nil); err != nil {
		s.logger.Error("enqueue", "err", err)
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": "enqueue: " + err.Error()})
		return
	}
	blobName := "receipts/" + event.OrderID + ".json"
	if _, err := s.blobs.UploadBuffer(r.Context(), s.cfg.container, blobName, body, nil); err != nil {
		s.logger.Error("receipt", "err", err)
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": "receipt: " + err.Error()})
		return
	}
	s.logger.Info("order created", "orderId", event.OrderID)
	writeJSON(w, http.StatusAccepted, map[string]any{"order": event, "queue": s.cfg.queueName, "receipt": s.cfg.container + "/" + blobName})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
