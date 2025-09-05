import os
import atexit
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import logging
logging.getLogger('tensorflow').setLevel(logging.ERROR)
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)
import tensorflow as tf
from dotenv import load_dotenv
##################################

import os
import glob
import faiss
import pickle
import fitz  
from sentence_transformers import SentenceTransformer
from typing import List, Dict
import google.genai as genai
import re
from verify import IECVerifier
from prom_inst import prompt_content

load_dotenv()

DATA_DIR = "pdfs"
INDEX_FILE = "vector.index"
MAPPING_FILE = "mapping.pkl"
TOP_K = 10

Api_key = os.getenv("GEMINI_API_KEY")

client = genai.Client(api_key=Api_key)
embedder = SentenceTransformer("all-MiniLM-L6-v2")
dimension = 384

if os.path.exists(INDEX_FILE) and os.path.exists(MAPPING_FILE):
    index = faiss.read_index(INDEX_FILE)
    with open(MAPPING_FILE, "rb") as f:
        id_to_text = pickle.load(f)
    indexed_files = set(id_to_text.get("files", []))
else:
    index = faiss.IndexFlatL2(dimension)
    id_to_text = {}
    indexed_files = set()

def extract_chunks_by_page(file_path: str) -> List[Dict]:
    doc = fitz.open(file_path)
    chunks = []
    for page_num in range(len(doc)):
        page = doc.load_page(page_num)
        text = page.get_text("text").strip()
        if text:
            chunks.append({
                "text": f"Page {page_num + 1}:\n{text}",
                "source": os.path.basename(file_path),
                "page": page_num + 1
            })
    return chunks

def add_documents_to_index(chunks: List[Dict], source_file: str = None):
    global id_to_text, index, indexed_files
    if not chunks:
        return

    texts = [chunk["text"] for chunk in chunks]
    embeddings = embedder.encode(texts, convert_to_numpy=True)
    start_id = len([k for k in id_to_text if isinstance(k, int)])
    ids = [start_id + i for i in range(len(chunks))]

    index.add(embeddings)
    for i, chunk in zip(ids, chunks):
        id_to_text[i] = {
            "text": chunk["text"],
            "source": chunk["source"],
            "page": chunk["page"]
        }

    if source_file:
        indexed_files.add(source_file)
        id_to_text["files"] = list(indexed_files)

    faiss.write_index(index, INDEX_FILE)
    with open(MAPPING_FILE, "wb") as f:
        pickle.dump(id_to_text, f)

def search_documents(query: str, top_k: int = TOP_K) -> List[Dict]:
    query_emb = embedder.encode([query], convert_to_numpy=True)
    D, I = index.search(query_emb, top_k)
    results = []
    for idx in I[0]:
        chunk = id_to_text.get(idx)
        if isinstance(chunk, dict) and "text" in chunk:
            results.append(chunk)
        # else:
        #     print(f"âš ï¸ Skipping malformed chunk at index {idx}: {chunk}")
    return results

def build_prompt_ai(query: str, context_chunks: List[Dict]) -> str:
    valid_chunks = [
        chunk for chunk in context_chunks
        if isinstance(chunk, dict) and "text" in chunk and "source" in chunk and "page" in chunk
    ]

    if not valid_chunks:
        return f"🛑 No valid context found to answer the question: {query}"

    context_text = "\n\n".join([chunk["text"] for chunk in valid_chunks])
    metadata = "\n".join([f"[{chunk['source']} - Page {chunk['page']}]" for chunk in valid_chunks])

    prompt = f"""
{prompt_content}

Input Processing:

📚 Context: {context_text}
🧾 Question: {query}


---

## FINAL EXECUTION DIRECTIVE

CRITICAL INSTRUCTION:
When context and query are provided, you must:
1. Read and interpret the provided context and question carefully
2. Always translate the requirements into directly executable Structured Text code that follows IEC 61131-3 standards
3. The output must include proper program structure (PROGRAM, VAR … END_VAR, logic)
4. Use IEC standard function blocks (e.g., TON, TOF, CTU, CTD) where applicable
5. Ensure correct syntax and indentation for Structured Text
6. Do not output explanations, comments, or metadata
7. The final answer must be ONLY the complete Structured Text code block
8. Use comment lines and blocks only for the complex areas and don't use more than 1 line continuously. Maintain the readibility off the code alive.Don't create a mess by generating too many the commant line
---
 
For any given question, generate only the necessary Structured Text code that directly solves the problem.  
- Keep the program minimal and focused on the stated requirement.  
- Do not add extra processes (e.g., conveyors, alarms, lamps, timers, trucks, blinking logic) unless the question explicitly requires them.  
- Use standard IEC61131-3 syntax and naming conventions.    
- Output only the Structured Text code, nothing else.
- You are not allowed to add commant line or commant block to explain every line of code. You are alowed to add only 1 commant line or commant block only after each 8 lines of code that to only if necessary
- use const for declaring the threshold
📚 Context:
{context_text}

🔎 Source Metadata:
{metadata}

🧾 Question:
{query}

🧠 Answer:
No extra fittings in the logic, but correctly have the safety standards where it is necessary
"""
    return prompt

def generate_answer(query: str, context_chunks: List[Dict]) -> str:
    prompt = build_prompt_ai(query, context_chunks)
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
    )
    return response.text

def process_pdf_folder():
    if not os.path.exists(DATA_DIR):
        os.makedirs(DATA_DIR)
        return

    pdf_files = glob.glob(os.path.join(DATA_DIR, "*.pdf"))
    for pdf_path in pdf_files:
        filename = os.path.basename(pdf_path)
        if filename in indexed_files:
            continue
        print(f"Processing: {filename}")
        chunks = extract_chunks_by_page(pdf_path)
        add_documents_to_index(chunks, source_file=filename)
    print("✅ All PDFs processed and indexed by page.")

def extract_all_code(answer: str) -> Dict[str, List[str]]:
    """
    Extract all code blocks and their potential language labels.

    Returns:
        Dictionary with 'code_blocks' and 'languages' lists
    """
    # Pattern to capture language and code
    pattern = r'(\w+)?\s*\n(.*?)\n'

    matches = re.findall(pattern, answer, re.DOTALL)

    languages = []
    code_blocks = []

    for lang, code in matches:
        languages.append(lang.strip() if lang else "unknown")
        code_blocks.append(code.strip())

    return {
        'languages': languages,
        'code_blocks': code_blocks
    }

def run_interactive_mode():
    """Interactive mode - only runs when script is executed directly"""
    print('Hi')
    process_pdf_folder()
    print("\n📝 Sample Question Prompt Demo")
    print("Type 'exit' to quit.\n")

    verify = IECVerifier()
    while True:
        query = input("Enter your question: ")
        if query.lower() in {"exit", "quit"}:
            print("Exiting...")
            break
        retrieved_chunks = search_documents(query)
        answer = generate_answer(query, retrieved_chunks)
        print("\n📹 Answer:")
        # print(answer)
        verification_result = verify.process_ai_response(answer)
        print(f"\n📹 Verification Result:")
        print(verification_result)
        
        # print("\n📹 Retrieved Context:")
        # for idx, chunk in enumerate(retrieved_chunks, 1):
        #     preview = chunk["text"][:300].replace("\n", " ")
        #     print(f"{idx}. [{chunk['source']} - Page {chunk['page']}] {preview}{'...' if len(preview) > 300 else ''}")
        # print("-" * 50)

# Only run interactive mode when script is executed directly
if __name__ == "__main__":
    run_interactive_mode()