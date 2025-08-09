#!/bin/bash

echo "=== SNS API 테스트 환경 정지 ==="

# 현재 디렉토리 확인
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml 파일을 찾을 수 없습니다."
    echo "support 디렉토리에서 실행해주세요."
    exit 1
fi

echo "🛑 Docker 컨테이너 정지 중..."

# 컨테이너들 정지 (데이터는 보존)
docker-compose stop

echo ""
echo "✅ 모든 컨테이너가 정지되었습니다."
echo ""
echo "📋 정지된 서비스:"
echo "   - sns-mysql"
echo "   - sns-redis" 
echo "   - sns-rabbitmq"
echo ""
echo "💾 데이터는 보존됩니다."
echo ""
echo "🔧 관리 명령어:"
echo "   - 다시 시작: ./start.sh"
echo "   - 완전 정리: ./clean.sh"
echo "   - 상태 확인: docker-compose ps"
