
pipeline {
    agent any

    tools {
        maven 'Maven-3'
    }

    stages {
        stage('Environment Check') {
            steps {
                sh 'java -version'
                sh 'mvn -version'
            }
        }

        stage('Maven Build and Test') {
            steps {
                dir('backend') {
                    sh 'mvn clean package'
                }
            }
        }
    }

    post {
        success {
            echo 'Java build and tests completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check the Jenkins console output.'
        }
    }
}
