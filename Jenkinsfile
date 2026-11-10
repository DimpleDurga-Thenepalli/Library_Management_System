
pipeline {
    agent any

    tools {
        maven 'Maven-3'
    }

    stages {

        // STAGE 1: Environment Check
        stage('Environment Check') {
            steps {
                sh '''
                    echo "Checking Java and Maven"
                    java -version
                    mvn -version
                '''
            }
        }

        // STAGE 2: Java Backend Build and Unit Tests
        stage('Backend Build') {
            steps {
                dir('backend') {
                    sh '''
                        echo "Building and testing Spring Boot backend"
                        mvn clean package
                    '''
                }

                stash name: 'docker-context',
                      includes: 'backend/Dockerfile,backend/.dockerignore,backend/target/library-1.0.0.jar'
            }
        }

        // STAGE 3: React Frontend Build
        stage('Frontend Build') {
            agent {
                label 'docker-agent'
            }

            steps {
                dir('frontend') {
                    sh '''
                        echo "Building React frontend using Node.js and Vite"
                        docker build --target build --progress=plain .
                    '''
                }
            }
        }

        // STAGE 4: SonarQube Analysis - Backend and Frontend
        // FIX: Make Node.js available to SonarQube for React analysis
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    withSonarQubeEnv('SonarQube') {
                        nodejs(nodeJSInstallationName: 'NodeJS') {
                            sh """
                                echo "Checking Node.js availability"
                                node --version
                                npm --version

                                echo "Analyzing Java backend and React frontend"
                                "${scannerHome}/bin/sonar-scanner"
                            """
                        }
                    }
                }
            }
        }

        // STAGE 5: Backend Docker Image
        stage('Backend Docker Build') {
            agent {
                label 'docker-agent'
            }

            steps {
                unstash 'docker-context'

                dir('backend') {
                    sh '''
                        echo "Building backend Docker image"
                        docker build -t library-management:${BUILD_NUMBER} .
                    '''
                }
            }
        }

        // STAGE 6: Frontend Docker Image
        stage('Frontend Docker Build') {
            agent {
                label 'docker-agent'
            }

            steps {
                dir('frontend') {
                    sh '''
                        echo "Building frontend Docker image"
                        docker build -t library-management-frontend:${BUILD_NUMBER} .
                    '''
                }
            }
        }

        // STAGE 7: Trivy Security Scanning
        stage('Trivy Scan') {
            agent {
                label 'docker-agent'
            }

            steps {
                sh '''
                    echo "Scanning backend Docker image"

                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      -v trivy-cache:/root/.cache/ \
                      aquasec/trivy:0.76.2 image \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      --timeout 15m \
                      library-management:${BUILD_NUMBER}

                    echo "Backend Trivy scan passed"

                    echo "Scanning frontend Docker image"

                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      -v trivy-cache:/root/.cache/ \
                      aquasec/trivy:0.76.2 image \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      --timeout 15m \
                      library-management-frontend:${BUILD_NUMBER}

                    echo "Frontend Trivy scan passed"
                '''
            }
        }

        // STAGE 8: Push Backend and Frontend Images to Harbor
        stage('Harbor Push') {
            agent {
                label 'docker-agent'
            }

            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'harbor-credentials',
                        usernameVariable: 'HARBOR_USER',
                        passwordVariable: 'HARBOR_PASS'
                    )
                ]) {
                    sh '''
                        set -e

                        REGISTRY="host.docker.internal:8082"
                        PROJECT="usecase1"

                        echo "Logging in to Harbor"
                        printf '%s' "$HARBOR_PASS" | docker login "$REGISTRY" \
                          --username "$HARBOR_USER" \
                          --password-stdin

                        echo "Tagging backend image"
                        docker tag library-management:${BUILD_NUMBER} \
                          "$REGISTRY/$PROJECT/library-management:${BUILD_NUMBER}"

                        echo "Tagging frontend image"
                        docker tag library-management-frontend:${BUILD_NUMBER} \
                          "$REGISTRY/$PROJECT/library-management-frontend:${BUILD_NUMBER}"

                        echo "Pushing backend image to Harbor"
                        docker push "$REGISTRY/$PROJECT/library-management:${BUILD_NUMBER}"

                        echo "Pushing frontend image to Harbor"
                        docker push "$REGISTRY/$PROJECT/library-management-frontend:${BUILD_NUMBER}"

                        echo "Both Docker images pushed successfully"
                        docker logout "$REGISTRY"
                    '''
                }
            }
        }

    }

    post {
        success {
            echo 'Use Case 1 completed successfully.'
        }

        failure {
            echo 'Use Case 1 failed. Check the first failed stage.'
        }
    }
}
