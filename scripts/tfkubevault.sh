#!/usr/bin/env bash

set -e

#cluster_name="mln-kube-cluster-dev"
#[ -z "$ROLE_ID" ] && export ROLE_ID="vault_role_env"
#[ -z "$SECRET_ID" ] && export SECRET_ID="vault_secret_id_env"
#SECRET_ENDPOINT="secret/data/build/k8s/${cluster_name}_kubeconfig"

[ -z "$ROLE_ID" ] && export ROLE_ID="vault_role_env"
[ -z "$SECRET_ID" ] && export SECRET_ID="vault_secret_id_env"
[ -z "$VAULT_HOST" ] && export VAULT_HOST="vault_host_env"
eval "$(jq -r '@sh "ROLE_ID=\(.role_id // "") SECRET_ID=\(.secret_id // "") SECRET_ENDPOINT=\(.secret_endpoint // "")"')"
VAULT_PORT="8200"
VAULT_LOGIN_URL="http://$VAULT_HOST:$VAULT_PORT/v1/auth/approle/login"
VAULT_SECRET_URL="http://$VAULT_HOST:$VAULT_PORT/v1/$SECRET_ENDPOINT"
# Retrieve the secret from vault
VAULT_TOKEN=$(curl -s -X POST -d '{"role_id":"'$ROLE_ID'","secret_id":"'$SECRET_ID'"}' $VAULT_LOGIN_URL | jq .auth.client_token | sed 's/"//g')
SECRET_OUTPUT=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" -H "Content-Type: application/json" "$VAULT_SECRET_URL")
# Check that permissions are fine
echo $SECRET_OUTPUT | grep -qv "permission denied" || (>&2 echo "Permission denied"; exit 1)
FILENAME=`basename ${SECRET_ENDPOINT}`.secret
# Output the secret
if [ -z `echo "$SECRET_OUTPUT" | jq '.data.data.value // empty'` ];
then
  echo "$SECRET_OUTPUT" | jq '.data.data'
else
  echo "$SECRET_OUTPUT" | jq '.data.data.value' | sed 's/"//g' | base64 -d > $FILENAME
  #echo "$(echo "$SECRET_OUTPUT" | jq .data.data.value | sed 's/"//g' | base64 -d)" >  ~/.kube/config
  jq -n --arg filename "$FILENAME" '{"filename": $filename}'
fi
