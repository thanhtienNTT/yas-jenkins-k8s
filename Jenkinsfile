/*
 * Jenkinsfile: CI (Build/Push) + CD GitOps (ArgoCD Integration)
 * Tối ưu hóa: Dual Tagging cho DEV và Image Retagging cho STAGING
 */

def writeGitOpsServiceOverride(String environmentName, String service, String tag) {
    writeFile(
        file: "environments/${environmentName}/services/${service}.yaml",
        text: """\
            backend:
              image:
                tag: "${tag}"
        """.stripIndent()
    )
}

def updateGitOpsRepo(String envName, String imageTag) {
    def allServices = env.ALL_SERVICES.split(',') as List
    
    withCredentials([string(credentialsId: env.GITOPS_TOKEN_CREDENTIALS_ID, variable: 'GITOPS_TOKEN')]) {
        def repoNoProtocol = env.GITOPS_REPO_URL.replaceFirst('https://', '')
        
        sh """
            rm -rf ${env.GITOPS_DIR}
            git clone https://x-access-token:${GITOPS_TOKEN}@${repoNoProtocol} ${env.GITOPS_DIR}
        """
        
        dir("${env.GITOPS_DIR}") {
            allServices.each { svc ->
                writeGitOpsServiceOverride(envName, svc, imageTag)
            }

            sh """
                git config user.name "${env.GITOPS_COMMIT_USER}"
                git config user.email "${env.GITOPS_COMMIT_EMAIL}"
                git add environments/${envName}/services
                
                if git diff --cached --quiet; then
                    echo ">>> Nothing changed for ${envName}. Skip commit."
                else
                    git commit -m "ci(${envName}): update images to ${imageTag} [skip ci]"
                    git push origin HEAD:main
                fi
            """
        }
    }
}

// HÀM: Kéo image từ Docker Hub, đổi tag và đẩy lên lại
def retagAndPushBackendImage(String service, String sourceTag, String targetTag, String dockerNamespace, String dockerCredentialsId) {
    withCredentials([usernamePassword(credentialsId: dockerCredentialsId, usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_TOKEN')]) {
        def sourceImage = "${dockerNamespace}/yas-${service}:${sourceTag}"
        def targetImage = "${dockerNamespace}/yas-${service}:${targetTag}"
        sh """
            echo \"${DOCKERHUB_TOKEN}\" | docker login -u \"${DOCKERHUB_USERNAME}\" --password-stdin
            docker pull ${sourceImage}
            docker tag ${sourceImage} ${targetImage}
            docker push ${targetImage}
            docker logout
        """
        echo ">>> Đã đổi tên thành công: ${sourceImage} -> ${targetImage}"
    }
}

pipeline {
    agent { label 'build' }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        DOCKERHUB_USER        = 'akiratomori'
        DOCKER_CREDENTIALS_ID = 'dockerhub-creds'
        ALL_SERVICES          = 'order,tax,cart,media'

        GITOPS_REPO_URL             = "https://github.com/AkiraTomori/ArgoCD-Advanced.git"
        GITOPS_TOKEN_CREDENTIALS_ID = 'gitops-token'
        GITOPS_DIR                  = 'gitops-yas'
        GITOPS_COMMIT_USER          = 'jenkins-bot'
        GITOPS_COMMIT_EMAIL         = 'jenkins@local'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Detect Scope & Tag') {
            steps {
                script {
                    env.BRANCH_NAME_RESOLVED = env.BRANCH_NAME ?: env.GIT_BRANCH ?: sh(
                        script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true
                    ).trim()

                    // Lấy mã hash 8 ký tự
                    env.GIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IS_MAIN = (env.BRANCH_NAME_RESOLVED == 'main' || env.BRANCH_NAME_RESOLVED.endsWith('/main')).toString()
                    
                    if (env.TAG_NAME) {
                        // Kịch bản 1: Push Tag (Cho Staging)
                        env.IS_RELEASE = "true"
                        env.IMAGE_TAG = env.TAG_NAME
                    } else {
                        // Kịch bản 2: Push Branch (Cho Dev hoặc Developer)
                        env.IS_RELEASE = "false"
                        // LUÔN LUÔN dùng mã hash để build image ban đầu, đảm bảo tính tracking
                        env.IMAGE_TAG = env.GIT_SHA
                    }

                    echo "SCOPE: IS_MAIN=${env.IS_MAIN}, IS_RELEASE=${env.IS_RELEASE}, TAG=${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build and Push Services') {
            // Bỏ qua stage này nếu đang chạy cho Release (Staging)
            when { expression { return env.IS_RELEASE.toBoolean() == false } }
            steps {
                script {
                    def allServices = env.ALL_SERVICES.split(',') as List
                    def servicesToBuild = []

                    if (env.IS_MAIN.toBoolean()) {
                        servicesToBuild = allServices
                    } else {
                        def branchService = env.BRANCH_NAME_RESOLVED.replaceFirst(/^dev_/, '').replaceFirst(/_service$/, '')
                        if (allServices.contains(branchService)) {
                            servicesToBuild = [branchService]
                        } else {
                            error "Cannot determine service from branch name: ${env.BRANCH_NAME_RESOLVED}"
                        }
                    }

                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'U', passwordVariable: 'P')]) {
                        sh 'echo "$P" | docker login -u "$U" --password-stdin'
                        servicesToBuild.each { svc ->
                            echo "===== BUILDING: ${svc} ====="
                            sh "mvn -B clean package -pl ${svc} -am -DskipTests"
                            // Build với tag là env.GIT_SHA
                            def fullImageName = "${DOCKERHUB_USER}/yas-${svc}:${IMAGE_TAG}"
                            dir("${svc}") {
                                sh "docker build -t ${fullImageName} ."
                                sh "docker push ${fullImageName}"
                            }
                        }
                        sh 'docker logout || true'
                    }
                }
            }
        }

        stage('CD Dev GitOps Update') {
            when { expression { return env.IS_MAIN.toBoolean() } }
            steps {
                script {
                    echo ">>> Bắt đầu Dual Tagging cho DEV..."
                    def allServices = env.ALL_SERVICES.split(',') as List
                    
                    // 1. Tạo thêm tag 'main' từ mã hash vừa build và đẩy lên Docker Hub
                    allServices.each { String service ->
                        retagAndPushBackendImage(service, env.IMAGE_TAG, 'main', env.DOCKERHUB_USER, env.DOCKER_CREDENTIALS_ID)
                    }

                    // 2. Cập nhật GitOps cho Dev bằng mã hash để ép ArgoCD tự động Sync
                    echo ">>> Đang cập nhật môi trường DEV ArgoCD với tag: ${env.IMAGE_TAG}"
                    updateGitOpsRepo('dev', env.IMAGE_TAG)
                }
            }
        }

        stage('CD Staging GitOps Update') {
            when { tag "v*" }
            steps {
                script {
                    echo ">>> Bắt đầu quy trình Retagging cho STAGING..."
                    def allServices = env.ALL_SERVICES.split(',') as List
                    
                    // Kéo tag 'main' (vừa được tạo ở bước Dev) về và đổi thành vX.X.X
                    allServices.each { String service ->
                        retagAndPushBackendImage(service, 'main', env.IMAGE_TAG, env.DOCKERHUB_USER, env.DOCKER_CREDENTIALS_ID)
                    }

                    echo ">>> Đang cập nhật môi trường STAGING GitOps với tag: ${env.IMAGE_TAG}"
                    updateGitOpsRepo('staging', env.IMAGE_TAG)
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}