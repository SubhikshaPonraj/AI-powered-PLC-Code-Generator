PROGRAM MemoryCalculation
VAR_INPUT
    M0 : BOOL;
    D0 : DINT;
    D1 : DINT;
    D2 : DINT;
END_VAR
VAR_OUTPUT
    D10 : DINT;
END_VAR

IF M0 THEN
    D10 := D0 * (D1 + D2);
ELSE
    D10 := 0; (* Set to a defined, safe default when M0 is FALSE *)
END_IF;

END_PROGRAM