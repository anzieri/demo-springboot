# Stage 1: Build the application using full Maven/JDK image
FROM maven:3.9.9-eclipse-temurin-21-alpine AS build
WORKDIR /app
# Copy only the pom.xml first to cache dependencies (speeds up builds)
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src .
RUN mvn clean package -DskipTests

# Stage 2: Create a minimal runtime image
# Use a minimal JRE or a custom jlink image as the base
FROM eclipse-temurin:21-jre-alpine
# or an even smaller image like cgr.dev/chainguard/jre or BellSoft Alpaquita
WORKDIR /app

# Create a non-root user for security
RUN useradd -m amara
USER amara

# Copy the built JAR file from the 'build' stage
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
