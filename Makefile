# Check to see if we can use ash, in Alpine images, or default to BASH.
SHELL_PATH = /bin/ash
SHELL = $(if $(wildcard $(SHELL_PATH)),/bin/ash,/bin/bash)

run:
	go run apis/services/sales/main.go | go run apis/tooling/logfmt/main.go

# ==============================================================================
# Define dependencies

GOLANG          := golang:1.24
ALPINE          := alpine:3.22
KIND            := kindest/node:v1.33.1
POSTGRES        := postgres:17.5
GRAFANA         := grafana/grafana:11.6.0
PROMETHEUS      := prom/prometheus:v3.4.0
TEMPO           := grafana/tempo:2.7.0
LOKI            := grafana/loki:3.5.0
PROMTAIL        := grafana/promtail:3.5.0

KIND_CLUSTER    := ardan-starter-cluster
NAMESPACE       := sales-system
SALES_APP       := sales
AUTH_APP        := auth
BASE_IMAGE_NAME := localhost/ardanlabs
VERSION         := 0.0.1
SALES_IMAGE     := $(BASE_IMAGE_NAME)/$(SALES_APP):$(VERSION)
METRICS_IMAGE   := $(BASE_IMAGE_NAME)/metrics:$(VERSION)
AUTH_IMAGE      := $(BASE_IMAGE_NAME)/$(AUTH_APP):$(VERSION)

# ==============================================================================
# Running from within k8s/kind

dev-up:
	kind create cluster \
		--image $(KIND) \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/dev/kind-config.yaml

	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner

	kind load docker-image $(POSTGRES) --name $(KIND_CLUSTER) & \
	kind load docker-image $(GRAFANA) --name $(KIND_CLUSTER) & \
	kind load docker-image $(PROMETHEUS) --name $(KIND_CLUSTER) & \
	kind load docker-image $(TEMPO) --name $(KIND_CLUSTER) & \
	kind load docker-image $(LOKI) --name $(KIND_CLUSTER) & \
	kind load docker-image $(PROMTAIL) --name $(KIND_CLUSTER) & \
	wait;

dev-down:
	kind delete cluster --name $(KIND_CLUSTER)

dev-status-all:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

dev-status:
	watch -n 2 kubectl get pods -o wide --all-namespaces

# ==============================================================================
# Modules support

deps-reset:
	git checkout -- go.mod
	go mod tidy
	go mod vendor

tidy:
	go mod tidy
	go mod vendor

