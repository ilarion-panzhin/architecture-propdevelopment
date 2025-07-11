# Развёртывание 4 pod'ов с nginx + метками + сервисами

kubectl run front-end-app --image=nginx --labels="role=front-end" --expose --port=80 --namespace=default
kubectl run back-end-api-app --image=nginx --labels="role=back-end-api" --expose --port=80 --namespace=default
kubectl run admin-front-end-app --image=nginx --labels="role=admin-front-end" --expose --port=80 --namespace=default
kubectl run admin-back-end-api-app --image=nginx --labels="role=admin-back-end-api" --expose --port=80 --namespace=default
