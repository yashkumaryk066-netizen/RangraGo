#!/bin/bash
# RangraGo Build Watcher — GitHub Actions ko monitor karta hai
# Jab naya build complete ho, Chrome mein APK download link open karta hai

REPO="yashkumaryk066-netizen/RangraGo"
APK_URL="https://github.com/yashkumaryk066-netizen/RangraGo/releases/latest/download/RangraGo.apk"
RELEASE_URL="https://github.com/yashkumaryk066-netizen/RangraGo/releases/latest"
CHECK_INTERVAL=30  # seconds

echo "🔍 RangraGo Build Watcher Started..."
echo "📡 Monitoring: https://github.com/$REPO/actions"
echo "⏱️  Checking every ${CHECK_INTERVAL} seconds..."
echo ""

LAST_RUN_ID=""
LAST_STATUS=""

while true; do
    # Get latest run info
    RESPONSE=$(curl -s "https://api.github.com/repos/$REPO/actions/runs?per_page=1")
    
    RUN_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; r=json.load(sys.stdin)['workflow_runs'][0]; print(r['id'])" 2>/dev/null)
    STATUS=$(echo "$RESPONSE" | python3 -c "import sys,json; r=json.load(sys.stdin)['workflow_runs'][0]; print(r['status'])" 2>/dev/null)
    CONCLUSION=$(echo "$RESPONSE" | python3 -c "import sys,json; r=json.load(sys.stdin)['workflow_runs'][0]; print(r.get('conclusion',''))" 2>/dev/null)
    
    TIMESTAMP=$(date '+%H:%M:%S')
    
    if [ "$RUN_ID" != "$LAST_RUN_ID" ] && [ -n "$LAST_RUN_ID" ]; then
        echo "[$TIMESTAMP] 🆕 New build detected! Run ID: $RUN_ID"
    fi
    
    if [ "$STATUS" = "in_progress" ] || [ "$STATUS" = "queued" ]; then
        echo "[$TIMESTAMP] ⏳ Build in progress... (Run: $RUN_ID)"
    elif [ "$STATUS" = "completed" ]; then
        if [ "$CONCLUSION" = "success" ] && [ "$RUN_ID" != "$LAST_STATUS" ]; then
            echo ""
            echo "[$TIMESTAMP] ✅ BUILD SUCCESSFUL!"
            echo "[$TIMESTAMP] 🔗 APK Link: $APK_URL"
            echo "[$TIMESTAMP] 🌐 Opening in Chrome..."
            
            # Open in Chrome
            if command -v google-chrome &> /dev/null; then
                google-chrome "$APK_URL" &
            elif command -v chromium-browser &> /dev/null; then
                chromium-browser "$APK_URL" &
            elif command -v xdg-open &> /dev/null; then
                xdg-open "$RELEASE_URL" &
            fi
            
            echo "[$TIMESTAMP] 🎉 Chrome mein APK download link open ho gaya!"
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  Download Link: $APK_URL"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            LAST_STATUS="$RUN_ID"
        elif [ "$CONCLUSION" = "failure" ]; then
            echo "[$TIMESTAMP] ❌ Build FAILED! Check: https://github.com/$REPO/actions"
        fi
    fi
    
    LAST_RUN_ID="$RUN_ID"
    sleep $CHECK_INTERVAL
done
