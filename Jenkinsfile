pipeline {
    agent any
    tools {
        nodejs 'node-18'
    }
    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '608645726975'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "${BUILD_ID}"
        NPM_CONFIG_LEGACY_PEER_DEPS = 'true'
        
    }
    stages {
        stage('1 - Checkout') {
            steps {
                checkout scm
            }
        }
        stage('2 - Frontend Install & Tests') {
            steps {
                dir('frontend') {
                    sh 'npm install --legacy-peer-deps'
                    sh 'npm test -- --watchAll=false --passWithNoTests'
                }
            }
        }
        stage('3 - Backend Install & Tests') {
            steps {
                dir('backend') {
                    sh 'npm install --legacy-peer-deps'
                    sh 'npm test -- --passWithNoTests'
                }
            }
        }
        stage('4 - Build Frontend') {
            steps {
                sh 'npm run build --prefix frontend'
            }
        }
        stage('5 - Build Backend') {
            steps {
                sh 'npm run build --prefix backend'
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
