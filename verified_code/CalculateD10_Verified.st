PROGRAM CalculateD10_Verified
VAR_INPUT
    xEnableCalculation : BOOL;
    iInputFactor     : INT;
    iInputAddend1    : INT;
    iInputAddend2    : INT;
END_VAR
VAR_OUTPUT
    iCalculatedResult  : INT := 0;
    xCalculationError  : BOOL := FALSE;
    xSumOverflowError  : BOOL := FALSE;
    xResultOverflowError : BOOL := FALSE;
END_VAR
VAR
    iIntermediateSum   : INT;
END_VAR

// Main program logic
xCalculationError := FALSE;
xSumOverflowError := FALSE;
xResultOverflowError := FALSE;

IF xEnableCalculation THEN
    // 1. Check for potential overflow of (iInputAddend1 + iInputAddend2)
    // IEC 61131-3 defines INT_MAX (32767) and INT_MIN (-32768) for standard INT.
    IF (iInputAddend2 > 0 AND iInputAddend1 > (32767 - iInputAddend2)) OR
       (iInputAddend2 < 0 AND iInputAddend1 < (-32768 - iInputAddend2)) THEN
        xSumOverflowError := TRUE;
        xCalculationError := TRUE;
        iIntermediateSum := 0; // Set to safe default
    ELSE
        iIntermediateSum := iInputAddend1 + iInputAddend2;
    END_IF;

    // 2. Perform multiplication with overflow check for iInputFactor * iIntermediateSum
    IF NOT xSumOverflowError THEN
        // More robust overflow check for multiplication, considering signs.
        // If iInputFactor is 0, no overflow possible (result is 0).
        IF iInputFactor = 0 THEN
            xResultOverflowError := FALSE;
        ELSIF (iIntermediateSum > 0 AND iInputFactor > 0 AND iIntermediateSum > (32767 / iInputFactor)) THEN
            xResultOverflowError := TRUE;
        ELSIF (iIntermediateSum < 0 AND iInputFactor < 0 AND iIntermediateSum < (32767 / iInputFactor)) THEN
            xResultOverflowError := TRUE;
        ELSIF (iIntermediateSum > 0 AND iInputFactor < 0 AND iIntermediateSum > (-32768 / iInputFactor)) THEN
            xResultOverflowError := TRUE;
        ELSIF (iIntermediateSum < 0 AND iInputFactor > 0 AND iIntermediateSum < (-32768 / iInputFactor)) THEN
            xResultOverflowError := TRUE;
        END_IF;

        IF xResultOverflowError THEN
            xCalculationError := TRUE;
            iCalculatedResult := 0; // Set to safe default
        ELSE
            iCalculatedResult := iInputFactor * iIntermediateSum;
        END_IF;
    ELSE
        // If sum already overflowed, result is also in error.
        iCalculatedResult := 0; // Set to safe default
    END_IF;

    // If any error occurred, ensure output is a safe value
    IF xCalculationError THEN
        iCalculatedResult := 0; // Enforce safe state for output
    END_IF;

ELSE
    // If xEnableCalculation is FALSE, calculation is not active.
    // Reset output to a safe state (e.g., 0) and clear all errors.
    iCalculatedResult := 0;
    xCalculationError := FALSE;
    xSumOverflowError := FALSE;
    xResultOverflowError := FALSE;
END_IF;

END_PROGRAM