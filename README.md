# 1. 프로젝트 개요 및 제출물
- 리눅스 서버의 안정성을 확보하기 위해 다중 사용자 권한 관리, 네트워크 보안 설정, 그리고 시스템 관제 자동화를 통합 구현한 서버 엔지니어링 실습 과제입니다. 쉘 스크립트(Bash)를 활용하여 서비스의 상태를 주기적으로 수집하고, 장애 징후를 사전에 탐지할 수 있는 로그 자동화 시스템을 구축하는 것이 핵심입니다.

## 핵심 수행 내용
1. 권한 및 보안 관리
- 다중 사용자 환경에서의 계정별 권한 분리 및 그룹 관리
- 방화벽(UFW) 설정 및 비표준 포트 활용을 통한 네트워크 보안 강화

2. 관제 자동화 스크립트 (monitor.sh) 개발
- 헬스 체크: 애플리케이션 프로세스 실행 여부 및 포트(15034) 응답 상태 확인
- 리소스 모니터링: CPU, 메모리, 디스크 사용률 실시간 수집
- 임계치 경고: 특정 수치 초과 시 로그 및 콘솔에 [WARNING] 메시지 출력

3. 데이터 로깅 및 자동화
- cron 스케줄러를 통한 1분 단위 무인 감시 체계 구축
- 표준화된 포맷으로 /var/log/agent-app/monitor.log에 기록 누적

## 기술 스택
- OS: Linux (Ubuntu/Docker)
- Script: Bash Shell Script
- Target: Python Application (agent_app.py)
- Tools: crontab, ss, pgrep, awk, sed


## 파일 구조

README.md       # 수행 내역서
monitor.sh      # 자동화 스크립트 소스코드
report.sh       # 


# 2. 전체 수행 흐름
- 1단계: SSH 보안 설정 및 방화벽 구성
- 2단계: 계정/그룹/권한 체계 구성
- 3단계: Python 앱 실행 환경 구성 및 실행 확인
- 4단계: Bash 모니터링 스크립트 작성
- 5단계: cron에 주기 실행 등록 및 결과 확인

# 3. 각 단계별 세부 수행 내용
## (1) 기본 보안 및 네트워크 설정
- SSH 설정
    - SSH 접속포트를 20022로 변경
    - Root 원격 로그인을 차단(PermitRootLogin no 설정)
    - 확인 방법: 
- 방화벽 설정
    - UFW 또는 firewalld 중 하나를 선택해 활성화
    - 인바운드 허용 포트는 TCP 20022(SSH), TCP 15034(APP)만 허용
    - 확인 방법:

## (2) 계정/그룹/권한 체계(협업 + 최소 권한)
- 생성 계정
    - agent-admin (운영/관리, cron 실행자)
    - agent-dev (개발/운영, monitor.sh 작성자)
    - agent-test (QA/테스트)
- 생성 그룹
    - agent-common: admin, dev, test
    - agent-core: admin, dev
- 디렉터리 구조
    - $AGENT_HOME
    - $AGENT_HOME/upload_files
    - $AGENT_HOME/api_keys
    - /var/log/agent-app
- 접근 권한
    - upload_files: group=agent-common, R/W 가능
    - api_keys 및 /var/log/agent-app: group=agent-core ONLY, R/W 가능
- 확인 방법
    - id agent-admin / id agent-dev / id agent-test
    - ls -l 및 getfacl(사용 시)로 소유/권한 확인

## (3) 애플리케이션 실행 환경 준비
- 설정한 환경 변수 목록
    - AGENT_HOME=/home/agent-admin/agent-app
    - AGENT_PORT=15034
    - AGENT_UPLOAD_DIR: $AGENT_HOME/upload_files
    - AGENT_KEY_PATH: $AGENT_HOME/api_keys/t_secret.key
    - AGENT_LOG_DIR: /var/log/agent-app
- 키 파일 생성
    - 경로: $AGENT_HOME/api_keys/t_secret.key
    - 내용: agent_api_key_test
- 앱 실행 및 확인
    - 일반 사용자 계정으로 실행 (루트 실행 금지)
    - Boot Sequence 5단계 [OK]
    - Agent READY 출력
    - 0.0.0.0:15034 LISTEN 확인

## (4) 시스템 관제 자동화 스크립트(monitor.sh) 구현
- 스크립트 파일 위치
    - $AGENT_HOME/bin/monitor.sh
- 파일 권한
    - 소유자: agent-dev
    - 그룹: agent-core
    - 권한: 750 (rwxr-x---)
- 구현 내용
    - agent_app.py 프로세스 확인 (비정상시 exit 1)
    - TCP 15034 LISTEN 확인 (비정상시 exit 1)
    - 방화벽(UFW 또는 firewalld) 활성화 확인 (비활성 시 WARNING 출력)
    - CPU / 메모리 / 디스크 사용률 수집
    - 임계치 경고 출력
        - CPU > 20% / MEM > 10% / DISK_USED
    - 로그 기록: /var/log/agent-app/monitor.log
    - 로그 형식: [YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
- 로그 보존 정책
    - 최대 10MB 또는 10개 파일 유지
    - logrotate 사용 여부나 스크립트 처리 방식

## (5) 자동 실행(cron) 등록
- agent-admin 계정의 crontab에 등록
    - /home/agent-admin/agent-app/bin/monitor.sh
- 확인 방법
    - crontab -l
    - 1~2분 후 monitor.log 기록 누적 확인

# 4. 증거 자료 및 확인 결과
- SSH 포트 변경(20022) 및 Root 원격 접속 차단 설정 확인 내역
- 방화벽(UFW 또는 firewalld) 활성화 및 20022/tcp, 15034/tcp만 허용 내역
- 계정/그룹(agent-admin/dev/test, agent-common/core) 생성 확인 내역
- 디렉토리 구조 및 권한(ACL 포함) 확인 내역
- 앱 Boot Sequence 5단계 [OK] 및 “Agent READY” 확인 내역
- monitor.sh 실행 결과(프로세스/포트/리소스/경고) 내역
- /var/log/agent-app/monitor.log 누적 기록 확인(최근 라인) 내역
- crontab 매분 실행 등록 및 자동 실행 확인(1분 후 로그 증가) 내역
