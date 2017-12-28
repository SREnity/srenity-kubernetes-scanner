SREnity Kubernetes Scanner
==========================

A kubernetes CronJob which periodically scans your cluster and reports metrics to the SREnity Dashboard.

Getting Started
---------------
Clone the respository, run the included `generate_deployment_yamls.sh` script, provide your SREnity public ID and private keys which you created for the kubernetes plugin (at https://srenitydashboard.io/user/plugins), and then apply the `srenity-service-secret-deployment.yaml` that is created to your cluster via `kubectl apply -f srenity-service-secret-deployment.yaml`.

Be careful though!  This file will contain your private key secret, so do not check in the YAML to source control!
