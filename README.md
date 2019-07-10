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
export KUBECONFIG=$HOME/.kube/config-minikube-local

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
kubectl create --filename busybox/pod.yaml
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
kubectl scale --replicas=3 deployment web-app

# rollout
kubectl set image deployment web-app php=apetani/php-app:0.1
kubectl rollout status deployment web-app
kubectl rollout history deployment web-app

# rolling back
kubectl set image deployment web-app php=apetani/php-app:0.3
kubectl rollout status deployment web-app
kubectl rollout history deployment web-app
kubectl rollout undo deployment web-app
kubectl rollout undo deployment web-app --to-revision=4

# pause rollout
kubectl rollout pause deployment web-app
kubectl set image deployment web-app php=apetani/php-app:0.3
kubectl set image deployment web-app php=apetani/php-app:0.1
kubectl rollout history deployment web-app
kubectl rollout resume deployment web-app
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
docker build -t apetani/php-app -f php.Dockerfile .
docker push apetani/php-app:latest

docker build \
  -t apetani/nginx-app -f nginx.Dockerfile .
docker push apetani/nginx-app:latest

# kubernetes
kubectl rollout pause deployment/web-app
kubectl apply -f kube/namespace.yaml
kubectl apply -f kube/secret.yaml
kubectl apply -f kube/configmap.yaml
kubectl apply -f kube/deployment.yaml
kubectl apply -f kube/service.yaml
kubectl apply -f kube/ingress.yaml
kubectl patch -n workshop deployment.apps/web-app -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"date\":\"`date +'%s'`\"}}}}}"
kubectl rollout resume deployment/web-app

# docker
# dev
source docker/config/.dev.env
docker-compose -f docker/docker-compose.local.yml -p ${PROJ}_${ENV} up

# stage
source docker/config/.stage.env
docker-compose -f docker/docker-compose.local.yml -p ${PROJ}_${ENV} up

# prod
source docker/config/.prod.env
docker-compose -f docker/docker-compose.prod.yml -p ${PROJ}_${ENV} up --build
```

## HorizontalPodAutoscaler

For HPA to work:

* Need to have in the cluster `heapster` or `metrics-server`
* Resource limits in deployments (cpu, memory)
* Every 15 secs checks the utilisation. Cooling period is the time between consecutive scale (scale up 3 min, scale down 5 min)

```sh
kubectl top pods
kubectl top nodes

minikube addons list
minikube addons enable metrics-server

kubectl create namespace workshop
kubectl run nginx --image nginx --port 80
kubectl expose deploy nginx --type NodePort
minikube ip
curl -I http://192.168.99.101:30975

watch kubectl get all
kubectl autoscale deploy nginx --min 1 --max 5 --cpu-percent 20
kubectl describe hpa nginx
siege -q -c 5 -t 2m http://192.168.99.101:30975
```

Resource limits:

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "100m"
```

## StatefulSets

* Unique name (se il nome del statefulset e web e ho 5 repliche, i pod sarano web-1, web-2, e cosi via)
* Unique network identity
* Unique stable storage (se parlo di statefulset i dati devono essere persistenti, in questo caso il pod sa con quale persistent volume è stato associato, e nel caso in cui lo cancello utilizzare lo stesso volume di prima)
* Ordered provisioning (il provisioning dei pod non viene fatto in parallelo ma uno ala volta, se cancello un statefulset, kubernetes inizzia la cancellazione dall’ultimo pod che ha creato. Lo stesso vale anche per i rolling update, uno alla volta iniziando dall’ultimo creato)

A statefulset needs an headless service to maintain a unique network identity for each pod:

* service: clusterIP: None
* statefulset: volumeClaimTemplates

## Services

ClusterIP

* is the default Kubernetes service
* a service inside the cluster that other apps inside your cluster can access
* there is no external access

```yaml
apiVersion: v1
kind: Service
metadata:  
  name: my-internal-service
spec:
  selector:
    app: my-app
  type: ClusterIP
  ports:  
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
```

NodePort opens a specific port on all the Nodes (the VMs), and any traffic that is sent to this port is forwarded to the service.

* targetPort (pod)
* nodePort (node, range 30000-32767)
* port (svc)

```yaml
apiVersion: v1
kind: Service
metadata:  
  name: my-nodeport-service
spec:
  selector:
    app: my-app
  type: NodePort
  ports:  
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30036
    protocol: TCP
```

LoadBalancer

* is the standard way to expose a service to the internet
* on GKE, this will spin up a Network Load Balancer that will give you a single IP address
* if you want to directly expose a service, this is the default method.

Ingress

* Ingress is actually NOT a type of service
* sits in front of multiple services and act as a “smart router” into your cluster
* the default GKE ingress controller will spin up a HTTP(S) Load Balancer

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: my-ingress
spec:
  backend:
    serviceName: other
    servicePort: 8080
  rules:
  - host: foo.mydomain.com
    http:
      paths:
      - backend:
          serviceName: foo
          servicePort: 8080
```
