# Kubernetes workshop

## Intro

### minikube

```sh
minikube start
kubectl cluster-info
kubectl get nodes
kubectl get po --all-namespaces
minikube dashboard
minikube stop
```

### kubectl

```sh
kubectl create namespace workshop
kubectl config set-context $(kubectl config current-context) --namespace=workshop
kubectl config view | grep namespace:

kubectl get pods -o wide --all-namespaces
kubectl run fedora --generator=run-pod/v1 --image=fedora
kubectl run fedora --generator=run-pod/v1 --image=fedora -- /usr/bin/sleep 3000
```

### YAML

```sh
kubectl create --filename busybox/pod.yaml
kubectl get pods -o wide
kubectl describe pods busybox

kubectl delete --filename busybox/pod.yaml
```

## Kubernetes Components

Kubernetes Resource Types:

* the _Pod_ is the smallest managed item for Kubernetes
* a _ReplicaSet_ ensures that a specified number of pod replicas are running at any given time (scalability)
* replica sets are part of a bigger entity, the _Deployment_
* to make services accessible we have the _Service_
* _Ingress_ is another way of making deployments accessible (similar to service)
* a _Namespace_ ensures strict isolation between resources (is implemented at linux kernel level)

Pods:

* A pod is a group of one or more containers, shared storage, networking and a specification on how to run these containers.
* All containers in a pod are always co-locted and co-scheduled
* You can se a pod as an application or logical host
* Pods are considered to be ephemeral
* If the node running the a pod crashes, the pod will be scheduled to go somewhere else
* Applications in the pod all use the same network namespace
  * one ip address for the pod
  * one range of ports for all containers
  * the hostname is the pods name

```bash
kubectl create --filename busybox-pod.yaml
kubectl describe pod busybox
kubectl delete pod busybox
```

Namespaces:

* A namespace is strict isolation that occurs on linux kernel level
* Namespaces can be added when creating a pod ensuring that a pod is available in a specific namespace only
* Before adding a pod to a namespace ensure that the namespace exists

```bash
kubectl create --filename namespace.yaml
kubectl delete --filename namespace.yaml
```

Replica Sets:

* replica sets can be created directly but you should not, use deployments instead
* applications that are launched through a deployment automatically create replica sets
* the purpose of replica sets is to scale pods up and down

```bash
kubectl run --image=nginx nginx-app
```

Deployments:

* deploymets are used to create and automate replica sets
* deploymet instruct the cluster how to create and scale applications
* deploymet controller will monitor instances of an application ensuring availability

```bash
kubectl create -f nginx/deployment.yaml

# scale
kubectl scale --replicas=3 deployment/nginx-app

# rollout
kubectl set image deployment/nginx-app nginx-app=nginx:1.9.0
kubectl rollout status deployment/nginx-app
kubectl rollout history deployment/nginx-app

# rolling back
kubectl set image deployment/nginx-app nginx-app=nginx:1.91
kubectl rollout status deployment/nginx-app
kubectl rollout history deployment/nginx-app
kubectl rollout undo deployment/nginx-app
kubectl rollout undo deployment/nginx-app --to-revision=2

# pause rollout
kubectl rollout pause deployment/nginx-app
kubectl set image deployment/nginx-app nginx-app=nginx:1.9.0
kubectl rollout history deployment/nginx-app
kubectl rollout resume deployment/nginx-app
```

```bash
kubectl run --help | less

kubectl run hazelcast --image=hazelcast --port=5701
kubectl get deployments # will have AVAILABLE=0
kubectl get rs # will have READY=0
kubectl get pods # will have READY=0/1

kubectl describe deployment hazelcast
kubectl describe pod <pod_name> # check Events for info
kubectl logs <pod_name> # logs will tell that cannot pull image
```

### Using Labels

A label is a string used to filter objects (to group object together).

_nodeSelector_ can be used to identify nodes where a Pod is allowed to run. If specified in a Pod definition, the pod will run only on nodes with that label.

```bash
# add label to node
kubectl label node <node_name> disktype=hdd
kubectl get nodes --show-labels

# add label to pod if not specified in yaml
kubectl label pod <pod_name> disktype=hdd
kubectl get pods --show-labels

kubectl get pods -l run -o yaml | less
kubectl get pods -l run=nginx-app -o yaml | less

# if I remove the run label from a pod a new one will be created since kubernetes cannot identify this pod as "running"
kubectl label pod <pod_name> run-
```

### Using Ingress

* Ingress can be used to give services externally reachable URLs
* An Ingress controller is required for offering Ingress services
* Any service that can be used as a reverse proxy can be used as an Ingress controller (Nginx)

Enable Ingress on minikube:

```bash
minikube addons list
minikube addons enable ingress

# verify ingress controller was created
kubectl get pods -n kube-system
```

## PHP-FPM

```sh
source .kube.env
docker build -t apetani/php-app -f php.Dockerfile .
docker push apetani/php-app

docker build \
  --build-arg ENV=${ENV} \
  -t apetani/nginx-app -f nginx.Dockerfile .
docker push apetani/nginx-app

# kubernetes
kubectl apply -f kube/deployment.yaml
kubectl apply -f kube/service.yaml
kubectl apply -f kube/ingress.yaml
kubectl patch -n workshop deployment.apps/web-app -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"date\":\"`date +'%s'`\"}}}}}"

# docker
source .dev.env
docker-compose -f docker-compose.${ENV}.yml up

source .prod.env
docker-compose -f docker-compose.${ENV}.yml up

docker-compose build --build-arg username="my-user" --build-arg password="my-pass"
```