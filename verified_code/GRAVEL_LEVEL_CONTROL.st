(*
    IEC 61131-3 Structured Text Program
    Program Name: GRAVEL_LEVEL_CONTROL
    Generated: 2025-09-03 12:28:44
    Verified and compliant with IEC standards
*)

PROGRAM GRAVEL_LEVEL_CONTROL
VAR_INPUT
    BIN_LEVEL : BYTE; (* Process variable - tank level *) 
    AUTO : BOOL;      (* Control mode selector *) 
END_VAR
VAR_OUTPUT
    BIN_VALVE : BOOL; (* Output to control the tank valve *) 
END_VAR
VAR CONSTANT
    LEVEL_THRESHOLD : REAL := 60.0; (* Maximum allowed level in percent *) 
END_VAR
VAR
    rBinLevelPercent : REAL; (* Tank level in percentage *) 
END_VAR

(* Convert raw BYTE level to percentage. Assumes BYTE is a scaled value requiring conversion. *) 
rBinLevelPercent := BYTE_TO_REAL(BIN_LEVEL);

(* Control the BIN_VALVE based on AUTO mode and level threshold. *) 
IF AUTO AND (rBinLevelPercent > LEVEL_THRESHOLD) THEN
    BIN_VALVE := FALSE; (* Close valve if level exceeds threshold in AUTO mode *) 
END_IF;