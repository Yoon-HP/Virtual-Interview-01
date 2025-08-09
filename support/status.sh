#!/bin/bash

echo "=== SNS API 테스트 환경 상태 확인 ==="

# 현재 디렉토리 확인
if [ ! -f "docker-compose-local.yml" ]; then
    echo "❌ docker-compose-local.yml 파일을 찾을 수 없습니다."
    echo "support 디렉토리에서 실행해주세요."
    exit 1
fi

echo ""
echo "🐳 Docker 컨테이너 상태:"
docker-compose ps

echo ""
echo "📊 데이터 확인:"

# MySQL 연결 및 데이터 확인
if docker exec sns-mysql mysql -u root -proot -e "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ MySQL 연결됨"
    POSTS_COUNT=$(docker exec sns-mysql mysql -u root -proot -D sns -e "SELECT COUNT(*) FROM posts;" -s -N 2>/dev/null || echo "0")
    echo "   - 포스트 개수: $POSTS_COUNT"
    
    if [ "$POSTS_COUNT" -gt 0 ]; then
        echo "   - 최신 포스트 3개:"
        docker exec sns-mysql mysql -u root -proot -D sns -e "SELECT id, author_id, LEFT(content, 30) as content, created_at FROM posts ORDER BY created_at DESC LIMIT 3;" 2>/dev/null || echo "     조회 실패"
    fi
else
    echo "❌ MySQL 연결 실패"
fi

# Redis 연결 및 캐시 확인
echo ""
if docker exec sns-redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis 연결됨"
    
    # 캐시 키 개수 확인
    CACHE_KEYS=$(docker exec sns-redis redis-cli KEYS "friend_feed:*" | wc -l)
    echo "   - 뉴스피드 캐시 키 개수: $CACHE_KEYS"
    
    if [ "$CACHE_KEYS" -gt 0 ]; then
        echo "   - 캐시된 뉴스피드:"
        for user_id in 1001 1002 1003; do
            COUNT=$(docker exec sns-redis redis-cli ZCARD "friend_feed:$user_id" 2>/dev/null || echo "0")
            if [ "$COUNT" -gt 0 ]; then
                echo "     사용자 $user_id: $COUNT 개 포스트"
            fi
        done
    fi
else
    echo "❌ Redis 연결 실패"
fi

# RabbitMQ 상태 확인
echo ""
if docker ps | grep -q sns-rabbitmq; then
    echo "✅ RabbitMQ 실행 중"
    echo "   - 관리 UI: http://localhost:15672 (guest/guest)"
else
    echo "❌ RabbitMQ 실행되지 않음"
fi

# 포트 사용 상태 확인
echo ""
echo "🌐 포트 사용 상태:"
for port in 3306 6379 5672 15672; do
    if lsof -i :$port > /dev/null 2>&1; then
        echo "   ✅ $port: 사용 중"
    else
        echo "   ❌ $port: 미사용"
    fi
done

# SNS API 서버 확인
echo ""
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/feeds 2>/dev/null | grep -q "200\|400"; then
    echo "✅ SNS API 서버 실행 중 (localhost:8080)"
else
    echo "❌ SNS API 서버 실행되지 않음"
    echo "   시작하려면: cd ../sns-api && ./gradlew bootRun"
fi

echo ""
echo "🔧 관리 명령어:"
echo "   ./start.sh   - 환경 시작"
echo "   ./stop.sh    - 환경 정지"
echo "   ./clean.sh   - 완전 정리"
echo "   ./test-api.sh - API 테스트"
