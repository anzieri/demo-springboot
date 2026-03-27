# Use the small Alpine-based JRE
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Create the user using Alpine syntax
RUN adduser -D amara
USER amara

# This is the key: Grab the JAR from the local 'target' folder
# created by the 'mvn package' step in your GitHub Action
COPY target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]