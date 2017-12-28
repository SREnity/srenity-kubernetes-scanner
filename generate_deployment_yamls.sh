#!/bin/bash

if [[ -z ${PUBLIC_ID} ]]; then
  echo "Enter your public ID to generate deployment YAMLs:"
  read PUBLIC_ID 
  echo ""
else
  echo "Public ID set from environment variable..." 
  echo ""
fi

if [[ -z ${PRIVATE_KEY} ]]; then
  echo "Enter your private key to generate deployment YAMLs:"
  read PRIVATE_KEY
  echo ""
else
  echo "Private key set from environment variable..." 
  echo ""
fi

B64_PUBLIC_ID=$(echo $PUBLIC_ID | base64 -w0)
B64_PRIVATE_KEY=$(echo $PRIVATE_KEY | base64 -w0)

cat srenity-service-template.yaml | sed -e "s/{PUBLIC_ID_PLACEHOLDER}/$B64_PUBLIC_ID/" -e "s/{PRIVATE_KEY_PLACEHOLDER}/$B64_PRIVATE_KEY/" > srenity-service-secret-deployment.yaml

echo "#############################################################################"
echo "####              Deployment YAML was successfully created:              ####"
echo "####               srenity-service-secret-deployment.yaml!               ####"
echo "#############################################################################"
echo ""
echo ""
echo "#############################################################################"
echo "#### Be careful with this file, and DO NOT check it into source control, ####"
echo "####               as it contains your deployment secret.                ####"
echo "#############################################################################"
echo "####      Add the file name to your .gitignore if you move it to a       ####"
echo "####                     source-controlled directory.                    ####"
echo "#############################################################################"
