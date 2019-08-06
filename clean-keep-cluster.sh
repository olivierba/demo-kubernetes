kubectl delete -f kubernetes-manifests/guestbook-service.json
kubectl delete -f kubernetes-manifests/guestbook-controller.json

kubectl delete -f kubernetes-manifests/redis-statefulset.yaml
kubectl delete -f kubernetes-manifests/redis-slave-network-policy.yaml 
kubectl delete -f kubernetes-manifests/redis-master-service.yaml
kubectl delete -f kubernetes-manifests/redis-master-deployment.yaml
kubectl delete -f kubernetes-manifests/redis-master-network-policy.yaml
kubectl delete -f kubernetes-manifests/pvc-redis-master.yaml
kubectl delete -f kubernetes-manifests/redis-config.yaml



#kubectl delete -f debugpod.yaml
