# ============================================
# Stage 1: Build
# ============================================
FROM gradle:8.5-jdk21 AS build

WORKDIR /app

# 의존성 캐싱을 위해 gradle 파일만 먼저 복사
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# 의존성 다운로드 (소스 변경 시 캐시 재사용)
RUN gradle dependencies --no-daemon || true

# 소스 복사 후 빌드
COPY src ./src
RUN gradle bootJar --no-daemon -x test

# ============================================
# Stage 2: Run
# ============================================
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# 보안: root 대신 별도 유저로 실행
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# 빌드 결과물만 복사 (이미지 크기 최소화)
COPY --from=build /app/build/libs/app.jar app.jar

# 헬스체크 (ECS + ALB가 이걸로 판단)
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]