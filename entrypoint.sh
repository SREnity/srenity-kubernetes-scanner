#!/bin/bash
set -e

echo "$(date -u): Pulling public key information from srenitydashboard.io"
curl 'https://srenitydashboard.io/api/v1/public_keys/latest.json' > public_key.json

cat public_key.json | jq '.key_body' | sed -e 's/^"//' -e 's/"$//' -e 's/\\n/\n/g' > public_key.pem
cat public_key.json | jq '.key_hash' | sed -e 's/^"//' -e 's/"$//' -e 's/\\n/\n/g' > public_key.sha
 
echo "$(date -u): Updating GCloud components."
gcloud components update

echo "$(date -u): Setting up Kubernetes connection via token."
kubectl config set-cluster currentCluster --server=\"https://${KUBERNETES_SERVICE_HOST}\"
kubectl config set-context currentCluster
kubectl config set-credentials currentCluster --token=\"$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\"
kubectl config use-context currentCluster

RESOURCES=(
  'certificatesigningrequests'
  'clusters'
  'clusterrolebindings'
  'clusterroles'
  'componentstatuses'
  'configmaps'
  'daemonsets'
  'deployments'
  'endpoints'
  'events'
  'horizontalpodautoscalers'
  'ingresses'
  'jobs'
  'limitranges'
  'namespaces'
  'networkpolicies'
  'nodes'
  'persistentvolumeclaims'
  'persistentvolumes'
  'pods'
  'poddisruptionbudgets'
  'podsecuritypolicies'
  'podtemplates'
  'replicasets'
  'replicationcontrollers'
  'resourcequotas'
  'rolebindings'
  'roles'
  'serviceaccounts'
  'services'
  'statefulsets'
  'storageclasses'
  'thirdpartyresources'
  )

echo "{" > cluster_dump.tmp

for resource in "${RESOURCES[@]}"; do 
  echo "$(date -u): Pulling information on $resource."
  chunk="\"$resource\":"
  piece=$(kubectl get --export --all-namespaces -o=json $resource | jq '.')

  if [ $? -ne 0 ]; then
    piece='{ "Error": "Invalid JSON resturned from export." }'
  fi

  if [[ -z $piece ]]; then
    piece="{}"
  fi

  echo -n "$chunk$piece" >> cluster_dump.tmp
  if [ $resource != "${RESOURCES[@]: -1:1}" ]; then
    echo "," >> cluster_dump.tmp
  fi
  echo "$(date -u): Finished pulling information on $resource."
done

echo "}" >> cluster_dump.tmp


echo "$(date -u): Creating shared secret for encryption."
openssl rand -base64 16 -out secret_key.bin

echo "$(date -u): Encrypting JSON with new secret."
openssl enc -aes-256-cbc -salt -in cluster_dump.tmp -out cluster_dump.tmp.enc -pass file:secret_key.bin -p | awk -F"=" 'FNR>=2{printf "%s:",$2}' | sed 's/:$//g' > secret_key_data.bin

echo "$(date -u): Encrypting secret with public key."
openssl rsautl -encrypt -inkey public_key.pem -pubin -in secret_key_data.bin -out secret_key.bin.enc

echo "$(date -u): Building POST JSON."
echo -n '{"key": "' > final_data.json
cat secret_key.bin.enc | base64 -w0 >> final_data.json
echo -n '", "hash": "' >> final_data.json 
cat public_key.sha | base64 -w0 >> final_data.json
echo -n '", "data": "' >> final_data.json 
cat cluster_dump.tmp.enc | base64 -w0 >> final_data.json
echo -n '"}' >> final_data.json

echo "$(date -u): Sending data to srenitydashboard.io external endpoint."
curl -H "Authorization: Token token=\"${PUBLIC_ID}:${PRIVATE_KEY}\"" -H 'Content-type: application/json' --data @final_data.json -vvv 'https://srenitydashboard.io/api/v1/user_plugins/external_update.json'
