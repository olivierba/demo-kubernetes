kubectl delete -f kubernetes-manifests/guestbook-service.json
kubectl delete -f kubernetes-manifests/guestbook-controller.json

kubectl delete -f kubernetes-manifests/redis-statefulset.yaml
kubectl delete -f kubernetes-manifests/redis-slave-network-policy.yaml 
kubectl delete -f kubernetes-manifests/redis-master-service.yaml
kubectl delete -f kubernetes-manifests/redis-master-deployment.yaml
kubectl delete -f kubernetes-manifests/redis-master-network-policy.yaml
kubectl delete -f kubernetes-manifests/pvc-redis-master.yaml
kubectl delete -f kubernetes-manifests/redis-config.yaml


#kubectl delete -f cluster-setup/psp-unrestricted.yaml
#kubectl delete -f cluster-setup/psp-restricted.yaml


#kubectl delete -f debugpod.yaml

gcloud container clusters delete ks-test --zone europe-west1-b --quiet --project olivierba-sandbox

gcloud iam service-accounts remove-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:olivierba-sandbox.svc.id.goog[default/gkewid-service]" \
  gke-workload-identity@olivierba-sandbox.iam.gserviceaccount.com

gcloud iam service-accounts delete gke-workload-identity@olivierba-sandbox.iam.gserviceaccount.com --quiet