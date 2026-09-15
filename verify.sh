#!/bin/bash
# HERP Hire API 疎通確認スクリプト
# 使い方: HERP_API_KEY=xxxxx ./verify.sh
#
# 各ステップは独立して実行できます。まず STEP1 だけ動かして、
# 問題なければ次に進んでください。

set -e

if [ -z "$HERP_API_KEY" ]; then
  echo "エラー: 環境変数 HERP_API_KEY が設定されていません"
  echo "例: HERP_API_KEY=xxxxx ./verify.sh"
  exit 1
fi

BASE="https://public-api.herp.cloud/hire"
AUTH="Authorization: Bearer ${HERP_API_KEY}"

echo "===================================================="
echo "STEP1: 疎通確認 — 選考ステップ=エントリーの応募一覧を取得"
echo "===================================================="
curl -s -X GET \
  "${BASE}/v1/candidacies?step=entry&status=active" \
  -H "${AUTH}" \
  -H "Content-Type: application/json" \
  | tee step1_candidacies.json | python3 -m json.tool

echo ""
echo "→ 上記に候補者が表示されていればOKです。"
echo "→ 401/403が出た場合はAPIキーのスコープ（candidacy:read）を確認してください。"
echo ""
read -p "STEP1は成功しましたか？次に進みますか？ (y/n): " ans1
if [ "$ans1" != "y" ]; then
  echo "STEP1で停止しました。エラー内容を確認してください。"
  exit 0
fi

echo ""
echo "上記JSONの中から、テストしたい1件の候補者の \"id\" をコピーして入力してください。"
read -p "candidacyId: " CID

echo "===================================================="
echo "STEP2: 応募詳細の取得"
echo "===================================================="
curl -s -X GET \
  "${BASE}/v1/candidacies/${CID}" \
  -H "${AUTH}" \
  | tee step2_detail.json | python3 -m json.tool

echo ""
echo "===================================================="
echo "STEP3: 添付ファイル一覧の取得"
echo "===================================================="
curl -s -X GET \
  "${BASE}/v1/candidacies/${CID}/files" \
  -H "${AUTH}" \
  | tee step3_files.json | python3 -m json.tool

echo ""
echo "→ resumesファイルのfileIdが取れていることを確認してください。"
echo "→ 実際にファイル本体をダウンロードしたい場合は以下を実行:"
echo "   curl -s -X GET \"${BASE}/v1/candidacies/${CID}/files/{fileId}\" -H \"${AUTH}\" -o resume.pdf"
echo ""
read -p "STEP2・3は成功しましたか？投稿テスト(STEP4)に進みますか？ (y/n): " ans2
if [ "$ans2" != "y" ]; then
  echo "投稿テストは行わず終了しました。"
  exit 0
fi

echo ""
echo "===================================================="
echo "STEP4: タイムラインへのテスト投稿（1件のみ）"
echo "===================================================="
echo "⚠️  この操作は実際に候補者 ${CID} のタイムラインにコメントが投稿されます。"
read -p "本当に投稿しますか？ (y/n): " ans3
if [ "$ans3" != "y" ]; then
  echo "投稿をキャンセルしました。"
  exit 0
fi

curl -s -X POST \
  "${BASE}/v1/candidacies/${CID}/timeline-comments" \
  -H "${AUTH}" \
  -H "Content-Type: application/json" \
  -d '{
    "body": "【テスト投稿】API疎通確認のためのテストコメントです。問題なければこのコメントは削除してください。\n\n🤖 by Claude Code",
    "textType": "text/markdown"
  }' \
  | python3 -m json.tool

echo ""
echo "===================================================="
echo "STEP5: 投稿の確認（タイムラインコメント取得）"
echo "===================================================="
curl -s -X GET \
  "${BASE}/v1/candidacies/${CID}/timeline-comments" \
  -H "${AUTH}" \
  | python3 -m json.tool

echo ""
echo "===================================================="
echo "STEP6: 求人要件の取得確認"
echo "===================================================="
curl -s -X GET \
  "${BASE}/v1/requisitions?status=active" \
  -H "${AUTH}" \
  | tee step6_requisitions.json | python3 -m json.tool

echo ""
echo "すべてのステップが完了しました。"
echo "HERP Hireの画面上でも、実際にテストコメントが投稿されているか目視確認してください。"
echo "確認後、STEP4で投稿したテストコメントは手動で削除しておくことをおすすめします。"
