#!/usr/bin/env python3
"""
Simple Flask web application for the calculator.
"""

from flask import Flask, render_template, request, jsonify
from calculator.operations import add, subtract, multiply, divide

app = Flask(__name__)

@app.route('/')
def index():
    """Main page with calculator interface."""
    return render_template('calculator.html')

@app.route('/api/calculate', methods=['POST'])
def calculate():
    """API endpoint for calculator operations."""
    try:
        data = request.get_json()
        operation = data.get('operation')
        a = float(data.get('a', 0))
        b = float(data.get('b', 0))
        
        if operation == 'add':
            result = add(a, b)
        elif operation == 'subtract':
            result = subtract(a, b)
        elif operation == 'multiply':
            result = multiply(a, b)
        elif operation == 'divide':
            if b == 0:
                return jsonify({'error': 'Cannot divide by zero'}), 400
            result = divide(a, b)
        else:
            return jsonify({'error': 'Invalid operation'}), 400
        
        return jsonify({
            'result': result,
            'operation': operation,
            'a': a,
            'b': b
        })
    
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': 'An error occurred'}), 500

@app.route('/health')
def health():
    """Health check endpoint."""
    return jsonify({'status': 'healthy', 'service': 'calculator'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False) 