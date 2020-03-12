#used for hadcore mode in conjuction with -enable-private-endpoint option

#Our GKE master is not exposed to the internet and only accessible from gke-subnet let's create a bastion proxy to reach the master
gcloud compute instances create --subnet=gke-subnet \
    --project $PROJECTID \
    --zone=europe-west1-b \
    --scopes cloud-platform gke-proxy


export PROXY_IP=`gcloud compute instances describe gke-proxy --project $PROJECTID --zone=europe-west1-b \
    --format="value(networkInterfaces[0].networkIP)"`

# allow our IP
gcloud container clusters update ks-test \
    --region=europe-west1 \
    --project $PROJECTID \
    --enable-master-authorized-networks \
    --master-authorized-networks $PROXY_IP/32

#building our proxy container
docker build -t gcr.io/$PROJECTID/k8s-api-proxy:0.1 proxy/.
docker push gcr.io/$PROJECTID/k8s-api-proxy:0.1

#signing the image manually
DIGEST="sha256:557b10b2a29ddda94a00844987e66244e00346c5af3da7a84dcdc1e5cc1a6d4a" # Replace with current value

gcloud beta container binauthz attestations sign-and-create \
  --project "${PROJECTID}" \
  --artifact-url "gcr.io/${PROJECTID}/k8s-api-proxy@${DIGEST}" \
  --attestor "vulnz-attestor" \
  --attestor-project "${PROJECTID}" \
  --keyversion "1" \
  --keyversion-key "vulnz-signerz" \
  --keyversion-location "europe-west1" \
  --keyversion-keyring "binauthz" \
  --keyversion-project "${PROJECTID}"

#now connect on the VM via SSH

sudo apt-get install kubectl

gcloud container clusters get-credentials ks-test \
--region europe-west1 --internal-ip 

export PROJECT_ID=`gcloud config list --format="value(core.project)"`

#run this on the proxy (without psp the proxy container won't run), copy the file on the proxy first or clone the repo
kubectl apply -f cluster-setup/psp-unrestricted.yaml

kubectl run k8s-api-proxy \
    --image=gcr.io/$PROJECT_ID/k8s-api-proxy:0.1 \
    --port=8118
    --namespace=godemode

kubectl create -f cluster-setup/proxy-lb.yaml


#you may need to run the VM with a SA with cluster admin privileges


export LB_IP=`kubectl get service/k8s-api-proxy -o jsonpath='{.status.loadBalancer.ingress[].ip} --namespace=godmode'`

export MASTER_IP=`gcloud container clusters describe ks-test --project ${PROJECTID} --region=europe-west1 --format="get(privateClusterConfig.privateEndpoint)"`

# test
curl -k -x $LB_IP:8118 https://$MASTER_IP/api
