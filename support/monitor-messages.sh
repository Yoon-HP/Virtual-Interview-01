#!/bin/bash

echo "=== RabbitMQ 메시지 실시간 모니터링 ==="
echo "포스트 생성/삭제 시 발행되는 메시지를 실시간으로 확인합니다."
echo "Ctrl+C로 종료하세요."
echo ""

RABBITMQ_HOST="localhost:15672"
RABBITMQ_USER="guest"
RABBITMQ_PASS="guest"

# 이전 통계 저장
get_message_stats() {
    curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/overview | \
    jq -r '.message_stats.publish // 0' 2>/dev/null || echo "0"
}

echo "📊 초기 상태 확인 중..."
PREV_PUBLISH=$(get_message_stats)
echo "현재까지 발행된 메시지: $PREV_PUBLISH 개"
echo ""
echo "🔄 실시간 모니터링 시작..."
echo "─────────────────────────────────────"

# 실시간 모니터링 루프
while true; do
    sleep 2
    
    CURRENT_PUBLISH=$(get_message_stats)
    
    if [ "$CURRENT_PUBLISH" != "$PREV_PUBLISH" ]; then
        DIFF=$((CURRENT_PUBLISH - PREV_PUBLISH))
        TIMESTAMP=$(date '+%H:%M:%S')
        
        echo "[$TIMESTAMP] 🚀 새 메시지 감지! (+$DIFF개) 총: $CURRENT_PUBLISH"
        
        # Exchange별 통계도 확인
        EXCHANGE_STATS=$(curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/exchanges | \
        jq -r '.[] | select(.name == "feed.events") | "Exchange: \(.name), 발행: \(.message_stats.publish_out // 0)"' 2>/dev/null)
        
        if [ -n "$EXCHANGE_STATS" ]; then
            echo "    $EXCHANGE_STATS"
        fi
        
        # Queue에 메시지가 쌓여있는지 확인
        QUEUE_MSGS=$(curl -s -u $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST/api/queues | \
        jq -r '.[] | select(.messages > 0) | "Queue: \(.name) (\(.messages)개)"' 2>/dev/null)
        
        if [ -n "$QUEUE_MSGS" ]; then
            echo "    📬 대기 중인 메시지:"
            echo "$QUEUE_MSGS" | sed 's/^/       /'
        fi
        
        echo "─────────────────────────────────────"
        
        PREV_PUBLISH=$CURRENT_PUBLISH
    fi
done
