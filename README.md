# Jenkins CI/CD Lab - Simple Calculator

A demonstration project showcasing Jenkins CI/CD pipeline with a simple calculator implementation in Python.

## Features

- Basic arithmetic operations (add, subtract, multiply, divide)
- Comprehensive unit tests with pytest
- Code coverage reporting
- Ready for Jenkins CI/CD pipeline integration
- Python package structure

## Prerequisites

- Python 3.7+
- pip (Python package manager)
- Git
- (Optional) Jenkins for CI/CD pipeline

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/mayusuf/jenkins-ci-cd-lab.git
   cd jenkins-ci-cd-lab
   ```

2. Create and activate a virtual environment:
   ```bash
   # On macOS/Linux
   python3 -m venv venv
   source venv/bin/activate
   
   # On Windows
   python -m venv venv
   venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Running Tests

Run all tests:
```bash
pytest
```

Run tests with coverage report:
```bash
pytest --cov=calculator tests/
```

Generate HTML coverage report:
```bash
pytest --cov=calculator --cov-report=html tests/
open htmlcov/index.html  # On macOS
```

## Project Structure

```
jenkins-ci-cd-lab/
├── calculator/           # Main package
│   ├── __init__.py      # Package initialization
│   └── operations.py    # Calculator operations
├── tests/               # Test package
│   ├── __init__.py      # Test package initialization
│   └── test_operations.py  # Test cases
├── .gitignore           # Git ignore file
├── README.md            # This file
└── requirements.txt     # Project dependencies
```

## Jenkins Integration

To set up this project in Jenkins:

1. Create a new Jenkins pipeline job
2. Configure the pipeline to use the `Jenkinsfile` (to be added)
3. Set up webhooks for automatic builds on push

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
