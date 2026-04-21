/*
 * Jenkinsfile: CI (Build/Push) + CD GitOps (ArgoCD Integration)
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

                    env.GIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()

                    // Sửa lại logic nhận diện Tag chặt chẽ hơn
                    env.IS_MAIN = (env.BRANCH_NAME_RESOLVED == 'main' || env.BRANCH_NAME_RESOLVED.endsWith('/main')).toString()
                    
                    // Trong Multibranch, khi chạy từ Tag, env.TAG_NAME sẽ có giá trị
                    if (env.TAG_NAME) {
                        env.IS_RELEASE = "true"
                        env.IMAGE_TAG = env.TAG_NAME
                    } else {
                        env.IS_RELEASE = "false"
                        env.IMAGE_TAG = env.IS_MAIN.toBoolean() ? 'latest' : env.GIT_SHA
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

        stage('CD Dev GitOps Update') {
            when { 
                // Có thể đổi thành: branch 'main' nếu muốn giống file tham chiếu
                expression { return env.IS_MAIN.toBoolean() } 
            }
            steps {
                script {
                    echo ">>> Đang cập nhật môi trường DEV với tag: ${env.IMAGE_TAG}"
                    updateGitOpsRepo('dev', env.IMAGE_TAG)
                }
            }
        }

        stage('CD Staging GitOps Update') {
            when { 
                // Sử dụng cú pháp native chuẩn nhất cho Tag
                tag "v*" 
            }
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