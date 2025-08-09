#!/bin/bash

echo "=== SNS API 테스트 환경 시작 ==="

# 현재 디렉토리 확인
if [ ! -f "docker-compose-local.yml" ]; then
    echo "❌ docker-compose-local.yml 파일을 찾을 수 없습니다."
    echo "support 디렉토리에서 실행해주세요."
    exit 1
fi

# 1. Docker 컨테이너들 시작
echo "🐳 Docker 컨테이너 시작 중..."
docker-compose up -d

# 2. 컨테이너들이 완전히 시작될 때까지 대기
echo "⏳ 서비스 시작 대기 중..."
echo "   - MySQL 초기화 대기..."
sleep 15

# MySQL이 완전히 시작되었는지 확인
MAX_RETRIES=12
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker exec sns-mysql mysql -u root -proot -e "SELECT 1;" > /dev/null 2>&1; then
        echo "✅ MySQL 준비 완료!"
        break
    fi
    echo "   MySQL 시작 대기 중... ($((RETRY_COUNT + 1))/$MAX_RETRIES)"
    sleep 5
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ MySQL 시작 실패!"
    exit 1
fi

# Redis 연결 확인
echo "   - Redis 연결 확인..."
if docker exec sns-redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis 준비 완료!"
else
    echo "❌ Redis 연결 실패!"
    exit 1
fi

# RabbitMQ 연결 확인 (간단히 컨테이너 상태만 확인)
if docker ps | grep -q sns-rabbitmq; then
    echo "✅ RabbitMQ 준비 완료!"
else
    echo "❌ RabbitMQ 시작 실패!"
    exit 1
fi

# 3. 초기 데이터 확인 및 자동 삽입
echo ""
echo "📊 초기 데이터 확인 및 설정..."

# posts 테이블 존재 여부 확인
TABLE_EXISTS=$(docker exec sns-mysql mysql -u root -proot -D sns -e "SHOW TABLES LIKE 'posts';" -s -N 2>/dev/null)

if [ -z "$TABLE_EXISTS" ]; then
    echo "   - posts 테이블이 없습니다. 테이블과 데이터를 생성합니다..."
    if docker exec -i sns-mysql mysql -u root -proot sns < init-data.sql > /dev/null 2>&1; then
        echo "   ✅ 테이블 및 초기 데이터 생성 완료!"
    else
        echo "   ❌ 초기 데이터 생성 실패!"
        exit 1
    fi
else
    # 테이블은 있지만 데이터가 없는 경우
    POSTS_COUNT=$(docker exec sns-mysql mysql -u root -proot -D sns -e "SELECT COUNT(*) FROM posts;" -s -N 2>/dev/null || echo "0")
    
    if [ "$POSTS_COUNT" = "0" ]; then
        echo "   - posts 테이블은 있지만 데이터가 없습니다. 테스트 데이터를 삽입합니다..."
        # 테이블 생성 부분을 제외하고 INSERT만 실행
        docker exec sns-mysql mysql -u root -proot -D sns -e "
        INSERT IGNORE INTO posts (author_id, content, created_at, updated_at) VALUES
        (1001, '안녕하세요! 첫 번째 테스트 포스트입니다. 🚀', NOW(), NOW()),
        (1002, 'SNS API 테스트 중입니다!', NOW(), NOW()),
        (1001, '두 번째 포스트도 잘 작동하나요?', NOW(), NOW()),
        (1003, '여러 사용자의 포스트를 테스트해봅시다.', NOW(), NOW()),
        (1002, '팔로우 기능도 곧 테스트할 예정입니다! 💪', NOW(), NOW());
        " > /dev/null 2>&1
        echo "   ✅ 테스트 데이터 삽입 완료!"
    else
        echo "   - 기존 데이터가 있습니다. 추가 삽입을 건너뜁니다."
    fi
fi

# 최종 데이터 개수 확인
FINAL_COUNT=$(docker exec sns-mysql mysql -u root -proot -D sns -e "SELECT COUNT(*) FROM posts;" -s -N 2>/dev/null || echo "0")
echo "   - 현재 테스트 포스트: $FINAL_COUNT 개"

# 4. 서비스 상태 요약
echo ""
echo "🎉 테스트 환경 시작 완료!"
echo ""
echo "📋 실행 중인 서비스:"
echo "   🐬 MySQL    : localhost:3306 (root/root, DB: sns)"
echo "   🧰 Redis    : localhost:6379"
echo "   🐰 RabbitMQ : localhost:5672 (관리 UI: http://localhost:15672)"
echo ""
echo "📝 다음 단계:"
echo "   1. SNS API 서버 시작: cd ../sns-api && ./gradlew bootRun"
echo "   2. Redis 캐시 설정: ./setup-redis-cache.sh"
echo "   3. API 테스트 실행: ./test-api.sh"
echo ""
echo "🔧 관리 명령어:"
echo "   - 상태 확인: docker-compose ps"
echo "   - 로그 확인: docker-compose logs [서비스명]"
echo "   - 정리하기: ./clean.sh"
