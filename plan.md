# 리눅스 서버의 보안 설정부터 자동화 스크립트 개발

1단계: 서버 기초 보안 및 네트워크 설정
서버에 외부인이 함부로 들어오지 못하게 문을 잠그는 과정입니다.   
- SSH 포트 변경: 기본 포트인 22번 대신 20022번을 사용하도록 /etc/ssh/sshd_config 파일을 수정하세요.   
- Root 접속 차단: 보안을 위해 루트 계정으로 직접 원격 접속하는 것을 막아야 합니다. (PermitRootLogin no 설정)   
- 방화벽(UFW) 설정: 문을 다 닫고, 꼭 필요한 20022(SSH)와 15034(앱) 포트만 열어주세요. 

$ sudo vi /etc/ssh/sshd_config (SSH 설정 변경)
[sudo] password for byj: 

0. SSH 서버 설치: sudo apt update && sudo apt install openssh-server -y
1. 검색: /Port 22
2. 수정: i (아래에 -- INSERT -- 확인)
3. 값 변경: Port 22를 Port 20022로 수정
4. Root 차단: /PermitRoot를 검색 > PermitRootLogin no로 수정 
5. 저장: Esc 누르고 :wq!

sudo ufw allow 20022/tcp (방화벽 허용)

sudo adduser agent-admin (계정 생성)

sudo groupadd agent-core (그룹 생성)

2단계: 계정 및 권한 체계 구축
여러 사람이 서버를 함께 사용할 때 서로의 영역을 침범하지 않도록 '최소 권한 원칙'을 적용하는 단계입니다.   
- 계정 및 그룹 생성: agent-admin, agent-dev, agent-test 계정을 만들고, 목적에 맞게 agent-common, agent-core 그룹에 배정하세요.   
- 디렉토리 구조 및 권한 설정: 앱이 돌아갈 폴더를 만들고, chown과 chmod 명령어를 사용해 특정 그룹만 읽고 쓸 수 있게 권한을 제한하세요. 특히 api_keys 폴더는 핵심 그룹(agent-core)만 접근 가능해야 합니다. 

3단계: 애플리케이션 실행 환경 준비
제공받은 Python 앱이 정상적으로 동작할 수 있도록 밑바탕을 깔아주는 과정입니다.   
- 환경 변수 등록: $AGENT_HOME, $AGENT_PORT 등 앱이 참조할 경로와 설정값들을 .bashrc 등에 등록하거나 실행 시 지정하세요.   
- 앱 실행 테스트: 루트가 아닌 일반 계정으로 앱을 실행해 보세요. 터미널에 "Agent READY"라는 문구가 뜨고 15034 포트가 리슨(LISTEN) 상태라면 성공입니다.

4단계: 시스템 관제 스크립트(monitor.sh) 개발
이번 미션의 핵심으로, 서버 상태를 자동으로 체크하는 로직을 작성합니다.   
- 언어: 반드시 Bash 쉘 스크립트로만 작성해야 합니다.   
- 포함될 내용:
1. 상태 점검: 앱 프로세스가 살아있는지, 포트가 열려있는지 확인 (실패 시 종료).   
2. 자원 수집: CPU, 메모리, 디스크 사용률을 계산합니다.  
3. 로그 기록: 수집한 데이터를 지정된 형식에 맞춰 /var/log/agent-app/monitor.log에 저장합니다.   
- 자동화: 작성한 스크립트가 매분 실행되도록 crontab에 등록하세요.   

---

## 해야 할 일 정리

### 1. 미션 요구사항 먼저 파악하기
- README에 정리한 내용이 전체 미션 흐름과 맞는지 확인
- 실제 미션에서는 `monitor.sh` 작성과 `crontab` 등록이 핵심
- 제공된 Python 앱이 있는지, 실행 방법과 위치를 먼저 확인

### 2. 서버 보안 설정 (1단계)
- sshd_config 수정
  - `Port 22` → `Port 20022`
  - `PermitRootLogin no`
- SSH 설정 변경 후 SSH 서버 재시작
  - `sudo systemctl restart sshd`
- UFW 방화벽 설정
  - `sudo ufw allow 20022/tcp`
  - `sudo ufw allow 15034/tcp`
  - `sudo ufw enable`
- SSH 포트와 방화벽 규칙이 제대로 적용됐는지 확인

### 3. 계정 / 그룹 / 권한 구성 (2단계)
- 사용자 생성
  - `agent-admin`, `agent-dev`, `agent-test`
- 그룹 생성
  - `agent-common`, `agent-core`
- 계정 그룹 배치
  - 예: `sudo usermod -aG agent-common agent-dev`
  - `agent-core`는 핵심 권한 필요 계정만
- 디렉토리 구조 생성
  - 앱 폴더, 로그 폴더, `api_keys` 폴더 등
- 소유권 / 권한 설정
  - 앱 폴더: 필요한 그룹만 읽고 쓰기
  - `api_keys` 폴더: `agent-core`만 접근 가능
  - 예: `sudo chown root:agent-core /path/to/api_keys`
  - 예: `sudo chmod 750 /path/to/api_keys`

### 4. 애플리케이션 실행 환경 준비 (3단계)
- 환경 변수 등록
  - `AGENT_HOME`, `AGENT_PORT` 등을 `.bashrc` 또는 실행 스크립트에 추가
- 앱 실행 테스트
  - 일반 사용자 계정으로 실행
  - 터미널에 `Agent READY` 출력 확인
- 포트 리슨 확인
  - `lsof -iTCP:15034 -sTCP:LISTEN` 또는 `ss -ltnp`
- 앱 프로세스가 정상 동작하는지 검증

### 5. 모니터링 스크립트 작성 (4단계)
- `monitor.sh`를 Bash로 작성
- 포함해야 할 내용
  1. 앱 프로세스 상태 확인
  2. 포트 15034 열림 확인
  3. CPU 사용률 수집
  4. 메모리 사용률 수집
  5. 디스크 사용률 수집
  6. `/var/log/agent-app/monitor.log`에 로그 기록
- 실패 시 스크립트가 종료하도록 처리
- 로그 형식은 미리 정해서 일관되게 기록

### 6. 자동화 등록
- `crontab -e`로 매분 실행 등록
  - 예: `* * * * * /path/to/monitor.sh`
- 실행 결과가 정상적으로 로그에 남는지 확인

---

## README에 추가/수정하면 좋은 내용
- `sshd_config` 수정 후 꼭 `systemctl restart sshd` 또는 `service ssh restart` 실행
- `UFW` 상태 확인 명령 추가: `sudo ufw status`
- 그룹에 사용자 추가하는 명령 예시 추가
- `api_keys` 폴더 권한 예시 추가
- `monitor.sh`에서 로그 파일이 없으면 생성하도록 처리
- `crontab` 등록 방법과 확인 방법 추가
  - `crontab -l`

> 요약하자면, 순서는 1) SSH/방화벽 2) 계정·권한 3) 앱 실행 환경 4) `monitor.sh` 작성 5) 크론 등록입니다.