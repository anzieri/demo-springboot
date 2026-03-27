pipeline {
    agent any

    environment {
        DOCKER_USER = "anzieri"
        DOCKER_CREDS = credentials('docker-hub-credentials-id')
    }

    stages {
        stage('Build & Test') {
            agent {
                docker { image 'maven:3-eclipse-temurin-21-jammy' }
            }
            steps {
                sh 'mvn clean compile'
                sh "mvn help:evaluate -Dexpression=project.version -q -DforceStdout | cut -d'-' -f1 > version.txt"
                sh 'mvn test -Dspring.profiles.active=test'
                sh 'mvn package -DskipTests'
                stash includes: 'target/*.jar, version.txt', name: 'app-binaries'
            }
            
        }

        stage('Dockerize') {
            agent any
            steps {
                unstash 'app-binaries'
                script {
                    def baseVersion = readFile('version.txt').trim()
                    def fullVersion = "${baseVersion}.${env.BUILD_NUMBER}"
                    sh "echo ${DOCKER_CREDS_PSW} | docker login -u ${DOCKER_CREDS_USR} --password-stdin"
                    sh "docker build -t ${DOCKER_USER}/${env.JOB_BASE_NAME}:${fullVersion} ."
                    sh "docker push ${DOCKER_USER}/${env.JOB_BASE_NAME}:${fullVersion}"
                }
            }
        }
    }
}