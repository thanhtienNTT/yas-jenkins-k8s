pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        DOCKERHUB_USER        =  'loknee1412'//'thanhtienntt'
        DOCKER_CREDENTIALS_ID = 'dockerhub-creds'
        ALL_SERVICES          = 'order,tax,cart'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Detect branch and commit tag') {
            steps {
                script {
                    env.BRANCH_NAME_RESOLVED = env.BRANCH_NAME ?: env.GIT_BRANCH ?: sh(
                        script: 'git rev-parse --abbrev-ref HEAD',
                        returnStdout: true
                    ).trim()

                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.IS_MAIN = (
                        env.BRANCH_NAME_RESOLVED == 'main' ||
                        env.BRANCH_NAME_RESOLVED == 'origin/main' ||
                        env.BRANCH_NAME_RESOLVED.endsWith('/main')
                    ).toString()

                    env.IMAGE_TAG = env.IS_MAIN.toBoolean() ? 'latest' : env.GIT_SHA

                    echo "BRANCH=${env.BRANCH_NAME_RESOLVED}"
                    echo "GIT_SHA=${env.GIT_SHA}"
                    echo "IS_MAIN=${env.IS_MAIN}"
                    echo "IMAGE_TAG=${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build and Push Services') {
            steps {
                script {
                    def allServices = env.ALL_SERVICES.split(',') as List
                    def servicesToBuild = []

                    if (env.IS_MAIN.toBoolean()) {
                        servicesToBuild = allServices
                    } else {
                        def branchService = env.BRANCH_NAME_RESOLVED
                            .replaceFirst(/^dev_/, '')
                            .replaceFirst(/_service$/, '')

                        if (allServices.contains(branchService)) {
                            servicesToBuild = [branchService]
                        } else {
                            error "Cannot determine service from branch name: ${env.BRANCH_NAME_RESOLVED}"
                        }
                    }

                    echo "SERVICES_TO_BUILD=${servicesToBuild.join(',')}"

                    withCredentials([usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS_ID}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'

                        servicesToBuild.each { svc ->
                            echo "===== BUILD SERVICE: ${svc} ====="

                            sh "mvn -B clean package -pl ${svc} -am -DskipTests"

                            dir("${svc}") {
                                sh "docker build -t ${DOCKERHUB_USER}/${svc}:${IMAGE_TAG} ."
                                sh "docker push ${DOCKERHUB_USER}/${svc}:${IMAGE_TAG}"
                            }
                        }

                        sh 'docker logout || true'
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Build and push completed for branch ${env.BRANCH_NAME_RESOLVED} with tag ${env.IMAGE_TAG}"
        }
        failure {
            echo "Build failed for branch ${env.BRANCH_NAME_RESOLVED}"
        }
        always {
            script {
                def allServices = env.ALL_SERVICES.split(',') as List
                def servicesToClean = []

                if (env.IS_MAIN.toBoolean()) {
                    servicesToClean = allServices
                } else {
                    def branchService = env.BRANCH_NAME_RESOLVED
                        .replaceFirst(/^dev_/, '')
                        .replaceFirst(/_service$/, '')

                    if (allServices.contains(branchService)) {
                        servicesToClean = [branchService]
                    }
                }

                servicesToClean.each { svc ->
                    sh "docker image rm -f ${DOCKERHUB_USER}/${svc}:${IMAGE_TAG} || true"
                }
            }
            cleanWs()
        }
    }
}