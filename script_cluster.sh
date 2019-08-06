#key ring can't be delete to avoid name collision, therefore this is a one shot creation, thus the commented out line. I leave them as a example

# we're creating encryption key to add application layer encryption to the kubernetes secret stored in ETCD
#gcloud kms keyrings create gkesecret_ring \
#    --location europe-west1 \
#    --project olivierba-sandbox

#gcloud kms keys create gkesecret_key \
#    --location europe-west1 \
#    --keyring gkesecret_ring \
#    --purpose encryption \
#    --project olivierba-sandbox


#gcloud kms keys add-iam-policy-binding gkesecret_key \
#  --location europe-west1 \
#  --keyring gkesecret_ring \
#  --member serviceAccount:service-361681312054@container-engine-robot.iam.gserviceaccount.com \
#  --role roles/cloudkms.cryptoKeyEncrypterDecrypter \
#  --project olivierba-sandbox


gcloud beta container clusters create ks-test \
      --node-locations=europe-west1-b,europe-west1-c \
      --cluster-version=1.13.7-gke.8 \
      --enable-autorepair \
      --enable-cloud-monitoring --enable-cloud-logging --project olivierba-sandbox --enable-stackdriver-kubernetes \
      --image-type=COS_CONTAINERD --enable-autoupgrade \
      --database-encryption-key=projects/olivierba-sandbox/locations/europe-west1/keyRings/gkesecret_ring/cryptoKeys/gkesecret_key \
      --identity-namespace=olivierba-sandbox.svc.id.goog \
      --enable-ip-alias \
      --create-subnetwork name=ks-test-subnet \
      --enable-network-policy #\
      #--enable-pod-security-policy #there seems to be a issue with podsecurity policy in conjunction with workload identity disabling for now


#kubectl apply -f cluster-setup/psp-unrestricted.yaml
#kubectl apply -f cluster-setup/psp-restricted.yaml


# service account for workload indentity
gcloud iam service-accounts create gke-workload-identity --display-name "GKE Workload Identity GSA"

#kubectl create namespace service-accounts

kubectl create serviceaccount --namespace default gkewid-service

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:olivierba-sandbox.svc.id.goog[default/gkewid-service]" \
  gke-workload-identity@olivierba-sandbox.iam.gserviceaccount.com

kubectl annotate serviceaccount --namespace default gkewid-service iam.gke.io/gcp-service-account=gke-workload-identity@olivierba-sandbox.iam.gserviceaccount.com
