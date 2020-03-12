# clone git clone https://github.com/GoogleCloudPlatform/gke-binary-auth-tools ~/binauthz-tools to get the source to build the CVE Scanner
export PROJECT_ID="orbital-signal-243013"
export REGION="europe-west1"
export PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" \
  --format='value(projectNumber)')"

export CLOUD_BUILD_SA_EMAIL="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

SHORT_SHA=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 7 ; echo '')


gcloud builds submit --project $PROJECT_ID --config hello-app/cloudbuild.yaml hello-app/. \
    --substitutions SHORT_SHA=$SHORT_SHA,_COMPUTE_REGION=$REGION,_KMS_KEYRING="binauthz",_KMS_LOCATION=$REGION,_STAGING_CLUSTER="ks-test",_VULNZ_ATTESTOR="vulnz-attestor",_VULNZ_KMS_KEY="vulnz-signerz",_VULNZ_KMS_KEY_VERSION=1