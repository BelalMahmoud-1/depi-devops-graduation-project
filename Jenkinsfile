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
                    sh '''
                        set -e

                        if ! command -v sonar-scanner >/dev/null 2>&1; then
                            SCANNER_VERSION=6.2.1.4610
                            curl -sSLo sonar-scanner-cli.zip \
                                "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SCANNER_VERSION}-linux-x64.zip"
                            unzip -qo sonar-scanner-cli.zip
                            export PATH="$PWD/sonar-scanner-${SCANNER_VERSION}-linux-x64/bin:$PATH"
                        fi

                        sonar-scanner \
                          -Dsonar.projectKey=depi-devops-graduation-project \
                          -Dsonar.projectName=depi-devops-graduation-project \
                          -Dsonar.sources=frontend/src,backend \
                          -Dsonar.exclusions=**/node_modules/**,**/build/**,**/uploads/** \
                          -Dsonar.sourceEncoding=UTF-8
                    '''
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
