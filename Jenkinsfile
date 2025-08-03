pipeline {
    agent any
    
    environment {
        // Set Python version (adjust as needed)
        PYTHON = 'python3'
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
                // Run tests with coverage
                sh '''
                    . venv/bin/activate
                    python -m pytest tests/ --cov=calculator --cov-report=xml --cov-report=term
                '''
            }
            
            post {
                always {
                    // Publish test results
                    junit '**/test-results/*.xml'
                    
                    // Publish coverage report
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: 'htmlcov',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report',
                        reportTitles: 'Code Coverage Report'
                    ])
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
    }
    
    post {
        always {
            // Clean up workspace
            cleanWs()
        }
        
        success {
            // Notify on success (e.g., email, Slack, etc.)
            echo 'Pipeline completed successfully!'
        }
        
        failure {
            // Notify on failure
            echo 'Pipeline failed!'
        }
    }
}
