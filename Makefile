REGISTRY_REPO=fl64
CONTAINER_NAME=annotation-to-labels
VER:=$(shell git describe --tags)
VER:=$(if $(CONTAINER_VER),$(CONTAINER_VER),"test")

NAMESPACE=mwc-demo

CONTAINER_NAME_TAG=$(REGISTRY_REPO)/$(CONTAINER_NAME):$(VER)
CONTAINER_NAME_LATEST=$(REGISTRY_REPO)/$(CONTAINER_NAME):latest

TEMP_DIR=./tmp

up: cfssl_generate_certs
	docker-compose up -d --build

down:
	docker-compose down

build:
	echo $(CONTAINER_VER)
	docker build -t $(CONTAINER_NAME_TAG) .

latest: build
	docker tag $(CONTAINER_NAME_TAG) $(CONTAINER_NAME_LATEST)

push: build
	docker push $(CONTAINER_NAME_TAG)

push_latest: push latest
	docker push $(CONTAINER_NAME_LATEST)

cfssl_temp_dir:
	mkdir -p $(TEMP_DIR)

cfssl_generate_ca: cfssl_temp_dir
	cfssl gencert -initca pki/ca-csr.json | cfssljson -bare $(TEMP_DIR)/ca –

cfssl_generate_certs: cfssl_generate_ca
	cfssl gencert -ca=$(TEMP_DIR)/ca.pem -ca-key=$(TEMP_DIR)/ca-key.pem -config=pki/ca-config.json -profile=server pki/server-csr.json | cfssljson -bare $(TEMP_DIR)/mwc-tls

k8s_create_ns:
	kubectl create namespace $(NAMESPACE) || true

k8s_create_secret: k8s_create_ns cfssl_generate_certs
	kubectl -n $(NAMESPACE) create secret tls mwc-certs \
    --cert "$(TEMP_DIR)/mwc-tls.pem" \
    --key "$(TEMP_DIR)/mwc-tls-key.pem" || true

k8s_deploy_app: k8s_create_secret
	kubectl apply -n $(NAMESPACE)  -f k8s-manifests/mwc-deployment.yaml
	cat k8s-manifests/mwc-webhook.yaml | sed "s/%CA_BUNDLE%/$(shell openssl base64 -A <"$(TEMP_DIR)/ca.pem")/g" | kubectl apply -n $(NAMESPACE) -f -

k8s_cleanup:
	kubectl delete ns $(NAMESPACE) --force --grace-period=0 || true
	kubectl delete mutatingwebhookconfigurations.admissionregistration.k8s.io mwc-webhook || true

clean: k8s_cleanup
	rm -rf $(TEMP_DIR)
