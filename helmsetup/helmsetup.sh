kubectl apply -f helm.yaml

helm init \
    --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' \
    --tiller-tls \
    --tiller-tls-cert tiller.cert.pem \
    --tiller-tls-key tiller.key.pem \
    --tiller-tls-verify \
    --tls-ca-cert ca.cert.pem \
    --service-account tiller-sa \
    --tiller-namespace tiller

helm repo update

cp ca.cert.pem $(helm home)/ca.pem
cp helm.cert.pem $(helm home)/cert.pem
cp helm.key.pem $(helm home)/key.pem


#to test
#helm install stable/joomla --tiller-namespace tiller --tls

#to delete and purge everyting
#helm ls --all --short | xargs -L1 helm delete --purge --tiller-namespace tiller --tls