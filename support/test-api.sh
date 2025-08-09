#!/bin/bash

BASE_URL="http://localhost:8080"
USER_ID="1001"

echo "=== SNS API 통합 테스트 ==="
echo "테스트 사용자 ID: $USER_ID"
echo ""

# 1. 포스트 생성
echo "1. 포스트 생성 테스트"
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "X-User-Id: $USER_ID" \
  -d '{"content": "새로운 테스트 포스트입니다! 🚀"}' \
  "$BASE_URL/api/feeds")

echo "Response: $RESPONSE"
echo ""

# 2. 포스트 ID 추출
POST_ID=$(echo $RESPONSE | jq -r '.id')
echo "생성된 포스트 ID: $POST_ID"
echo ""

# 3. 친구 피드 조회 (Redis 캐시에서 데이터 로드)
echo "2. 친구 피드 조회 테스트"
FRIENDS_FEED_RESPONSE=$(curl -s -X GET \
  -H "X-User-Id: $USER_ID" \
  "$BASE_URL/api/feeds/friends")

echo "사용자 $USER_ID의 친구 피드:"
echo $FRIENDS_FEED_RESPONSE | jq '.'

FRIENDS_FEED_COUNT=$(echo $FRIENDS_FEED_RESPONSE | jq 'length')
echo "친구 피드 포스트 개수: $FRIENDS_FEED_COUNT"
echo ""

# 4. 내 피드 조회
echo "3. 내 피드 조회 테스트"
MY_FEED_RESPONSE=$(curl -s -X GET \
  -H "X-User-Id: $USER_ID" \
  "$BASE_URL/api/feeds/my")

echo "사용자 $USER_ID의 내 피드:"
echo $MY_FEED_RESPONSE | jq '.'

MY_FEED_COUNT=$(echo $MY_FEED_RESPONSE | jq 'length')
echo "내 피드 포스트 개수: $MY_FEED_COUNT"
echo ""

# 5. 포스트 삭제
echo "4. 포스트 삭제 테스트"
if [ "$POST_ID" != "null" ] && [ -n "$POST_ID" ]; then
    DELETE_RESPONSE=$(curl -s -X DELETE \
      -H "X-User-Id: $USER_ID" \
      "$BASE_URL/api/feeds/$POST_ID")
    echo "포스트 ID $POST_ID 삭제 완료"
    
    # 삭제 후 내 피드 다시 조회
    echo "삭제 후 내 피드 확인:"
    AFTER_DELETE=$(curl -s -X GET \
      -H "X-User-Id: $USER_ID" \
      "$BASE_URL/api/feeds/my")
    AFTER_COUNT=$(echo $AFTER_DELETE | jq 'length')
    echo "삭제 후 내 피드 포스트 개수: $AFTER_COUNT"
else
    echo "삭제할 포스트 ID를 찾을 수 없습니다."
fi
echo ""

echo "✅ 테스트 완료!"
echo "📊 테스트 결과: 포스트 생성 → 친구 피드 조회 → 내 피드 조회 → 포스트 삭제 → 재조회"