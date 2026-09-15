#!/bin/bash
# HERP Hire API 選考予定作成テストスクリプト
# 使い方: HERP_API_KEY=xxxxx ./test_contact_creation.sh
#
# hashimoto_naoki さんのAPIキーを使って、
# 指定した応募に対してテスト用の選考予定を作成します。

set -e

if [ -z "$HERP_API_KEY" ]; then
  echo "エラー: 環境変数 HERP_API_KEY が設定されていません"
  echo "例: HERP_API_KEY=xxxxx ./test_contact_creation.sh"
  exit 1
fi

BASE="https://public-api.herp.cloud/hire"
AUTH="Authorization: Bearer ${HERP_API_KEY}"
CANDIDACY_ID="459ba99c-8f28-4744-bac1-368694013986"

echo "===================================================="
echo "STEP1: ユーザー一覧を取得（橋本さんのIDを探します）"
echo "===================================================="
curl -s -X GET \
  "${BASE}/v1/users" \
  -H "${AUTH}" \
  | tee step_users.json | python3 -m json.tool

echo ""
echo "→ 上記の一覧から「橋本尚樹」さんを探し、その \"id\" の値をコピーしてください。"
echo "→ 401/403が出た場合はAPIキーのスコープ（user:read等）を確認してください。"
echo ""
read -p "橋本さんのユーザーIDを貼り付けてください: " USER_ID

if [ -z "$USER_ID" ]; then
  echo "IDが入力されなかったため終了します。"
  exit 1
fi

echo ""
echo "===================================================="
echo "STEP2: 対象の応募情報を確認（本当にテスト対象で合っているか目視確認）"
echo "===================================================="
curl -s -X GET \
  "${BASE}/v1/candidacies/${CANDIDACY_ID}" \
  -H "${AUTH}" \
  | python3 -m json.tool

echo ""
read -p "この応募で合っていますか？テスト予定を作成しますか？ (y/n): " ans1
if [ "$ans1" != "y" ]; then
  echo "中断しました。"
  exit 0
fi

echo ""
echo "===================================================="
echo "STEP3: テスト用の選考予定（コンタクト）を作成"
echo "===================================================="
echo "⚠️  この操作は実際にHERP上にテスト予定を作成し、Googleカレンダーにも反映されます。"
read -p "本当に実行しますか？ (y/n): " ans2
if [ "$ans2" != "y" ]; then
  echo "中断しました。"
  exit 0
fi

RESPONSE=$(curl -s -X POST \
  "${BASE}/v1/candidacies/${CANDIDACY_ID}/contacts" \
  -H "${AUTH}" \
  -H "Content-Type: application/json" \
  -d "{
    \"step\": \"entry\",
    \"type\": \"interview\",
    \"requireAssessmentSchedule\": true,
    \"assessmentSchedule\": {
      \"title\": \"【テスト】APIからの選考予定作成\",
      \"adjustBy\": \"all\",
      \"attendeeIds\": [\"${USER_ID}\"]
    }
  }")

echo "$RESPONSE" | python3 -m json.tool || echo "$RESPONSE"

echo ""
echo "===================================================="
echo "結果の見方"
echo "===================================================="
echo "・成功した場合: contacts配列の中に作成された予定の情報（id, assessmentSchedule等）が表示されます"
echo "・400エラーの場合: エラーメッセージに \"type\" や \"adjustBy\" に指定できる値のヒントが"
echo "  含まれていることが多いので、その内容を教えてください（一緒に修正します）"
echo ""
echo "成功していたら、次にHERPの画面とGoogleカレンダーを開いて、"
echo "・選考予定が作られているか"
echo "・カレンダーの「作成者」が hashimoto_naoki@kayac.bond になっているか"
echo "を確認してください。"
