/*
 * Jenkinsfile: CI (Build/Push) + CD GitOps (ArgoCD Integration)
 * Mục tiêu: Tự động hóa việc build service và cập nhật cấu hình cho Dev/Staging
 */

// Hàm ghi đè file YAML trong repo GitOps - Giữ nguyên từ file mẫu của bạn
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

// Hàm dùng chung để clone và push lên GitOps Repo để tránh lặp code
def updateGitOpsRepo(String envName, String imageTag) {
    def allServices = env.ALL_SERVICES.split(',') as List
    
    withCredentials([string(credentialsId: env.GITOPS_TOKEN_CREDENTIALS_ID, variable: 'GITOPS_TOKEN')]) {
        // Xóa dấu https:// để chuẩn bị cho lệnh clone có token
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

        // GitOps Configuration
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
                    // 1. Xác định Branch Name
                    env.BRANCH_NAME_RESOLVED = env.BRANCH_NAME ?: env.GIT_BRANCH ?: sh(
                        script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true
                    ).trim()

                    env.GIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()

                    // 2. Phân loại sự kiện (Main branch hay Release Tag)
                    env.IS_MAIN = (env.BRANCH_NAME_RESOLVED == 'main' || env.BRANCH_NAME_RESOLVED.endsWith('/main')).toString()
                    // Kiểm tra nếu là tag bắt đầu bằng v (ví dụ v1.0.0)
                    env.IS_RELEASE = (env.TAG_NAME != null || env.BRANCH_NAME_RESOLVED =~ /^v\d+/).toString()

                    // 3. Quyết định Image Tag
                    if (env.IS_RELEASE.toBoolean()) {
                        env.IMAGE_TAG = env.TAG_NAME ?: env.BRANCH_NAME_RESOLVED
                    } else if (env.IS_MAIN.toBoolean()) {
                        env.IMAGE_TAG = 'latest'
                    } else {
                        env.IMAGE_TAG = env.GIT_SHA
                    }

                    echo "SCOPE: IS_MAIN=${env.IS_MAIN}, IS_RELEASE=${env.IS_RELEASE}, TAG=${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build and Push Services') {
            steps {
                script {
                    def allServices = env.ALL_SERVICES.split(',') as List
                    def servicesToBuild = []

                    // Nếu là main hoặc tag release -> Build tất cả. Nếu là branch dev_* -> Build 1 service.
                    if (env.IS_MAIN.toBoolean() || env.IS_RELEASE.toBoolean()) {
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

        // --- GIAI ĐOẠN CD: CẬP NHẬT GITOPS CHO DEV ---
        stage('CD Dev GitOps Update') {
            when { expression { return env.IS_MAIN.toBoolean() } }
            steps {
                script {
                    echo ">>> Đang cập nhật môi trường DEV với tag: ${env.IMAGE_TAG}"
                    updateGitOpsRepo('dev', env.IMAGE_TAG)
                }
            }
        }

        // --- GIAI ĐOẠN CD: CẬP NHẬT GITOPS CHO STAGING ---
        stage('CD Staging GitOps Update') {
            when { expression { return env.IS_RELEASE.toBoolean() } }
            steps {
                script {
                    echo ">>> Đang cập nhật môi trường STAGING với tag: ${env.IMAGE_TAG}"
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