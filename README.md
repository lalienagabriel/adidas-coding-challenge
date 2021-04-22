# adidas-coding-challenge

## Implementation of a simple REST application with a hello world endpoint:

To create the rest app we´re using spring.io which allows us to generate a project with java and maven.
We need to fill up the form , e.g.:
```maven
Project: Maven Project
Language: Java
Spring Boot: 2.4.5
Group: com.lalienagabriel.example
Artifact: hello-world
Name: hello-world
Description: adidas-coding-challenge
Package name: com.lalienagabriel.example.hello-world
Packaging: Jar
Java: 8
```
When the download has finish, we should extract it on our working directory, in this case: ```hello-world```
We´ll create the controller file ```HelloController.java```:
```java
package com.lalienagabriel.example.helloworld;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

@RestController
public class HelloController {

        @RequestMapping("/")
        public String index() {
                return "Hello World";
        }

}
```
Later we´ll build the jar file to test it in our server:
```bash
chmod 755 mvnw #set read and execution to current group and all users plus write to the current user
./mvnw clean package #building the jar file with maven
```
## Implementation of a pipeline, where every commit of each developer goes through phases (steps) finishing on a production environment:

We need to setup the docker file to create the container with the jar file, but before doing it, we´re going to create the dockerfile to setup the container
```dockerfile
FROM openjdk:8-jdk-alpine #base container
COPY target/hello-world-0.0.1-SNAPSHOT.jar hello-world.jar #jar file to add to the container with the new name
ENTRYPOINT ["java","-jar","/hello-world.jar"] #execution line for the container
```
To test the container we´re going to build it
```bash
docker build --tag=hello-world:latest . #build the container with all the files in the current directory
docker run -p8080:8080 hello-world:latest #run the container mapping the port 8080 of our server to the port 8080 in the container
```
To check that our container is working fine, we should access to the webpage:
```bash
curl http://localhost:8080
```
If we´ve answer like Hello World, it´s working fine
Then we´ll register in hub.docker.com to create the container and the setup the automatization
```bash
docker tag hello-world:latest lalienagabriel/hello-world:latest #tag the container to upload in docker hub
docker login #login in our docker hub account
docker push lalienagabriel/hello-world:latest #push the container to docker hub
```
Now, to setup the github actions in order to create docker container when we push a new version in git.
To do it, we´ll need to create a new access token on docker hub and set it up on github secrets. 
When it´s done, we´ll create the yaml files to use it in github actions
```yaml
name: docker-hub
on: [push]
jobs:
  push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-java@v2
        with:
          java-version: "8"
          distribution: adopt
      - name: Build jar
        run: mvn package
      - name: Build image
        run: docker build --file dockerfile --tag lalienagabriel/hello-world .
      - name: Push to Docker Hub
        uses: docker/build-push-action@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
          repository: lalienagabriel/hello-world
          tag_with_ref: true
```
Then we use git push to test and check the docker hub container is created

## Implementation of a Kubernetes deployment. The implementation needs to take care of the application deployment and expose it to internet:

To implement this point, we´re going to use minikube to create a local kubernetes cluster.
We´ll need to create the pod and service yaml to deploy it, for doing it, we create a new directory called ```kubernetes```
Deployment:
```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: hello-world
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      name: hello-world
      labels:
        app: hello-world
    spec:
      containers:
        - name: hello-world
          image: lalienagabriel/hello-world:main
          ports:
          - containerPort: 8080
          imagePullPolicy: Always
```
Service:
```yaml
kind: Service
apiVersion: v1
metadata:
  name: hello-world
spec:
  selector:
    app: hello-world
  type: LoadBalancer
  ports:
    - name: execution-port
      port: 8080
      targetPort: 8080
```
We´ve used LoadBalancer type in order to expose it to the host network
To deploy it:
```bash
minikube -- kubectl apply -f kubernetes/
```
To check that it´s working we´ll need to use kubectl tunnel to make the pod externally accesible:
```bash
minikube tunnel
```
To get test it we should know the complete name of the service, the external exposed ip and curl it:
```bash
minikube kubectl -- get services #check complete service name and external ip
hello-world   LoadBalancer   10.98.217.119   <pending>     8080:30043/TCP   11h
curl 10.98.217.119:8080
```

## Please provide answers to the following questions

- How will you ensure the application is deployed properly?

We can check the pod status of the pod and the service:
```bash
minikube kubectl -- get pods #check pods status
minikube kubectl -- get rc,services #check services
```

- How can you check the application logs once deployed?

```bash
minikube kubectl -- logs hello-world-78f684cbb9-cqzh6
```

- Can you be alerted when application is not ready?

To monitor kubernetes we can use influxdb and grafana to check the CPU, Memory, pods and services
To do it we´ll need to setup a heapster pod which contains both of them and has the dashboards already created:
```bash
wget https://raw.githubusercontent.com/kubernetes/heapster/release-1.5/deploy/kube-config/influxdb/influxdb.yaml
wget https://raw.githubusercontent.com/kubernetes/heapster/release-1.5/deploy/kube-config/influxdb/grafana.yaml
kubectl create -f influxdb.yaml
kubectl create -f grafana.yaml
kubectl get pods --namespace=kube-system #Check the pods Heapster, Grafana and InfluxDB are running
```
After it you should config the influxdb and grafana to connect to the server in order to collect metrics from kubernetes
To see grafana we´ll need to use kubernetes proxy to expose it outside of the server:
```bash
minikube kubectl proxy
```
