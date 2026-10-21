# Built by Cloud Build when deploying with `gcloud run deploy --source server`.
FROM eclipse-temurin:21-jdk AS build
WORKDIR /src
COPY gradlew settings.gradle build.gradle gradle.properties ./
COPY gradle gradle
COPY src src
RUN ./gradlew --no-daemon -q quarkusBuild -x test

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /src/build/quarkus-app/ ./
USER 1001
CMD ["java", "-XX:MaxRAMPercentage=75", "-jar", "quarkus-run.jar"]
