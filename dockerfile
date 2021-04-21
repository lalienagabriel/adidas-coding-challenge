FROM openjdk:8-jdk-alpine
COPY target/hello-world-0.0.1-SNAPSHOT.jar hello-world.jar
ENTRYPOINT ["java","-jar","/hello-world.jar"]
