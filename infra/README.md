# Jenkins Infra Quick Start

## 1. Prepare
1. Go to `infra`.
2. Copy `.env.example` to `.env`.
3. Update `.env` values:
   - `DOCKERHUB_USER`
   - `DOCKERHUB_TOKEN`
   - `JENKINS_ADMIN_PASSWORD`
4. `KUBECONFIG_PATH` is optional for now.
5. On Windows, if Docker socket mapping fails, set `DOCKER_HOST_SOCKET=//var/run/docker.sock`.

## 2. Start Jenkins
- Windows: `powershell -ExecutionPolicy Bypass -File .\scripts\jenkins.ps1 -Action up`
- Linux/macOS: `bash ./scripts/jenkins.sh up`

## 3. Open Jenkins
1. Open `http://localhost:8080`.
2. Login with `JENKINS_ADMIN_ID` and `JENKINS_ADMIN_PASSWORD` from `.env`.

## 4. Common commands
- Logs:
  - Windows: `powershell -ExecutionPolicy Bypass -File .\scripts\jenkins.ps1 -Action logs`
  - Linux/macOS: `bash ./scripts/jenkins.sh logs`
- Stop:
  - Windows: `powershell -ExecutionPolicy Bypass -File .\scripts\jenkins.ps1 -Action down`
  - Linux/macOS: `bash ./scripts/jenkins.sh down`
- Reset all Jenkins data:
  - Windows: `powershell -ExecutionPolicy Bypass -File .\scripts\jenkins.ps1 -Action reset`
  - Linux/macOS: `bash ./scripts/jenkins.sh reset`

## 5. Team rule
- Do not commit `infra/.env`.
- Do not commit `infra/jenkins_data`.
- Keep Jenkins configuration only in:
  - `infra/jenkins/docker-compose.yml`
  - `infra/jenkins/Dockerfile`
  - `infra/jenkins/plugins.txt`
  - `infra/jenkins/jenkins.yaml`
