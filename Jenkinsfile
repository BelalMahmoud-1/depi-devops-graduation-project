pipeline {
    agent any
      tools {
        nodejs 'node-18'
    }

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

        stage('2 - Frontend Install&Tests') {
            steps {
                dir('Frontend') {
                    sh 'npm install --force'
                    sh 'npm test -- --watchAll=false --passWithNoTests'
                }
            }
        }

  

        stage('4 - Build Frontend') {
            steps {
                sh 'npm run build --prefix Frontend'
            }
        }

        stage('5 - Build Backend') {
            steps {
                sh 'npm run build --prefix Backend'
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed during execution."
        }
    }
}
