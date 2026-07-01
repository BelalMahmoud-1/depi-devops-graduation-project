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

        /* stage('SonarQube Scan') {
            steps {
                sh 'echo "Running SonarQube scan..."'
                // sh 'sonar-scanner'
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                sh 'echo "Running OWASP Dependency Check..."'
                // sh 'docker run --rm -v $PWD:/src owasp/dependency-check:latest --scan /src'
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh "docker build -t ${ECR_REGISTRY}/frontend:${IMAGE_TAG} Frontend"
            }
        }

        stage('Build Backend Image') {
            steps {
                sh "docker build -t ${ECR_REGISTRY}/backend:${IMAGE_TAG} Backend"
            }
        }

        stage('Trivy Scan - Frontend') {
            steps {
                sh "docker run --rm aquasec/trivy:latest image ${ECR_REGISTRY}/frontend:${IMAGE_TAG} || true"
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY'
                    sh 'aws ecr create-repository --repository-name frontend --region $AWS_REGION || true'
                    sh 'aws ecr create-repository --repository-name backend --region $AWS_REGION || true'
                    sh "docker push ${ECR_REGISTRY}/frontend:${IMAGE_TAG}"
                    sh "docker push ${ECR_REGISTRY}/backend:${IMAGE_TAG}"
                }
            }
        }

        stage('Update Kubernetes Manifests') {
            steps {
                sh "sed -i 's|image:.*frontend.*|image: ${ECR_REGISTRY}/frontend:${IMAGE_TAG}|' k8s/frontend-deployment.yaml"
                sh "sed -i 's|image:.*backend.*|image: ${ECR_REGISTRY}/backend:${IMAGE_TAG}|' k8s/backend-deployment.yaml"
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh 'kubectl apply -f k8s/'
                sh 'kubectl rollout status deployment/frontend -n default'
                sh 'kubectl rollout status deployment/backend -n default'
            }
        }

        stage('Slack Notification') {
            steps {
                sh '''
                    curl -X POST -H 'Content-type: application/json' \
                    --data "{\"text\": \"✅ Deployment succeeded: ${JOB_NAME} #${BUILD_NUMBER}\"}" \
                    $SLACK_WEBHOOK || true
                '''
            }
        }
        */
    }

    post {
        always {
            echo "Pipeline finished"
        }

        failure {
            script {
                node {
                    sh """
                        curl -X POST -H 'Content-type: application/json' \
                        --data '{"text":"❌ Pipeline failed: ${JOB_NAME} #${BUILD_NUMBER}"}' \
                        ${SLACK_WEBHOOK} || true
                    """
                }
            }
        }
    }
}
