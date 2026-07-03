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
        ECR_BACKEND = "${ECR_REGISTRY}/depi-devops-graduation-project-backend"
        ECR_FRONTEND = "${ECR_REGISTRY}/depi-devops-graduation-project-frontend"
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

        // stage('5 - OWASP Dependency Check') {
        //     steps {
        //         dependencyCheck(
        //             odcInstallation: 'Dependency-Check',
        //             additionalArguments: '--scan . --project "${JOB_NAME}" --format XML --format HTML'
        //         )

        //         dependencyCheckPublisher(
        //             pattern: '**/dependency-check-report.xml'
        //         )
        //     }
        // }
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
