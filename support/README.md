# Support Tools

SNS API 개발 및 테스트를 위한 지원 도구들입니다.

## 📁 파일 구성

### 설정 파일
- `docker-compose-local.yml`: MySQL, Redis, RabbitMQ 인프라 설정

### 관리 스크립트
- `start.sh`: 테스트 환경 시작 (자동 데이터 삽입, 상태 확인 포함)
- `stop.sh`: 테스트 환경 정지 (데이터 보존)
- `clean.sh`: 테스트 환경 완전 정리 (모든 데이터 삭제)
- `status.sh`: 현재 환경 상태 확인

### 데이터 및 테스트
- `setup-redis-cache.sh`: Redis 뉴스피드 캐시 데이터 설정 (MySQL과 자동 동기화)
- `test-api.sh`: API 통합 테스트 스크립트 (친구 피드/내 피드 구분, 사용자 1001 기준, jq 지원)

### 모니터링
- `check-rabbitmq.sh`: RabbitMQ 상태 및 메시지 확인
- `monitor-messages.sh`: RabbitMQ 메시지 실시간 모니터링

## 🚀 사용법

### 빠른 시작 (권장)
```bash
cd support

# 1. 테스트 환경 시작 (자동 데이터 삽입, 상태 확인)
./start.sh

# 2. 애플리케이션 시작 (별도 터미널)
cd ../sns-api
./gradlew bootRun --args='--spring.profiles.active=local'

# 3. Redis 캐시 데이터 설정
cd ../support
./setup-redis-cache.sh

# 4. API 통합 테스트 실행 (친구 피드 + 내 피드)
./test-api.sh

# 5. RabbitMQ 메시지 확인 (선택적)
./check-rabbitmq.sh
```

### 개별 관리 명령어
```bash
cd support

# 환경 상태 확인
./status.sh

# 환경 정지 (데이터 보존)
./stop.sh

# 환경 완전 정리 (모든 데이터 삭제)
./clean.sh

# 환경 재시작
./start.sh

# RabbitMQ 상태 확인
./check-rabbitmq.sh

# 실시간 메시지 모니터링 
./monitor-messages.sh
```

## 📊 테스트 데이터

### MySQL 자동 초기 데이터
- **자동 생성**: `start.sh` 실행 시 테이블과 테스트 데이터 자동 생성
- **5개 테스트 포스트**: 사용자 1001, 1002, 1003의 다양한 포스트
- **스마트 처리**: 기존 데이터가 있으면 건너뛰고, 없으면 자동 삽입
- **한국 시간대**: Asia/Seoul 설정 적용
- **JPA Auditing**: 생성/수정 시간 자동 관리

### Redis 뉴스피드 캐시
- `friend_feed:1001`: 사용자 1001의 뉴스피드 (MySQL과 자동 동기화)
- `setup-redis-cache.sh`로 실제 존재하는 포스트 ID와 자동 매칭
- Sorted Set 구조로 최신순 정렬 지원

## 🔧 고급 관리 명령어

### 직접 접속
```bash
# MySQL 직접 접속
docker exec -it sns-mysql mysql -u root -proot sns

# Redis 직접 접속  
docker exec -it sns-redis redis-cli

# 컨테이너 로그 확인
docker-compose logs [mysql|redis|rabbitmq]
```

### 웹 UI
- **RabbitMQ 관리**: http://localhost:15672 (guest/guest)

### 수동 Docker 명령어
```bash
# 상태 확인
docker-compose ps

# 수동 시작/정지
docker-compose up -d
docker-compose stop
docker-compose down

# 볼륨까지 완전 삭제
docker-compose down -v
```

## 📝 참고사항

### 핵심 특징
- **완전 자동화**: `start.sh` 한 번으로 테이블 생성 + 데이터 삽입 완료
- **API 구분**: 친구 피드(`/api/feeds/friends`)와 내 피드(`/api/feeds/my`) 분리
- **JPA 쿼리 로깅**: SQL 쿼리와 파라미터 실시간 출력 (validation 모드)
- **한국 시간대**: 모든 서비스가 Asia/Seoul 설정

### 요구사항
- jq 필요 (자동 설치: `brew install jq`)
- Docker & Docker Compose
- Java 17+ (Spring Boot 3.x)

### 포트 사용
- **MySQL**: 3306
- **Redis**: 6379  
- **RabbitMQ**: 5672 (AMQP), 15672 (관리 UI)
- **SNS-API**: 8080

## 🐛 문제 해결

### 포트 충돌
```bash
# 사용 중인 포트 확인
lsof -i :3306 -i :6379 -i :5672

# 기존 컨테이너 완전 정리
./clean.sh
```

### 캐시 동기화 문제
```bash
# Redis 캐시 재설정
./setup-redis-cache.sh

# MySQL-Redis 상태 확인
./status.sh
```

### API 연결 실패
```bash
# SNS API 서버 상태 확인
curl -s -H "X-User-Id: 1001" http://localhost:8080/api/feeds/friends

# 서버 재시작 (sns-api 디렉토리에서)
./gradlew bootRun --args='--spring.profiles.active=local'
```

### 데이터 자동 삽입 문제
```bash
# 환경 완전 재시작으로 자동 삽입 재실행
./clean.sh
./start.sh

# 수동 데이터 확인
docker exec sns-mysql mysql -u root -proot sns -e "SELECT COUNT(*) FROM posts;"
```
