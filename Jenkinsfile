
pipeline {
    agent any

    tools {
        maven 'Maven-3'
    }

    stages {
        stage('Environment Check') {
            steps {
                sh '''
                    java -version
                    mvn -version
                '''
            }
        }

        stage('Backend Build') {
            steps {
                dir('backend') {
                    sh 'mvn clean package'
                }

                stash name: 'docker-context',
                      includes: 'backend/Dockerfile,backend/.dockerignore,backend/target/library-1.0.0.jar'
            }
        }

        stage('Frontend Build') {
            agent {
                label 'docker-agent'
            }

            steps {
                dir('frontend') {
                    sh 'docker build --target build --progress=plain .'
                }
            }
        }

        
stage('SonarQube Analysis') {
    steps {
        dir('backend') {
            withSonarQubeEnv('SonarQube') {
                sh '''
                    mvn org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                      -Dsonar.projectKey=Library-Management-System \
                      -Dsonar.projectName=Library-Management-System \
                      -Dsonar.projectBaseDir=.. \
                      -Dsonar.sources=backend/src/main/java,frontend/src \
                      -Dsonar.tests=backend/src/test/java \
                      -Dsonar.java.binaries=backend/target/classes \
                      -Dsonar.exclusions=**/node_modules/**,**/dist/** \
                      -Dsonar.sourceEncoding=UTF-8
                '''
            }
        }
    }
}


        stage('Backend Docker Build') {
            agent {
                label 'docker-agent'
            }

            steps {
                unstash 'docker-context'

                dir('backend') {
                    sh 'docker build -t library-management:${BUILD_NUMBER} .'
                }
            }
        }

        stage('Frontend Docker Build') {
            agent {
                label 'docker-agent'
            }

            steps {
                dir('frontend') {
                    sh 'docker build -t library-management-frontend:${BUILD_NUMBER} .'
                }
            }
        }

        stage('Trivy Scan') {
            agent {
                label 'docker-agent'
            }

            steps {
                sh '''
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      -v trivy-cache:/root/.cache/ \
                      aquasec/trivy:0.76.2 image \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      --timeout 15m \
                      library-management:${BUILD_NUMBER}

                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      -v trivy-cache:/root/.cache/ \
                      aquasec/trivy:0.76.2 image \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      --timeout 15m \
                      library-management-frontend:${BUILD_NUMBER}
                '''
            }
        }
    }

    post {
        success {
            echo 'Backend, frontend, SonarQube, Docker and Trivy stages passed!'
        }

        failure {
            echo 'Pipeline failed. Check Jenkins Console Output.'
        }
    }
}
