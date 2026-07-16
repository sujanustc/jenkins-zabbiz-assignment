pipeline {
    agent any

    environment {
        DOCKER_HUB_USER = 'dasujandb'
        DOCKER_HUB_REPO = 'node-express-app'
        IMAGE_NAME = "${DOCKER_HUB_USER}/${DOCKER_HUB_REPO}"
        PORT = '3000'
        // 'docker-hub-credentials' is the ID of the username/password credential stored in Jenkins
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing application dependencies...'
                dir('app') {
                    sh 'npm install'
                }
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running unit tests...'
                dir('app') {
                    sh 'npm test'
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                echo 'Building Docker image...'
                dir('app') {
                    sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} -t ${IMAGE_NAME}:latest ."
                }
                
                echo 'Pushing Docker image to Docker Hub...'
                // Using Jenkins credentials wrapper to securely log in
                withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    sh "docker push ${IMAGE_NAME}:${BUILD_NUMBER}"
                    sh "docker push ${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Deploy Application') {
            steps {
                echo 'Deploying Docker container locally...'
                sh """
                    # Stop and remove existing container if running
                    if [ \$(docker ps -aq -f name=node-app) ]; then
                        echo "Stopping and removing existing container..."
                        docker stop node-app
                        docker rm node-app
                    fi
                    
                    # Run the newly built container
                    docker run -d --name node-app -p ${PORT}:${PORT} ${IMAGE_NAME}:latest
                    
                    echo "Application is deployed and running on port ${PORT}!"
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully! Build #${BUILD_NUMBER} is live."
        }
        failure {
            echo "Pipeline failed on Build #${BUILD_NUMBER}. Please check the console output logs."
        }
    }
}
