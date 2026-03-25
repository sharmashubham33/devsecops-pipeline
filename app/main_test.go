package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()

	healthHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}

	var resp HealthResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp.Status != "healthy" {
		t.Errorf("expected healthy, got %s", resp.Status)
	}

	if resp.Service != "devsecops-demo" {
		t.Errorf("expected devsecops-demo, got %s", resp.Service)
	}
}

func TestCreateOrderSuccess(t *testing.T) {
	body := OrderRequest{
		CustomerID: "CUST-001",
		Items: []Item{
			{SKU: "SKU-001", Name: "Widget", Quantity: 2, Price: 9.99},
		},
		Total: 19.98,
	}
	bodyBytes, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/orders", bytes.NewReader(bodyBytes))
	w := httptest.NewRecorder()

	createOrderHandler(w, req)

	if w.Code != http.StatusCreated {
		t.Errorf("expected 201, got %d", w.Code)
	}

	var resp OrderResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode: %v", err)
	}

	if resp.Status != "created" {
		t.Errorf("expected created, got %s", resp.Status)
	}
}

func TestCreateOrderMissingCustomerID(t *testing.T) {
	body := OrderRequest{
		Items: []Item{{SKU: "SKU-001", Name: "Widget", Quantity: 1, Price: 5.0}},
	}
	bodyBytes, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/orders", bytes.NewReader(bodyBytes))
	w := httptest.NewRecorder()

	createOrderHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestCreateOrderNoItems(t *testing.T) {
	body := OrderRequest{CustomerID: "CUST-001", Items: []Item{}}
	bodyBytes, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/orders", bytes.NewReader(bodyBytes))
	w := httptest.NewRecorder()

	createOrderHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestCreateOrderInvalidQuantity(t *testing.T) {
	body := OrderRequest{
		CustomerID: "CUST-001",
		Items:      []Item{{SKU: "SKU-001", Name: "Widget", Quantity: 0, Price: 5.0}},
	}
	bodyBytes, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/orders", bytes.NewReader(bodyBytes))
	w := httptest.NewRecorder()

	createOrderHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestCreateOrderWrongMethod(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/orders", nil)
	w := httptest.NewRecorder()

	createOrderHandler(w, req)

	if w.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected 405, got %d", w.Code)
	}
}

func TestCreateOrderInvalidJSON(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/orders", bytes.NewReader([]byte("not json")))
	w := httptest.NewRecorder()

	createOrderHandler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}
