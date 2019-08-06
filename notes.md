To authenticate on the registry

gcloud auth configure-docker

To build image
docker build . -t eu.gcr.io/enhanced-mote-230116/redis:nonroot

To push image
docker push  eu.gcr.io/enhanced-mote-230116/redis:nonroot

create pvc 

kubectl apply -f pvc-redis-master.yaml 

create master deployment
kubectl apply -f redis-master-deployment.yaml

create master service 

kubectl apply -f redis-master-service.yaml

create slave stateful sets
kubectl apply -f redis-statefulset.yaml 


front end

docker build . -t eu.gcr.io/enhanced-mote-230116/gb-front:v1

kubectl apply -f guestbook-controller.json 
kubectl apply -f guestbook-service.json



kubectl exec -it my-pod  -- /bin/bash


To setup pod security policy
https://kubernetes.io/docs/concepts/policy/pod-security-policy/#example


https://banzaicloud.com/blog/pod-security-policy/