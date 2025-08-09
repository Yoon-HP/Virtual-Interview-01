#!/bin/bash

echo "=== SNS API 테스트 환경 정리 ==="

# 현재 디렉토리 확인
if [ ! -f "docker-compose-local.yml" ]; then
    echo "❌ docker-compose-local.yml 파일을 찾을 수 없습니다."
    echo "support 디렉토리에서 실행해주세요."
    exit 1
fi

echo "🧹 Docker 컨테이너 및 볼륨 정리 중..."

# 1. 실행 중인 컨테이너들 정지 및 제거
echo "📦 컨테이너 정지 및 제거..."
docker-compose down

# 2. 볼륨까지 완전 삭제 (모든 데이터 초기화)
echo "💾 데이터 볼륨 삭제..."
docker-compose down -v

# 3. 관련 이미지 정리 (선택사항 - 주석 해제 시 이미지도 삭제)
# echo "🖼️  관련 Docker 이미지 삭제..."
# docker-compose down --rmi all

# 4. 사용하지 않는 Docker 리소스 정리
echo "🗑️  사용하지 않는 Docker 리소스 정리..."
docker system prune -f

# 5. 특정 네트워크가 남아있다면 정리
NETWORK_NAME="virtual-interview-01_default"
if docker network ls | grep -q "$NETWORK_NAME"; then
    echo "🌐 네트워크 정리: $NETWORK_NAME"
    docker network rm "$NETWORK_NAME" 2>/dev/null || echo "네트워크 자동 정리됨"
fi

echo ""
echo "✅ 정리 완료!"
echo ""
echo "📋 정리된 항목:"
echo "   - 모든 SNS API 컨테이너 (sns-mysql, sns-redis, sns-rabbitmq)"
echo "   - 모든 데이터 볼륨 (MySQL, Redis, RabbitMQ 데이터)"
echo "   - 사용하지 않는 Docker 리소스"
echo ""
echo "🚀 새로 시작하려면: ./start.sh"
