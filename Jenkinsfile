pipeline {
    agent any
    
    environment {
        // Set Python version (adjust as needed)
        PYTHON = 'python3'
        // Add deployment environment variables
        DEPLOY_ENV = 'production'
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Checkout code from SCM
                checkout scm
                
                // Print Python and pip versions for debugging
                sh '${PYTHON} --version'
                sh '${PYTHON} -m pip --version'
            }
        }
        
        stage('Setup Virtual Environment') {
            steps {
                // Create and activate virtual environment
                sh '''
                    ${PYTHON} -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install setuptools wheel
                    pip install -r requirements.txt
                '''
            }
        }
        
        stage('Lint') {
            steps {
                // Run linter (add more linters as needed)
                sh '''
                    . venv/bin/activate
                    pip install flake8
                    flake8 calculator/ tests/ --count --select=E9,F63,F7,F82 --show-source --statistics
                    flake8 calculator/ tests/ --count --max-complexity=10 --max-line-length=127 --statistics
                '''
            }
        }
        
        stage('Test') {
            steps {
                // Run tests with coverage and JUnit XML
                sh '''
                    . venv/bin/activate
                    python -m pytest tests/ --cov=calculator --cov-report=xml --cov-report=html --cov-report=term --junitxml=test-results.xml
                '''
            }
            
            post {
                always {
                    // Publish test results
                    junit 'test-results.xml'
                    
                    // Archive coverage report (alternative to HTML publishing)
                    archiveArtifacts artifacts: 'htmlcov/**/*', allowEmptyArchive: true
                }
            }
        }
        
        stage('Build Package') {
            steps {
                // Build a source distribution
                sh '''
                    . venv/bin/activate
                    python setup.py sdist bdist_wheel
                '''
                
                // Archive the artifacts
                archiveArtifacts artifacts: 'dist/*', allowEmptyArchive: true
            }
        }
        
        stage('Security Scan') {
            steps {
                // Run security scan (optional)
                sh '''
                    . venv/bin/activate
                    pip install safety
                    safety check --json --output safety-report.json || true
                '''
            }
            post {
                always {
                    // Archive security report
                    archiveArtifacts artifacts: 'safety-report.json', allowEmptyArchive: true
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'  // Only deploy from main branch
            }
            steps {
                script {
                    // Deploy to production
                    echo "Deploying to ${DEPLOY_ENV} environment..."
                    
                    // Run the deployment script
                    sh '''
                        . venv/bin/activate
                        chmod +x deploy.sh
                        sudo ./deploy.sh
                        echo "Deployment completed successfully!"
                        echo "Environment: ${DEPLOY_ENV}"
                        echo "Build Number: ${BUILD_NUMBER}"
                        echo "Git Commit: ${GIT_COMMIT}"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Clean up workspace
            cleanWs()
        }
        
        success {
            // Notify on success (e.g., email, Slack, etc.)
            echo 'Pipeline completed successfully!'
            
            // Send success notification
            script {
                // Add your notification logic here
                // Example: Slack notification, email, etc.
                echo "Build #${BUILD_NUMBER} completed successfully!"
            }
        }
        
        failure {
            // Notify on failure
            echo 'Pipeline failed!'
            
            // Send failure notification
            script {
                // Add your notification logic here
                echo "Build #${BUILD_NUMBER} failed!"
            }
        }
        
        unstable {
            // Handle unstable builds
            echo 'Pipeline is unstable!'
        }
    }
}
