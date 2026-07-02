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

        stage('4 - SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'chmod +x scripts/sonar-scan.sh && scripts/sonar-scan.sh'
                }
            }
        }

        stage('5 - OWASP Dependency Check') {
            steps {
                dependencyCheck(
                    odcInstallation: 'Dependency-Check',
                    additionalArguments: '--scan . --project "${JOB_NAME}" --format XML --format HTML'
                )

                dependencyCheckPublisher(
                    pattern: '**/dependency-check-report.xml'
                )
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
