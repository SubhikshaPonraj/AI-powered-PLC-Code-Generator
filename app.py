from flask import Flask, render_template, request, jsonify
from flask_cors import CORS
import os
from final_rag import search_documents, generate_answer
import re

app = Flask(__name__)
CORS(app)

# Global variable to store the last generated code
last_generated_code = {"code": "", "filename": ""}

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/ask', methods=['POST'])
def ask_question():
    global last_generated_code
    data = request.get_json()
    query = data.get('query', '')
    
    if not query:
        return jsonify({"error": "No query provided"}), 400
    
    try:
        retrieved_chunks = search_documents(query)
        answer = generate_answer(query, retrieved_chunks)
        
        # Extract just the code from the answer for display
        code_content = extract_code_from_response(answer)
        
        # Extract program name for filename
        program_name_match = re.search(r'PROGRAM\s+(\w+)', code_content, re.IGNORECASE)
        program_name = program_name_match.group(1) if program_name_match else "program"
        filename = f"{program_name}.st"
        
        # Store the last generated code for download
        last_generated_code = {
            "code": code_content,
            "filename": filename
        }
        
        return jsonify({
            "answer": code_content,
            "sources": [{"source": chunk["source"], "page": chunk["page"]} for chunk in retrieved_chunks],
            "filename": filename
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

def extract_code_from_response(response_text):
    """Extract Structured Text code from response"""
    # Try to find code between markers first
    code_match = re.search(r'```(?:\w+)?\s*(.*?)\s*```', response_text, re.DOTALL)
    if code_match:
        return code_match.group(1).strip()
    
    # If no markers, look for PROGRAM keyword
    program_start = response_text.find('PROGRAM')
    if program_start == -1:
        program_start = response_text.find('VAR')
    
    if program_start != -1:
        code_content = response_text[program_start:]
        # Remove any text after END_PROGRAM if it exists
        end_program = code_content.find('END_PROGRAM')
        if end_program != -1:
            code_content = code_content[:end_program + len('END_PROGRAM')]
        return code_content
    
    # If all else fails, return the original text
    return response_text

if __name__ == '__main__':
    app.run(debug=True, port=5000)