h2. A somewhat secure install of helm/tiller

h3. Prerequisites
- Ensure you have local helm client, and you have deployed your K8S cluster
- We assume that you deployed the restricted policy (and the unretricted one) and activated the podsecuritypolicy admission controller on the cluster

h3. Step by step install
- Generate the certificates for the CA authority to enable TLS (see bogus sample in this folder)
```
openssl req -key ca.key.pem -new -x509 \
    -days 7300 -sha256 \
    -out ca.cert.pem \
    -extensions v3_ca
openssl genrsa -out tiller.key.pem 4096
openssl req -new -sha256 \
    -key tiller.key.pem \
    -out tiller.csr.pem \
openssl x509 -req -days 365 \
    -CA ca.cert.pem \
    -CAkey ca.key.pem \
    -CAcreateserial \
    -in tiller.csr.pem \
    -out tiller.cert.pem
openssl req -new -sha256 \
    -key helm.key.pem \
    -out helm.csr.pem \
openssl x509 -req -days 365 \
    -CA ca.cert.pem \
    -CAkey ca.key.pem \
    -CAcreateserial \
    -in helm.csr.pem \
    -out helm.cert.pem

- run the helm.yaml file. This will create a separate namespace for tiller, create roles and binding to allow tiller to use the privileged psp, and deploy asset in the default namespace. To deploy in other namespace create the appropriate roles
- init helm and deploy tiller on your cluster with helmsetup.sh. This will also copy the necessary certificates in your helm home folder
- from now on use the following syntax to deploy charts in the default namespace

```
helm install stable/xxxx--tiller-namespace tiller --tls  

- Note that default install make tiller cluster admin and will make all local rbac role restrictions and policy useless. 