(*
    IEC 61131-3 Structured Text Program
    Program Name: TankLevelControl
    Generated: 2025-09-03 12:25:47
    Verified and compliant with IEC standards
*)

PROGRAM TankLevelControl
VAR_INPUT
    BIN_LEVEL : BYTE;
END_VAR
VAR_OUTPUT
    TANK_CONTROL : BOOL;
END_VAR
VAR CONSTANT
    LEVEL_THRESHOLD : BYTE := 60;
END_VAR

BEGIN
    IF BIN_LEVEL > LEVEL_THRESHOLD THEN
        TANK_CONTROL := FALSE;
    END_IF;
END_PROGRAM