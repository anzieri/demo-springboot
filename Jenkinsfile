pipeline {
    agent any // Main agent that stays active

    environment {
        DOCKER_USER = "anzieri"
        DOCKER_CREDS = credentials('docker-hub-credentials-id')
        // Force lowercase repo name for Docker Hub compatibility
        REPO_NAME = "${env.JOB_BASE_NAME}".toLowerCase()
    }

    stages {
        stage('Build & Test') {
            agent {
                docker {
                    image 'maven:3-eclipse-temurin-21-jammy'
                    // Reuse the same workspace to avoid missing files
                    reuseNode true
                }
            }
            steps {
                sh 'mvn clean compile'
                sh "mvn help:evaluate -Dexpression=project.version -q -DforceStdout | cut -d'-' -f1 > version.txt"
                sh 'mvn test -Dspring.profiles.active=test'
                sh 'mvn package -DskipTests'

                // CRITICAL: Include the Dockerfile in your stash!
                stash includes: 'target/*.jar, version.txt, Dockerfile', name: 'app-binaries'
            }
        }

        stage('Dockerize') {
            steps {
                unstash 'app-binaries'
                script {
                    def baseVersion = readFile('version.txt').trim()
                    def fullVersion = "${baseVersion}.${env.BUILD_NUMBER}"

                    sh "echo ${DOCKER_CREDS_PSW} | docker login -u ${DOCKER_CREDS_USR} --password-stdin"

                    sh "docker build -t ${DOCKER_USER}/${REPO_NAME}:${fullVersion} ."
                    sh "docker tag ${DOCKER_USER}/${REPO_NAME}:${fullVersion} ${DOCKER_USER}/${REPO_NAME}:latest"

                    sh "docker push ${DOCKER_USER}/${REPO_NAME}:${fullVersion}"
                    sh "docker push ${DOCKER_USER}/${REPO_NAME}:latest"
                }
            }
        }
    }

    post {
        always {
            // Keep your Pi clean!
            sh 'docker system prune -f'
        }
    }
}