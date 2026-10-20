.PHONY: help publish-platforms publish-resource-types publish-infra publish-runtimes publish-apps build-infra validate-infra image packages

# Publish order: platforms -> resource types -> infra bundles -> runtimes -> apps.
# An app bundle builds on top of its runtime, so the runtime must be published first.
INFRA_BUNDLES = azure-virtual-network azure-kubernetes-service azure-storage-account azure-storage-queue azure-databricks-workspace
RUNTIMES      = azure-function-nodejs azure-aks-helm-go
APPS          = azure-orders-api azure-orders-processor azure-orders-worker
RESOURCE_TYPES = $(shell find resource-types -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
IMAGE ?= ghcr.io/CHANGE-ME/azure-orders-processor:0.1.0

help:
	@echo "make publish-platforms       Publish the azure-service-principal credential type"
	@echo "make publish-resource-types  Publish every resource type (live at once, no dev channel)"
	@echo "make publish-infra           Build and publish the infra bundles to the development channel"
	@echo "make publish-runtimes        Build and publish the runtimes to the development channel"
	@echo "make publish-apps            Build and publish the app bundles to the development channel"
	@echo "make image IMAGE=...         Build and push the orders-processor container image (linux/amd64)"
	@echo "make packages                Build the zip packages of the two Function apps"

publish-platforms:
	mass resource-type publish platforms/azure/massdriver.yaml

publish-resource-types:
	@for rt in $(RESOURCE_TYPES); do \
		mass repository create $$rt -t resource-type >/dev/null 2>&1 || true; \
		mass resource-type publish resource-types/$$rt/massdriver.yaml; \
	done

# Every bundle publish uses --development. A stable release needs a human decision.
define publish_bundles
	@for b in $(1); do \
		mass repository create $$b -t bundle >/dev/null 2>&1 || true; \
		mass bundle publish --development --bundle-directory bundles/$$b || exit 1; \
	done
endef

publish-infra:
	$(call publish_bundles,$(INFRA_BUNDLES))

publish-runtimes:
	$(call publish_bundles,$(RUNTIMES))

publish-apps:
	$(call publish_bundles,$(APPS))

build-infra:
	@for b in $(INFRA_BUNDLES) azure-function-nodejs; do mass bundle build --bundle-directory bundles/$$b || exit 1; done

validate-infra: build-infra
	@for b in $(INFRA_BUNDLES) azure-function-nodejs; do (cd bundles/$$b/src && tofu init -backend=false >/dev/null && tofu validate) || exit 1; done

image:
	docker buildx build --platform linux/amd64 -t $(IMAGE) --push apps/orders-processor

packages:
	cd apps/orders-api && npm ci && npm run package
	cd apps/orders-worker && npm ci && npm run package
