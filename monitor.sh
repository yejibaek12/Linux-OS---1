#!/bin/bash

# 1. 환경 변수 설정
AGENT_HOME="/home/agent-admin/agent-app"
LOG_FILE="/var/log/agent-app/monitor.log"
APP_NAME="agent_app.py"
APP_PORT=15034

# 현재 시간 포맷
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# [HEALTH CHECK]
# 프로세스 확인: ps 명령어로 앱이 실행 중인지 체크
PID=$(pgrep -f "$APP_NAME")

if [ -z "$PID" ]; then
    echo "[$TIMESTAMP] [ERROR] Process '$APP_NAME' is not running." >> "$LOG_FILE"
    exit 1
fi

# 포트 확인: 15034 포트가 LISTEN 상태인지 체크
PORT_CHECK=$(ss -tulnp | grep ":$APP_PORT " | grep "LISTEN")

if [ -z "$PORT_CHECK" ]; then
    echo "[$TIMESTAMP] [ERROR] Port $APP_PORT is not in LISTEN state." >> "$LOG_FILE"
    exit 1
fi

# [RESOURCE MONITORING]
# CPU 및 메모리 사용률 계산 (awk 활용)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
DISK_USED=$(df / | grep / | awk '{print $5}' | sed 's/%//')

# [WARNING CHECK]
# 임계값 경고 출력 (로그에는 남기되 스크립트는 종료하지 않음)
WARNINGS=""
# CPU > 20% 
if (( $(echo "$CPU_USAGE > 20" | bc -l) )); then WARNINGS+="[WARNING] CPU threshold exceeded ($CPU_USAGE% > 20%) "; fi
# MEM > 10% 
if (( $(echo "$MEM_USAGE > 10" | bc -l) )); then WARNINGS+="[WARNING] MEM threshold exceeded (${MEM_USAGE%.*}% > 10%) "; fi
# DISK > 80%
if [ "$DISK_USED" -gt 80 ]; then WARNINGS+="[WARNING] DISK threshold exceeded ($DISK_USED% > 80%)"; fi

# 방화벽 상태 점검
UFW_STATUS=$(sudo ufw status | grep "Status: active")
if [ -z "$UFW_STATUS" ]; then
    WARNINGS+="[WARNING] Firewall is inactive "
fi

# [LOG RECORDING]
# 최종 로그 기록
# 포맷: [YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
echo "[$TIMESTAMP] PID:$PID CPU:${CPU_USAGE}% MEM:${MEM_USAGE%.*}% DISK_USED:${DISK_USED}% $WARNINGS" >> "$LOG_FILE"

# 콘솔 출력용
echo "== SYSTEM MONITOR RESULT =="
echo "Checking process '$APP_NAME'... [OK] (PID: $PID)"
echo "Checking port $APP_PORT... [OK]"
echo "CPU Usage: $CPU_USAGE%"
echo "MEM Usage: ${MEM_USAGE%.*}%"
echo "DISK Used: $DISK_USED%"
if [ ! -z "$WARNINGS" ]; then echo "$WARNINGS"; fi

######################################
######################################

# 파일의 소유자와 그룹 변경
sudo chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh

# 권한 설정 (rwxr-x---)
chmod 750 /home/agent-admin/agent-app/bin/monitor.sh

# crontab 매분 실행 등록 (agent-admin 계정으로 로그인한 상태에서 실행)
crontab -e
* * * * * /home/agent-admin/agent-app/bin/monitor.sh

tail -f /var/log/agent-app/monitor.log