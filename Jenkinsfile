
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

            echo "Scanning frontend Docker image"

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


        stage('SonarQube Analysis') {
            steps {
                dir('backend') {
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            mvn org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                              -Dsonar.projectKey=Library-Management-System \
                              -Dsonar.projectName=Library-Management-System
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
    }

    post {
        success {
            echo 'Backend and frontend builds completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check Jenkins console output.'
        }
    }
}
