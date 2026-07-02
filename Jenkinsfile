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

        stage('Frontend Tests') {
            steps {
                dir('Frontend') {
                    sh 'npm ci'
                    sh 'npm test -- --watchAll=false --coverage=false'
                }
            }
        }

        stage('Backend Tests') {
            steps {
                dir('Backend') {
                    sh 'npm ci'
                    sh 'npm test'
                }
            }
        }
    }   // ← كان ناقص

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed during execution."
        }
    }
}
        failure {
            echo "❌ Pipeline failed during execution."
        }
    }
}
