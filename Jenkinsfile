
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

        stage('Maven Build and Test') {
            steps {
                dir('backend') {
                    sh 'mvn clean package'
                }

                stash name: 'docker-context',
                      includes: 'backend/Dockerfile,backend/.dockerignore,backend/target/library-1.0.0.jar'
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

        stage('Docker Build') {
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
    }

    post {
        success {
            echo 'Pipeline stages completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check Jenkins console output.'
        }
    }
}
