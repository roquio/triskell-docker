FROM eclipse-temurin:21-jdk-alpine

COPY api.jar /api.jar

EXPOSE 8080

CMD ["java", "-Dspring.profiles.active=demo", "-jar", "/api.jar"]
