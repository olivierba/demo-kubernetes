
PROJECTID=orbital-signal-243013
PROJECTNUMBER=469755381865
MYIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
CLOUD_BUILD_SA_EMAIL="${PROJECTNUMBER}@cloudbuild.gserviceaccount.com"

# we're creating encryption key to add application layer encryption to the kubernetes secret stored in ETCD
gcloud kms keyrings create gkesecret_ring \
    --location europe-west1 \
    --project $PROJECTID

gcloud kms keys create gkesecret_key \
    --location europe-west1 \
    --keyring gkesecret_ring \
    --purpose encryption \
    --project $PROJECTID

#GKE can use the key iam binding
gcloud kms keys add-iam-policy-binding gkesecret_key \
  --location europe-west1 \
  --keyring gkesecret_ring \
  --member serviceAccount:service-$PROJECTNUMBER@container-engine-robot.iam.gserviceaccount.com \
  --role roles/cloudkms.cryptoKeyEncrypterDecrypter \
  --project $PROJECTID



# service account for workload identity
gcloud iam service-accounts create gke-workload-identity --display-name "GKE Workload Identity GSA"

#for binauth
gcloud projects add-iam-policy-binding "${PROJECTID}" \
  --member "serviceAccount:${CLOUD_BUILD_SA_EMAIL}" \
  --role "roles/container.developer"

gcloud kms keyrings create "binauthz" \
  --project "${PROJECTID}" \
  --location "europe-west1"

gcloud kms keys create "vulnz-signerz" \
  --project "${PROJECTID}" \
  --location "europe-west1" \
  --keyring "binauthz" \
  --purpose "asymmetric-signing" \
  --default-algorithm "rsa-sign-pkcs1-4096-sha512"


  # vulnerability attestor

  curl "https://containeranalysis.googleapis.com/v1/projects/${PROJECTID}/notes/?noteId=vulnz-note" \
  --request "POST" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $(gcloud auth print-access-token)" \
  --header "X-Goog-User-Project: ${PROJECTID}" \
  --data-binary @- <<EOF
    {
      "name": "projects/${PROJECTID}/notes/vulnz-note",
      "attestation": {
        "hint": {
          "human_readable_name": "Vulnerability scan note"
        }
      }
    }
EOF

curl "https://containeranalysis.googleapis.com/v1beta1/projects/${PROJECTID}/notes/vulnz-note:setIamPolicy" \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $(gcloud auth print-access-token)" \
  --header "X-Goog-User-Project: ${PROJECTID}" \
  --data-binary @- <<EOF
    {
      "resource": "projects/${PROJECTID}/notes/vulnz-note",
      "policy": {
        "bindings": [
          {
            "role": "roles/containeranalysis.notes.occurrences.viewer",
            "members": [
              "serviceAccount:${CLOUD_BUILD_SA_EMAIL}"
            ]
          },
          {
            "role": "roles/containeranalysis.notes.attacher",
            "members": [
              "serviceAccount:${CLOUD_BUILD_SA_EMAIL}"
            ]
          }
        ]
      }
    }
EOF

gcloud container binauthz attestors create "vulnz-attestor" \
  --project "${PROJECTID}" \
  --attestation-authority-note-project "${PROJECTID}" \
  --attestation-authority-note "vulnz-note" \
  --description "Vulnerability scan attestor"

gcloud beta container binauthz attestors public-keys add \
  --project "${PROJECTID}" \
  --attestor "vulnz-attestor" \
  --keyversion "1" \
  --keyversion-key "vulnz-signerz" \
  --keyversion-keyring "binauthz" \
  --keyversion-location "europe-west1" \
  --keyversion-project "${PROJECTID}"

gcloud container binauthz attestors add-iam-policy-binding "vulnz-attestor" \
  --project "${PROJECTID}" \
  --member "serviceAccount:${CLOUD_BUILD_SA_EMAIL}" \
  --role "roles/binaryauthorization.attestorsVerifier"

gcloud kms keys add-iam-policy-binding "vulnz-signerz" \
  --project "${PROJECTID}" \
  --location "europe-west1" \
  --keyring "binauthz" \
  --member "serviceAccount:${CLOUD_BUILD_SA_EMAIL}" \
  --role 'roles/cloudkms.signerVerifier'

  #gcloud kms keys add-iam-policy-binding binauth \
  #--project "${PROJECTID}" \
  #--location "europe-west1" \
  #--keyring "binauthz" \
  #--member "serviceAccount:${CLOUD_BUILD_SA_EMAIL}" \
  #--role roles/cloudkms.cryptoKeyDecrypter

#create secure gke cluster
#network policy, Pod security policy, COS CONTAINERD, KMS encrypted ETCD, workload identity, private cluster, shielded node, activate stackdrivers logs, create own subnet for nodes
gcloud beta container clusters create ks-test \
      --region=europe-west1 \
      --release-channel regular \
      --enable-autorepair \
      --enable-stackdriver-kubernetes \
      --project $PROJECTID \
      --image-type=COS_CONTAINERD --enable-autoupgrade \
      --enable-shielded-nodes \
      --database-encryption-key=projects/$PROJECTID/locations/europe-west1/keyRings/gkesecret_ring/cryptoKeys/gkesecret_key \
      --create-subnetwork name=gke-subnet \
      --enable-ip-alias \
      --enable-private-nodes \
      --master-ipv4-cidr 172.16.0.0/28 \
      --enable-master-authorized-networks \
      --enable-network-policy \
      --enable-pod-security-policy \
      --identity-namespace=$PROJECTID.svc.id.goog \
      --enable-binauthz
      #--enable-private-endpoint \ #hardcore mode, the control plane API can only be accessed via internal private IP. More secure, but not very convenient

# note I use a cloud NAT router to allow egress access from my nodes, this can be disable for even more secure mode at the expense of access to public registries such at dockerhub

#binauth policy
gcloud container binauthz policy import ./binauthz-policy.yaml \
  --project "${PROJECTID}"

# allow our IP
gcloud container clusters update ks-test \
    --region=europe-west1 \
    --project $PROJECTID \
    --enable-master-authorized-networks \
    --master-authorized-networks $MYIP/32


kubectl apply -f cluster-setup/psp-unrestricted.yaml
kubectl apply -f cluster-setup/psp-restricted.yaml

#k8s SA for workload identity
kubectl create serviceaccount gkewid-sa

gcloud iam service-accounts create gkewid-service \
  --project $PROJECTID

gcloud projects add-iam-policy-binding $PROJECTID \
  --role roles/iam.serviceAccountTokenCreator \
  --member "serviceAccount:gkewid-service@${PROJECTID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECTID \
  --role roles/viewer \
  --member "serviceAccount:gkewid-service@${PROJECTID}.iam.gserviceaccount.com"

gcloud iam service-accounts add-iam-policy-binding \
  --project $PROJECTID \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECTID}.svc.id.goog[default/gkewid-sa]" \
  gkewid-service@${PROJECTID}.iam.gserviceaccount.com

kubectl annotate serviceaccount  gkewid-sa iam.gke.io/gcp-service-account=gkewid-service@$PROJECTID.iam.gserviceaccount.com

#gcloud container clusters update ks-test \
#    --region=europe-west1 \
#    --project $PROJECTID \
#    --no-enable-master-authorized-networks
