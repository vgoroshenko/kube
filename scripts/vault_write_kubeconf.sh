#!/bin/bash
[ -z "$ROLE_ID" ] && export ROLE_ID="vault_role_env"
[ -z "$SECRET_ID" ] && export SECRET_ID="vault_secret_id_env"
[ -z "$VAULT_HOST" ] && export VAULT_HOST="vault_host_env"
SECRET_ENDPOINT="secret/data/build/k8s/mln/mln-kube-cluster-docker_build_env_kubeconfig"
VAULT_PORT="8200"
VAULT_LOGIN_URL="http://$VAULT_HOST:$VAULT_PORT/v1/auth/approle/login"
VAULT_TOKEN=$(curl -s -X POST -d '{"role_id":"'$ROLE_ID'","secret_id":"'$SECRET_ID'"}' $VAULT_LOGIN_URL | jq .auth.client_token | sed 's/"//g')
echo $VAULT_TOKEN
aws eks --region eu-central-1 update-kubeconfig --name mln-kube-cluster-docker_build_env
config=$(base64 -w 0 ~/.kube/config)
curl -H "X-Vault-Token: $VAULT_TOKEN" \
    -H "Content-Type:application/json" \
    -X POST \
    -d "{\"data\":{\"value\":\"$config\"}}" \
    http://$VAULT_HOST:8200/v1/${SECRET_ENDPOINT}
