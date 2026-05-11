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