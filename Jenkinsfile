pipeline {
    agent any

    tools {
        nodejs 'node-18'
    }

    environment {
        SCANNER_HOME = tool 'SonarQubeScanner'
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_BACKEND = "${ECR_REGISTRY}/amazona-backend"
        ECR_FRONTEND = "${ECR_REGISTRY}/amazona-frontend"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('1 - Checkout') {
            steps {
                checkout scm
            }
        }

        stage('2 - Frontend Tests') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm test -- --watchAll=false --coverage=false --passWithNoTests'
                }
            }
        }

        stage('3 - Backend Tests') {
            steps {
                dir('backend') {
                    sh 'npm ci --legacy-peer-deps'
                    sh 'npm test'
                }
            }
        }

        stage('SonarQube') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Amazona \
                        -Dsonar.projectKey=depi-devops-graduation-project \
                        -Dsonar.sources=frontend/src,backend
                    """
                }
            }
        }

        stage('Build Images') {
            steps {
                sh """
                    docker build -t ${ECR_FRONTEND}:${IMAGE_TAG} ./frontend
                    docker build -t ${ECR_BACKEND}:${IMAGE_TAG} ./backend
                """
             }
        }
        
        stage('Trivy Scan - Frontend') {
            steps {
                sh """
                    trivy image \
                      --severity HIGH,CRITICAL \
                      --exit-code 0 \
                      ${ECR_FRONTEND}:${IMAGE_TAG}
                """
            }
        }

        stage('Trivy Scan - Backend') {
            steps {
                sh """
                    trivy image \
                      --severity HIGH,CRITICAL \
                      --exit-code 0 \
                      ${ECR_BACKEND}:${IMAGE_TAG}
                """
            }
        }

        stage('Push to ECR') {
           steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh """
                        # Login to ECR
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        # Tag 'latest' from the already built image
                        docker tag ${ECR_FRONTEND}:${IMAGE_TAG} ${ECR_FRONTEND}:latest
                        docker tag ${ECR_BACKEND}:${IMAGE_TAG} ${ECR_BACKEND}:latest

                        # Push Frontend
                        docker push ${ECR_FRONTEND}:${IMAGE_TAG}
                        docker push ${ECR_FRONTEND}:latest

                        # Push Backend
                        docker push ${ECR_BACKEND}:${IMAGE_TAG}
                        docker push ${ECR_BACKEND}:latest
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }

        failure {
            echo '❌ Pipeline failed during execution.'
        }

        always {
            archiveArtifacts artifacts: '**/dependency-check-report.*', allowEmptyArchive: true
            echo 'Pipeline execution finished.'
        }
    }
}
