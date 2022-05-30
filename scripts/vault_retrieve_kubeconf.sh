#!/bin/bash
[ -z "$ROLE_ID" ] && export ROLE_ID="vault_role_env"
[ -z "$SECRET_ID" ] && export SECRET_ID="vault_secret_id_env"
[ -z "$VAULT_HOST" ] && export VAULT_HOST="vault_host_env"
SECRET_ENDPOINT="secret/data/build/k8s/mln/mln-kube-cluster-docker_build_env_kubeconfig"
VAULT_PORT="8200"
VAULT_LOGIN_URL="http://$VAULT_HOST:$VAULT_PORT/v1/auth/approle/login"
VAULT_SECRET_URL="http://$VAULT_HOST:$VAULT_PORT/v1/$SECRET_ENDPOINT"
### Retrieves the kubeconfig from vault and writes it to default location###
VAULT_TOKEN=$(curl -s -X POST -d '{"role_id":"'$ROLE_ID'","secret_id":"'$SECRET_ID'"}' $VAULT_LOGIN_URL | jq .auth.client_token | sed 's/"//g')
SECRET_OUTPUT=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" -H "Content-Type: application/json" "$VAULT_SECRET_URL")
echo "$VAULT_TOKEN"
echo "$SECRET_OUTPUT"
echo "$(echo "$SECRET_OUTPUT" | jq .data.data.value | sed 's/"//g' | base64 -d)" >  ~/.kube/config
