# Build stage
FROM maven:3.9.5-eclipse-temurin-17 AS build
WORKDIR /app

# Copy and install common-lib first
COPY lib/common-lib-1.0.7.jar /tmp/common-lib-1.0.7.jar
RUN mvn install:install-file \
    -Dfile=/tmp/common-lib-1.0.7.jar \
    -DgroupId=io.github.haphong463 \
    -DartifactId=common-lib \
    -Dversion=1.0.7 \
    -Dpackaging=jar

COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Create a non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Copy the jar file
COPY --from=build /app/target/product-service.jar app.jar

# Change ownership of the app
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8084/actuator/health || exit 1

EXPOSE 8084

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]