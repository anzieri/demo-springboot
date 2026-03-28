pipeline {
    agent any

    environment {
        DOCKER_USER = "anzieri"
        DOCKER_PAT = credentials('DOCKER_PAT')
        REPO_NAME = "${env.JOB_BASE_NAME}".toLowerCase()
        DOCKER_IMAGE = "${DOCKER_USER}/${REPO_NAME}"
    }

    stages {
        stage('Build & Test') {
            agent {
                docker {
                    image 'maven:3-eclipse-temurin-21-jammy'
                    reuseNode true
                }
            }
            steps {
                // Pointing Maven to a local folder in the workspace to avoid permission errors
                script {
                    def mvnFlags = "-Dmaven.repo.local=${WORKSPACE}/.m2/repository"
                    sh "mvn ${mvnFlags} clean compile"
                    sh "mvn ${mvnFlags} help:evaluate -Dexpression=project.version -q -DforceStdout | cut -d'-' -f1 > version.txt"
                    sh "mvn ${mvnFlags} test -Dspring.profiles.active=test"
                    sh "mvn ${mvnFlags} package -DskipTests"
                }

                stash includes: 'target/*.jar, version.txt, Dockerfile', name: 'app-binaries'
            }
        }

        stage('Dockerize') {
            steps {
                unstash 'app-binaries' // Synced with the stash name above
                script {
                    def baseVersion = readFile('version.txt').trim()
                    def fullVersion = "${baseVersion}.${env.BUILD_NUMBER}"

                    // Login and Build
                    sh "echo ${DOCKER_PAT} | docker login -u ${DOCKER_USER} --password-stdin"
                    sh "docker build -t ${DOCKER_IMAGE}:${fullVersion} ."

                    // --- SMOKE TEST ---
                    // Running the container temporarily to verify health
                    sh "docker run -d -p 8082:8082 -p 8083:8083 --name test-container ${DOCKER_IMAGE}:${fullVersion}"

                    // Give Spring Boot a moment to start (10s is usually enough for a Pi 5)
                    sh "sleep 15"

                    try {
                        // Check health on the HOST port (8081)
                        sh "curl -f http://localhost:8083/actuator/health"
                        echo "Health check passed!"
                    } catch (Exception e) {
                        sh "docker logs test-container"
                        error "Health check failed. Check the logs above."
                    } finally {
                        sh "docker rm -f test-container"
                    }

                    // Tag and Push only if the health check passed
                    sh "docker tag ${DOCKER_IMAGE}:${fullVersion} ${DOCKER_IMAGE}:latest"
                    sh "docker push ${DOCKER_IMAGE}:${fullVersion}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }
    }

    post {
        always {
            // Clean up dangling images to save your Pi's SSD
            sh 'docker system prune -f'
        }
    }
}