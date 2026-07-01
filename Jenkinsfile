pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "${BUILD_ID}"
        SLACK_WEBHOOK = credentials('slack-webhook')
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
        always {
            echo "Pipeline finished"
        }

        failure {
            // Using single quotes prevents Groovy parsing errors and reads directly from env
            sh '''
                curl -X POST -H 'Content-type: application/json' \
                --data "{\\"text\\":\\"❌ Pipeline failed: ${JOB_NAME} #${BUILD_NUMBER}\\"}" \
                $SLACK_WEBHOOK || true
            '''
        }
    }
}
