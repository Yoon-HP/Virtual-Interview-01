#!/bin/bash

echo "=== Redis 캐시 데이터 설정 ==="

# Redis에 연결하여 뉴스피드 캐시 데이터 설정
# friend_feed:{userId} 형태로 Sorted Set 생성 (점수는 타임스탬프)

echo "Redis에 뉴스피드 캐시 데이터를 설정합니다..."

# MySQL에서 현재 존재하는 포스트 ID들을 가져오기
echo "MySQL에서 포스트 ID 목록 조회..."
POST_IDS=$(docker exec sns-mysql mysql -u root -proot -D sns -e "SELECT id FROM posts ORDER BY id;" -s -N 2>/dev/null)

if [ -z "$POST_IDS" ]; then
    echo "⚠️  포스트가 없습니다. 먼저 포스트를 생성해주세요."
    exit 1
fi

# Redis 캐시 초기화
echo "기존 캐시 데이터 삭제..."
docker exec sns-redis redis-cli DEL friend_feed:1001

# 사용자 1001의 뉴스피드에 실제 존재하는 포스트 ID들 추가
echo "사용자 1001의 뉴스피드에 포스트 추가..."
for post_id in $POST_IDS; do
    docker exec sns-redis redis-cli ZADD friend_feed:1001 $post_id "$post_id"
done

echo "캐시 데이터 설정 완료!"

# 설정된 데이터 확인
echo -e "\n=== 설정된 캐시 데이터 확인 ==="
echo "사용자 1001의 뉴스피드 (최신순):"
docker exec sns-redis redis-cli ZREVRANGE friend_feed:1001 0 -1 WITHSCORES

CACHE_COUNT=$(docker exec sns-redis redis-cli ZCARD friend_feed:1001)
echo -e "\n캐시된 포스트 개수: $CACHE_COUNT"

echo -e "\n=== Redis 캐시 설정 완료! ==="
