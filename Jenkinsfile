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

                    echo "BRANCH=${env.BRANCH_NAME_RESOLVED}"
                    echo "GIT_SHA=${env.GIT_SHA}"
                    echo "IS_MAIN=${env.IS_MAIN}"
                }
            }
        }

        stage('Build and Push Services') {
            steps {
                script {
                    // SỬA danh sách này đúng theo repo của bạn
                    def services = [
                        'order',
                        'tax',
                        'cart',
                        'product',
                        'customer',
                        'inventory',
                        'location',
                        'rating',
                        'search'
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
                                sh "docker build -t ${DOCKERHUB_USER}/${svc}:${GIT_SHA} ."

                                if (env.IS_MAIN.toBoolean()) {
                                    sh "docker tag ${DOCKERHUB_USER}/${svc}:${GIT_SHA} ${DOCKERHUB_USER}/${svc}:main"
                                }

                                sh "docker push ${DOCKERHUB_USER}/${svc}:${GIT_SHA}"

                                if (env.IS_MAIN.toBoolean()) {
                                    sh "docker push ${DOCKERHUB_USER}/${svc}:main"
                                }
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
            echo "Build and push completed for branch ${env.BRANCH_NAME_RESOLVED} with tag ${env.GIT_SHA}"
        }
        failure {
            echo "Build failed for branch ${env.BRANCH_NAME_RESOLVED}"
        }
        always {
            script {
                def services = [
                    'order',
                    'tax',
                    'cart',
                    'product',
                    'customer',
                    'inventory',
                    'location',
                    'rating',
                    'search'
                ]

                services.each { svc ->
                    sh "docker image rm -f ${DOCKERHUB_USER}/${svc}:${GIT_SHA} || true"
                    sh "docker image rm -f ${DOCKERHUB_USER}/${svc}:main || true"
                }
            }
            cleanWs()
        }
    }
}