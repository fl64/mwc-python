# Mutating webhook python demo

This demo was created for the purpose of playing with mutation webhooks, no serious purpose was intended lol :)

The main task of this hook is to select Pods by the given criteria, take all available Pod annotations and create corresponding labels.

## Requirements
- docker
- docker-compose
- Make
- cfssl (optional when u deploy with helm)
- helm (optional)

## How to use:

### Build

```bash
make build
make push
```

### Local testing

```bash
# up
make up
# test
curl -k -X POST -H "Content-Type: application/json" --data @test/request.json https://localhost:5000/mutate
# down
make down
make clean
```

### Deploy with k8s manifests

```bash
# deply
make k8s_deploy_app
# test
kubectl apply -f test/demo.yaml
# cleanup
make clean
```

### Deploy with helm

```bash
# deploy
helm install mwc-app-demo helm/mwc-demo/ -n mwc-ns --create-namespace
# test
kubectl apply -f test/demo.yaml
# uninstall
helm uninstall mwc-app-demo -n mwc-ns
```
