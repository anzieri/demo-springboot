pipeline {
    agent any

    environment {
        DOCKER_USER = "anzieri"
        DOCKER_CREDS = credentials('docker-hub-credentials-id')
        REPO_NAME = "${env.JOB_BASE_NAME}".toLowerCase()
        // Define this so the script knows what DOCKER_IMAGE is
        DOCKER_IMAGE = "${DOCKER_USER}/${REPO_NAME}"
    }

    stages {
        stage('Build & Test') {
            agent {
                docker {
                    image 'maven:3-eclipse-temurin-21-jammy'
                    reuseNode true // Essential to keep the workspace/Dockerfile visible
                }
            }
            steps {
                // No 'tools' block needed! The image already has mvn.
                sh 'mvn clean package -DskipTests'
                sh "mvn help:evaluate -Dexpression=project.version -q -DforceStdout | cut -d'-' -f1 > version.txt"

                // Stash the JAR, the version, AND the Dockerfile
                stash includes: 'target/*.jar, version.txt, Dockerfile', name: 'app-artifacts'
            }
        }

        stage('Dockerize') {
            steps {
                unstash 'app-artifacts'
                script {
                    def baseVersion = readFile('version.txt').trim()
                    def fullVersion = "${baseVersion}.${env.BUILD_NUMBER}"

                    sh "echo ${DOCKER_CREDS_PSW} | docker login -u ${DOCKER_CREDS_USR} --password-stdin"
                    sh "docker build -t ${DOCKER_IMAGE}:${fullVersion} ."
                    sh "docker tag ${DOCKER_IMAGE}:${fullVersion} ${DOCKER_IMAGE}:latest"
                    sh "docker push ${DOCKER_IMAGE}:${fullVersion}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f'
        }
    }
}