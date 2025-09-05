PROGRAM CalculateIndustrialOutput
VAR_INPUT
    bEnableCalculation : BOOL := FALSE; // Enable signal for the calculation
    rInputFactor       : REAL := 0.0;   // Multiplier input
    rInputOperand1     : REAL := 0.0;   // First operand for addition
    rInputOperand2     : REAL := 0.0;   // Second operand for addition
END_VAR
VAR_OUTPUT
    rCalculatedOutput  : REAL := 0.0;   // Result of the calculation
END_VAR

IF bEnableCalculation THEN
    rCalculatedOutput := rInputFactor * (rInputOperand1 + rInputOperand2);
ELSE
    rCalculatedOutput := 0.0; // Ensure a defined state when not enabled
END_IF

END_PROGRAM