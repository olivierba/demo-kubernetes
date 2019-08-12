This is a comprehensive Kubernetes on GKE demo aiming a illustrating several key aspects:

- Deploying a cluster on GKE in a secure mode:
    -- using 2 PSP, a default very restrictive one and a less restrictive for PODs with higher privileges requests 
    -- Granting the necessary permission to the PSP to service accounts / namespaces with IAM
    -- Enabling Network policies
    -- Enabling secret encryption with KMS keys, by defaut secrets in ETCD are only base64 encoded which does nothing in terms of security. The data is alway encrypted at rest on disk though
    -- activated Workload identity so that workload can authenticate against GCP services with proper IAM account without mounting keys to the pods
- Performing a typical deployment on our secure cluser
    -- A redis master/slave cluser
    -- A small front end to post data to our cluster
    -- corresponding network policies to allow traffic between pods
- Organizing your code for automated deployment with Skaffold
    -- Build and deploy images on GCP with cloud build
    -- automate execution of yaml files
    -- This is even easier with VS code cloud code extention 


NOTE:
- As of today (08/12/2019) there's a bug with Workload Identity (Beta feature), it doesn't work when PSP are enabled on the cluster. As a result and until the fix is rolled out I've commented out this feature.
