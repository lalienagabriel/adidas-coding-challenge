FROM openjdk:8-jdk-alpine
COPY target/hello-world-0.0.1.jar hello-world-0.0.1.jar
ENTRYPOINT ["java","-jar","/hello-world-0.0.1.jar"]
