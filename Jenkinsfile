
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
    }

    post {
        success {
            echo 'Maven build, tests and SonarQube analysis completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check Jenkins console output.'
        }
    }
}
