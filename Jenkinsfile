
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
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    withSonarQubeEnv('SonarQube') {
                        sh """
                            echo "Analyzing Java backend and React frontend"
                            "${scannerHome}/bin/sonar-scanner"
                        """
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
    }

    post {
        success {
            echo 'SUCCESS: Backend build, frontend build, SonarQube, Docker images and Trivy scans passed!'
        }

        failure {
            echo 'FAILURE: Check the first failed stage in Jenkins Console Output.'
        }
    }
}
