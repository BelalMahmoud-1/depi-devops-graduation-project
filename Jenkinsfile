pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "${BUILD_ID}"
    }

    stages {
        stage('1 - Checkout') {
            steps {
                checkout scm
            }
        }

        stage('2 - Frontend Tests') {
            steps {
                dir('Frontend') {
                    sh 'npm install'
                    sh 'npm test -- --watchAll=false'
                }
            }
        }

        stage('3 - Backend Tests') {
            steps {
                dir('Backend') {
                    sh 'npm install'
                    sh 'npm test'
                }
            }
        }

        stage('4 - Build Frontend') {
            steps {
                sh 'echo "Building Frontend..."'
                sh 'npm run build --prefix Frontend'
            }
        }

        stage('5 - Build Backend') {
            steps {
                sh 'echo "Building Backend..."'
                sh 'npm run build --prefix Backend'
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        
        failure {
            echo "❌ Pipeline failed during execution. Check the console log above for errors."
        }
    }
}
