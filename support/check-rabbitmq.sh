#!/bin/bash

echo "=== RabbitMQ 메시지 및 상태 확인 ==="

# RabbitMQ Management API를 사용하여 정보 조회
RABBITMQ_HOST="localhost:15672"
RABBITMQ_USER="guest"
RABBITMQ_PASS="guest"

# 1. RabbitMQ 연결 확인
echo "🐰 RabbitMQ 연결 상태 확인..."
if curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/overview > /dev/null 2>&1; then
    echo "✅ RabbitMQ Management API 연결됨"
else
    echo "❌ RabbitMQ Management API 연결 실패"
    echo "   URL: http://$RABBITMQ_HOST"
    echo "   계정: $RABBITMQ_USER/$RABBITMQ_PASS"
    exit 1
fi

echo ""

# 2. Exchange 정보 확인
echo "📡 Exchange 정보:"
EXCHANGES=$(curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/exchanges | jq -r '.[] | select(.name != "") | "\(.name) (\(.type))"' 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "$EXCHANGES"
else
    echo "Exchange 정보 조회 실패 (jq 필요)"
    curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/exchanges | grep -o '"name":"[^"]*"' | head -10
fi

echo ""

# 3. Queue 정보 확인
echo "📬 Queue 정보:"
QUEUES=$(curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/queues | jq -r '.[] | "\(.name): \(.messages) 메시지"' 2>/dev/null)
if [ $? -eq 0 ]; then
    if [ -z "$QUEUES" ]; then
        echo "생성된 Queue가 없습니다."
    else
        echo "$QUEUES"
    fi
else
    echo "Queue 정보 조회 실패"
fi

echo ""

# 4. Connection 정보 확인
echo "🔗 Connection 정보:"
CONNECTIONS=$(curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/connections | jq -r '.[] | "\(.name): \(.state)"' 2>/dev/null)
if [ $? -eq 0 ]; then
    if [ -z "$CONNECTIONS" ]; then
        echo "활성 Connection이 없습니다."
    else
        echo "$CONNECTIONS"
    fi
else
    echo "Connection 정보 조회 실패"
fi

echo ""

# 5. Channel 정보 확인
echo "📺 Channel 정보:"
CHANNELS=$(curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/channels | jq -r '.[] | "\(.name): \(.state)"' 2>/dev/null)
if [ $? -eq 0 ]; then
    if [ -z "$CHANNELS" ]; then
        echo "활성 Channel이 없습니다."
    else
        echo "$CHANNELS"
    fi
else
    echo "Channel 정보 조회 실패"
fi

echo ""

# 6. 최근 메시지 통계 (선택적)
echo "📊 메시지 통계:"
STATS=$(curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/overview | jq -r '.message_stats // {}' 2>/dev/null)
if [ $? -eq 0 ] && [ "$STATS" != "{}" ]; then
    PUBLISH_COUNT=$(echo $STATS | jq -r '.publish // 0')
    DELIVER_COUNT=$(echo $STATS | jq -r '.deliver_get // 0')
    echo "   - 발행된 메시지: $PUBLISH_COUNT"
    echo "   - 전달된 메시지: $DELIVER_COUNT"
else
    echo "메시지 통계가 없거나 조회 실패"
fi

echo ""

# 7. 특정 Queue의 메시지 확인 (있다면)
echo "💌 Queue 메시지 미리보기:"
QUEUE_LIST=$(curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/queues | jq -r '.[].name' 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$QUEUE_LIST" ]; then
    for queue in $QUEUE_LIST; do
        MESSAGE_COUNT=$(curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/queues/%2F/$queue | jq -r '.messages' 2>/dev/null)
        if [ "$MESSAGE_COUNT" -gt 0 ]; then
            echo "Queue '$queue'에 $MESSAGE_COUNT 개의 메시지가 있습니다."
            
            # 메시지 미리보기 (소비하지 않고 확인)
            PREVIEW=$(curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS \
                -X POST http://$RABBITMQ_HOST/api/queues/%2F/$queue/get \
                -H "Content-Type: application/json" \
                -d '{"count":3,"ackmode":"ack_requeue_false","encoding":"auto"}' 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                echo "최근 메시지 미리보기:"
                echo $PREVIEW | jq -r '.[] | "  - \(.payload)"' 2>/dev/null || echo "  메시지 파싱 실패"
            fi
        fi
    done
else
    echo "Queue가 없거나 조회 실패"
fi

echo ""
echo "🔧 RabbitMQ 관리 명령어:"
echo "   웹 UI: http://localhost:15672 (guest/guest)"
echo "   Docker 로그: docker logs sns-rabbitmq"
echo "   컨테이너 접속: docker exec -it sns-rabbitmq bash"

echo ""
echo "=== RabbitMQ 확인 완료! ==="
