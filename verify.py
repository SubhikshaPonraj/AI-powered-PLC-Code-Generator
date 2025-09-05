# iec_verifier.py
import os
import re
import json
from datetime import datetime
import google.genai as genai
from prom_inst import code_verification_prompt
from dotenv import load_dotenv


load_dotenv()

Api_key = os.getenv("GEMINI_API_KEY")
class IECVerifier:
    """Class to handle IEC 61131-3 Structured Text code verification and saving"""

    def __init__(self, api_key=Api_key, verified_dir: str = "verified_code"):
        # Initialize Gemini client
        self.client = genai.Client(api_key=api_key)
        self.verified_dir = verified_dir
        os.makedirs(self.verified_dir, exist_ok=True)

    def extract_st_code(self, response_text: str) -> str:
        """Extract Structured Text code from Gemini response"""
        clean_text = re.sub(r'```(?:\w+)?\s*', '', response_text)
        clean_text = re.sub(r'```\s*', '', clean_text)

        lines = clean_text.strip().split('\n')
        st_code_lines = []
        in_code_block = False

        for line in lines:
            if 'PROGRAM' in line.upper() or 'VAR' in line.upper() or in_code_block:
                in_code_block = True
                st_code_lines.append(line)
                if 'END_PROGRAM' in line.upper():
                    break

        return '\n'.join(st_code_lines) if st_code_lines else clean_text.strip()

    def verify_iec_code(self, code: str) -> dict:
        """Verify IEC 61131-3 code compliance"""
        prompt = f"""{code_verification_prompt}
### CODE TO VERIFY:

```structured_text
{code}
```
- Keep the code simple 
- Strictly remove all the inline commants and inline comment blocks from the code
"""

        try:
            response = self.client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
            )

            result_text = response.text.strip()

            # Extract JSON part
            if '```json' in result_text:
                result_text = result_text.split('```json')[1].split('```')[0].strip()
            elif '```' in result_text:
                result_text = result_text.split('```')[1].split('```')[0].strip()

            return json.loads(result_text)

        except Exception as e:
            return {
                "valid": False,
                "errors": [f"Verification failed: {str(e)}"],
                "corrected_code": ""
            }

    def save_verified_code(self, code: str, filename: str = None) -> str:
        """Save verified code with proper IEC formatting.
        If filename is not provided, use PROGRAM name from code.
        """
        program_name = None
        match = re.search(r'\bPROGRAM\s+(\w+)', code, re.IGNORECASE)
        if match:
            program_name = match.group(1)

        if not filename:
            if program_name:
                filename = f"{program_name}.st"
            else:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"iec_program_{timestamp}.st"

        filepath = os.path.join(self.verified_dir, filename)


        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(code)

        return filepath


    def process_ai_response(self, ai_response: str) -> str:
        """Process AI response string and verify the generated code"""
        generated_code = self.extract_st_code(ai_response)

        if not generated_code or len(generated_code.strip()) < 10:
            return "❌ No valid Structured Text code found in response"

        print(f"🔍 Extracted code for verification:\n{generated_code}\n")

        verification = self.verify_iec_code(generated_code)

        if verification.get("valid", False):
            saved_path = self.save_verified_code(generated_code)
            return f"✅ Code verified successfully!\nSaved to: {saved_path}"

        else:
            if verification.get("corrected_code"):
                corrected_code = verification["corrected_code"]
                saved_path = self.save_verified_code(corrected_code)
                errors = "\n".join(verification.get("errors", []))
                return f"⚠️ Code corrected and saved!\nSaved to: {saved_path}\nErrors fixed:\n{errors}"
            else:
                errors = "\n".join(verification.get("errors", []))
                return f"❌ Invalid code could not be auto-corrected.\nErrors:\n{errors}"



# Usage example
if __name__ == "__main__":
    verifier = IECVerifier(api_key="YOUR_API_KEY_HERE")
    sample_response = """
    ```st
    (*
    PROGRAM: Main
    LANGUAGE: Structured Text (ST)
    STANDARD: IEC 61131-3
    PURPOSE: Demonstrates how a boolean input (StartButton)
             can be used to control a boolean output (Motor).
*)

PROGRAM Main
    // ----------------------------
    // Variable Declaration Section
    // ----------------------------
    VAR
        StartButton : BOOL;   // Input variable representing the start button.
                             // TRUE  → button pressed
                             // FALSE → button not pressed
                             
        Motor : BOOL;         // Output variable representing motor control.
                             // TRUE  → motor is ON
                             // FALSE → motor is OFF
    END_VAR

    // ---------------------------------
    // Main Program Execution Logic
    // ---------------------------------
    // Check if the StartButton is pressed.
    // If StartButton = TRUE, then turn the Motor ON.
    // Otherwise, Motor remains in its previous state
    // (no ELSE condition is provided, so no action occurs).
    IF StartButton THEN
        Motor := TRUE;        // Assign TRUE to Motor → motor is energized.
    END_IF

    // ---------------------------------
    // End of Program
    // ---------------------------------
END_PROGRAM

    ```
    """
    print(verifier.process_ai_response(sample_response))
