# 1. 프로젝트 개요 및 제출물
- 
```
파일 구조(예시)

README.md       # 수행 내역서
monitor.sh      # 자동화 스크립트
report.sh       # 
```

# 2. 전체 수행 흐름
- 1단계: SSH 보안 설정 및 방화벽 구성
- 2단계: 계정/그룹/권한 체계 구성
- 3단계: Python 앱 실행 환경 구성 및 실행 확인
- 4단계: Bash 모니터링 스크립트 작성
- 5단계: cron에 주기 실행 등록 및 결과 확인

# 3. 각 단계별 세부 수행 내용
## (1) 기본 보안 및 네트워크 설정
- 어떤 설정을 변경했는지
    - sshd_config에서 Port 20022로 변경
    - PermitRootLogin no 설정
- 방화벽 설정
    - UFW 또는 firewalld 중 무엇을 사용했는지
    - 허용한 포트: 20022/tcp, 15034/tcp
- 확인 방법
    - ss -tulnp | grep sshd
    - sudo ufw status 또는 sudo firewall-cmd --list-all

## (2) 계정 및 그룹 / 권한 체계
- 만든 계정
    - agent-admin
    - agent-dev
    - agent-test
- 만든 그룹
    - agent-common
    - agent-core
- 그룹에 배정한 구성
    - agent-common: admin, dev, test
    - agent-core: admin, dev
- 디렉터리 구조
    - $AGENT_HOME
    - $AGENT_HOME/upload_files
    - $AGENT_HOME/api_keys
    - /var/log/agent-app
- 파일/디렉터리 권한 정책
    - upload_files: agent-common 읽기/쓰기
    - api_keys: agent-core 전용
    - /var/log/agent-app: agent-core 전용
- 확인 방법
    - id agent-dev
    - ls -ld
    - getfacl 또는 stat

## (3) 애플리케이션 실행 환경 준비
- 설정한 환경 변수 목록
    - AGENT_HOME
    - AGENT_PORT=15034
    - AGENT_UPLOAD_DIR
    - AGENT_KEY_PATH
    - AGENT_LOG_DIR
- 키 파일 생성
    - 경로: $AGENT_HOME/api_keys/t_secret.key
    - 내용: agent_api_key_test
- 앱 실행 및 확인
    - 일반 사용자 계정으로 실행
    - Boot Sequence 5단계 [OK]
    - Agent READY
    - 0.0.0.0:15034 LISTEN 확인

## (4) 모니터링 스크립트 구현
- 스크립트 파일 위치
    - $AGENT_HOME/bin/monitor.sh
- 파일 권한
    - 소유자: agent-dev
    - 그룹: agent-core
    - 권한: 750
- 구현 내용
    - agent_app.py 프로세스 확인
    - 15034 포트 LISTEN 확인
    - 방화벽 활성화 확인 (비활성 시 경고)
    - CPU / 메모리 / 디스크 사용률 수집
    - 임계치 경고 출력
    - 로그 기록: /var/log/agent-app/monitor.log
    - 로그 형식: [YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
- 로그 보존 정책
    - 최대 10MB 또는 10개 파일 유지
    - logrotate 사용 여부나 스크립트 처리 방식

## (5) 자동 실행(cron) 등록
- agent-admin 계정의 crontab에 등록
    - 예: * * * * * /home/agent-admin/agent-app/bin/monitor.sh
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
