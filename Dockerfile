FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# 보안: root 대신 별도 유저로 실행
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# CI에서 빌드된 JAR 복사 (GitHub Actions에서 build/libs/*.jar → app.jar)
COPY build/libs/*.jar app.jar

# 헬스체크 (ECS + ALB가 이걸로 판단)
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]