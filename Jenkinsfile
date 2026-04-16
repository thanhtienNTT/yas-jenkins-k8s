pipeline {
    agent { label 'build' }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        DOCKERHUB_USER        = 'thanhtienntt'
        DOCKER_CREDENTIALS_ID = 'dockerhub-creds'
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
                    def services = [
                        'order',
                        'tax',
                        'cart'
                    ]

                    withCredentials([usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS_ID}",
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'

                        services.each { svc ->
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
                def services = [
                    'order',
                    'tax',
                    'cart'
                ]

                services.each { svc ->
                    sh "docker image rm -f ${DOCKERHUB_USER}/${svc}:${IMAGE_TAG} || true"
                }
            }
            cleanWs()
        }
    }
}