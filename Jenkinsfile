pipeline {
    agent any
    environment {
            DOCKER_USER = "anzieri"
            DOCKER_CREDS = credentials('docker-hub-credentials-id')
            // Force lowercase repo name for Docker Hub compatibility
            REPO_NAME = "${env.JOB_BASE_NAME}".toLowerCase()
    }

    stages {
        stage('Build') {
            agent { image 'maven:3-eclipse-temurin-21-jammy' }
            steps {
                sh 'mvn clean compile'
                // Extract version
                sh "mvn help:evaluate -Dexpression=project.version -q -DforceStdout | cut -d'-' -f1 > version.txt"
                stash includes: 'target/**, version.txt', name: 'build-artifacts'
            }
        }

        stage('Test') {
            agent { image 'maven:3-eclipse-temurin-21-jammy' }
            steps {
                unstash 'build-artifacts'
                sh 'mvn test -Dspring.profiles.active=test'
            }
        }

        stage('Package') {
            agent { image 'maven:3-eclipse-temurin-21-jammy' }
            steps {
                unstash 'build-artifacts'
                sh 'mvn package -DskipTests'
                stash includes: 'target/*.jar, version.txt', name: 'final-jar'
            }
        }

        stage('Dockerize') {
            steps {
                unstash 'final-jar'
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
            sh 'docker system prune -af'
        }
    }
}