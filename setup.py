from setuptools import setup, find_packages

with open('README.md', 'r', encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='jenkins-ci-cd-lab',
    version='0.1.0',
    author='Your Name',
    author_email='your.email@example.com',
    description='A simple calculator project for Jenkins CI/CD demonstration',
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://github.com/mayusuf/jenkins-ci-cd-lab',
    packages=find_packages(),
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
    ],
    python_requires='>=3.7',
    install_requires=[
        # Add your project's runtime dependencies here
    ],
    extras_require={
        'dev': [
            'pytest>=6.0',
            'pytest-cov>=2.0',
            'flake8>=3.9',
        ],
    },
)
