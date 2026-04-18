# Jenkins IaC Guide

## 1. Muc tieu
Tai lieu nay giai thich toan bo setup Jenkins bang IaC trong du an nay: tung file dung de lam gi, workflow dang chay ra sao, can sua bien nao, va sau khi Jenkins len thi thao tac gi tiep.

## 2. Y nghia tung file
- [infra/.env.example](infra/.env.example): Mau bien moi truong de ca team copy thanh .env.
- [infra/.env](infra/.env): Bien moi truong local, chua secret, khong commit.
- [infra/jenkins/Dockerfile](infra/jenkins/Dockerfile): Build custom Jenkins image va cai tool can thiet (maven, docker cli, kubectl).
- [infra/jenkins/docker-compose.yml](infra/jenkins/docker-compose.yml): Chay Jenkins container, map port, mount volume, nap env, healthcheck.
- [infra/jenkins/plugins.txt](infra/jenkins/plugins.txt): Danh sach plugin Jenkins can cai san.
- [infra/jenkins/jenkins.yaml](infra/jenkins/jenkins.yaml): Jenkins Configuration as Code (JCasC), dung de auto config user, security, credential, global settings.
- [infra/scripts/jenkins.ps1](infra/scripts/jenkins.ps1): Script bootstrap cho Windows.
- [infra/scripts/jenkins.sh](infra/scripts/jenkins.sh): Script bootstrap cho Linux/macOS.
- [infra/jenkins_data](infra/jenkins_data): Persistent data cua Jenkins (job history, config, plugin state, credentials state).
- [Jenkinsfile](Jenkinsfile): Pipeline CI/CD logic cua source code, duoc Jenkins doc tu repo khi chay job.

## 3. Workflow dang chay
1. Ban chay script bootstrap (ps1 hoac sh).
2. Script tao .env neu chua co, tao jenkins_data, tao kubeconfig fallback.
3. Script goi docker compose up --build.
4. Compose build image tu Dockerfile va cai plugin tu plugins.txt.
5. Container Jenkins len, mount jenkins.yaml va jenkins_data.
6. Jenkins startup va doc JCasC tu jenkins.yaml de auto tao admin user + credential dockerhub-creds.
7. Ban tao Pipeline job tren UI, job nay doc [Jenkinsfile](Jenkinsfile) tu repo va thuc thi build/push image.

## 4. Bien can config
### Bat buoc
- DOCKERHUB_USER
- DOCKERHUB_TOKEN
- JENKINS_ADMIN_PASSWORD

### Thuong de mac dinh
- JENKINS_UI_PORT (default 8080)
- JENKINS_AGENT_PORT (default 50000)
- JENKINS_DATA_PATH (default ../jenkins_data)
- DOCKER_HOST_SOCKET (default /var/run/docker.sock)
- KUBECTL_VERSION (default stable)

### Optional
- KUBECONFIG_PATH: De trong neu chua deploy K8s tu Jenkins.

## 5. Cach chay
### Windows
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\jenkins.ps1 -Action up
```

### Linux/macOS
```bash
bash ./scripts/jenkins.sh up
```

### Lenh thuong dung
```powershell
# logs
powershell -ExecutionPolicy Bypass -File .\scripts\jenkins.ps1 -Action logs

# stop
powershell -ExecutionPolicy Bypass -File .\scripts\jenkins.ps1 -Action down

# reset (xoa container + volume cua compose)
powershell -ExecutionPolicy Bypass -File .\scripts\jenkins.ps1 -Action reset
```

## 6. Chay xong thi lam gi tiep
1. Mo http://localhost:8080.
2. Dang nhap bang JENKINS_ADMIN_ID va JENKINS_ADMIN_PASSWORD trong .env.
3. Vao Manage Jenkins -> Credentials, kiem tra credential id dockerhub-creds da ton tai.
4. Tao Pipeline job tro toi repo nay.
5. Bam Build Now de test mot lan.
6. Xac nhan log co cac buoc checkout, mvn build, docker build, docker push.
7. Kiem tra Docker Hub da co tag moi.
8. Cau hinh webhook GitHub neu muon auto trigger khi push.

## 7. Jenkinsfile co can lien ket gi voi setup Docker khong
Co, nhung chi lien ket o muc logic CI.

- Credential ID trong [Jenkinsfile](Jenkinsfile) phai trung voi id trong [infra/jenkins/jenkins.yaml](infra/jenkins/jenkins.yaml). Hien tai dang trung la dockerhub-creds.
- DOCKERHUB_USER trong [Jenkinsfile](Jenkinsfile) nen trung voi DOCKERHUB_USER trong .env de tranh login mot user nhung push repo path cua user khac.
- [Jenkinsfile](Jenkinsfile) khong can biet chi tiet docker-compose, no chi can Jenkins container co docker socket va tool day du.

## 8. Danh gia do gon cua setup hien tai
Setup hien tai khong qua ruom ra cho muc tieu team-shared IaC.

No tach thanh cac lop ro rang:
- Build image
- Runtime orchestration
- Jenkins config as code
- Bootstrap script cho team
- Pipeline code trong repo

Neu chi dung cho local demo mot nguoi, ban co the rut gon.

## 9. To chuc gon nhat de xai
### Ban toi gian cho team Windows
- Giu [infra/.env.example](infra/.env.example)
- Giu [infra/jenkins/Dockerfile](infra/jenkins/Dockerfile)
- Giu [infra/jenkins/docker-compose.yml](infra/jenkins/docker-compose.yml)
- Giu [infra/jenkins/jenkins.yaml](infra/jenkins/jenkins.yaml)
- Giu [infra/jenkins/plugins.txt](infra/jenkins/plugins.txt)
- Giu [infra/scripts/jenkins.ps1](infra/scripts/jenkins.ps1)
- Giu [Jenkinsfile](Jenkinsfile)

### Co the bo
- [infra/scripts/jenkins.sh](infra/scripts/jenkins.sh) neu team khong dung Linux/macOS
- [infra/Makefile](infra/Makefile) neu da chot dung script ps1

Ket luan: 3 file (Dockerfile + compose + env) du cho viec chay container, nhung khong du cho auto bootstrap Jenkins settings va team reproducibility. Khi can IaC that su cho team, jenkins.yaml va plugins.txt la 2 file rat nen giu.
