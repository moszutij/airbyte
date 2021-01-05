#!/usr/bin/env bash

set -e

. tools/lib/lib.sh

assert_root

trap 'trap - SIGTERM && kill 0' SIGINT SIGTERM EXIT

echo "Starting app..."

echo "Applying dev manifests to kubernetes..."
kubectl apply -k kube/overlays/dev

sleep 30s

kubectl get pods
kubectl describe pods
kubectl logs svc/airbyte-server-svc

echo "Waiting for server to be ready..."
kubectl wait --for=condition=Available deployment/airbyte-server --timeout=200s

sleep 30s

kubectl port-forward svc/airbyte-server-svc 8001:8001 &

echo "Running e2e tests via gradle..."
./gradlew --no-daemon :airbyte-tests:acceptanceTests --scan --tests "*AcceptanceTestsKube"