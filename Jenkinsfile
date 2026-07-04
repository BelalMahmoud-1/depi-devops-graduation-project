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

        stage('2 - Run Tests in Parallel') {
            parallel {
                stage('Frontend Tests') {
                    steps {
                        dir('frontend') {
                            sh 'npm install'
                            sh 'npm test -- --watchAll=false --coverage=false --passWithNoTests'
                        }
                    }
                }
                stage('Backend Tests') {
                    steps {
                        dir('backend') {
                            sh 'npm ci --legacy-peer-deps'
                            sh 'npm test'
                        }
                    }
                }
            }
        }

        stage('3 - SonarQube Code Analysis') {
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

        stage('4 - Build Docker Images') {
            steps {
                sh """
                    docker build -t ${ECR_FRONTEND}:${IMAGE_TAG} ./frontend
                    docker build -t ${ECR_BACKEND}:${IMAGE_TAG} ./backend
                """
             }
        }
        
        stage('5 - Trivy Security Scan') {
            parallel {
                stage('Scan Frontend') {
                    steps {
                        sh """
                            trivy image --severity HIGH,CRITICAL --exit-code 0 ${ECR_FRONTEND}:${IMAGE_TAG}
                        """
                    }
                }
                stage('Scan Backend') {
                    steps {
                        sh """
                            trivy image --severity HIGH,CRITICAL --exit-code 0 ${ECR_BACKEND}:${IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('6 - Push to AWS ECR') {
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

                        # Tag 'latest'
                        docker tag ${ECR_FRONTEND}:${IMAGE_TAG} ${ECR_FRONTEND}:latest
                        docker tag ${ECR_BACKEND}:${IMAGE_TAG} ${ECR_BACKEND}:latest

                        # Push Images
                        docker push ${ECR_FRONTEND}:${IMAGE_TAG}
                        docker push ${ECR_FRONTEND}:latest
                        docker push ${ECR_BACKEND}:${IMAGE_TAG}
                        docker push ${ECR_BACKEND}:latest
                    """
                }
            }
        }

        stage('7 - Deploy to EKS') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh """
                        export KUBECONFIG=\$HOME/.kube/config

                        aws eks update-kubeconfig \
                          --region ${AWS_REGION} \
                          --name amazona-dev-cluster

                        kubectl rollout restart deployment/backend
                        kubectl rollout restart deployment/frontend
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
            slackSend(
                channel: '#amazona-pipeline',
                color: 'good',
                message: "✅ Build Success: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]"
            )
        }

        failure {
            echo '❌ Pipeline failed during execution.'
            slackSend(
                channel: '#amazona-pipeline',
                color: 'danger',
                message: "❌ Build Failed: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]"
            )
        }
    }
}
