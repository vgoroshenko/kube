#!/bin/bash

#eval "$(jq -r '@sh "ROLE_ID=\(.role_id // "") SECRET_ID=\(.secret_id // "") SECRET_ENDPOINT=\(.secret_endpoint // "")"')"
[ -z "$ROLE_ID" ] && export ROLE_ID="vault_role_env"
[ -z "$SECRET_ID" ] && export SECRET_ID="vault_secret_id_env"
[ -z "$VAULT_HOST" ] && export VAULT_HOST="vault_host_env"
SECRET_ENDPOINT="secret/data/build/k8s/mln/url/docker_build_env"
VAULT_PORT="8200"
VAULT_LOGIN_URL="http://$VAULT_HOST:$VAULT_PORT/v1/auth/approle/login"
VAULT_TOKEN=$(curl -s -X POST -d '{"role_id":"'$ROLE_ID'","secret_id":"'$SECRET_ID'"}' $VAULT_LOGIN_URL | jq .auth.client_token | sed 's/"//g')

aws eks --region eu-central-1 update-kubeconfig --name mln-kube-cluster-docker_build_env
SERVICE_ACCOUNT=user1

# Get the ServiceAccount's token Secret's name
SECRET=$(kubectl get serviceaccount ${SERVICE_ACCOUNT} -o json | jq -Mr '.secrets[].name | select(contains("token"))')

# Write ca.crt to vault
CACERT=$(kubectl get secret ${SECRET} -o json | jq -Mr '.data["ca.crt"]')

# Extract the Bearer token from the Secret and decode
TOKEN=$(kubectl get secret ${SECRET} -o json | jq -Mr '.data.token' | base64 -d)
# Get the API Server location
APISERVER=$(kubectl config view --minify | grep server | cut -f 2- -d ":" | tr -d " ")

# Write cert, token and url to vault
curl -H "X-Vault-Token: $VAULT_TOKEN" \
    -H "Content-Type:application/json" \
    -X POST \
    -d "{\"data\":{\"value\":\"$CACERT\",\"token\":\"$TOKEN\",\"apiserver\":\"$APISERVER\"}}" \
    http://$VAULT_HOST:8200/v1/${SECRET_ENDPOINT}
