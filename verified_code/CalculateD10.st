PROGRAM CalculateD10
VAR_INPUT
    M0 : BOOL;
    D0 : REAL;
    D1 : REAL;
    D2 : REAL;
END_VAR
VAR_OUTPUT
    D10 : REAL := 0.0;
    AlarmCode : INT := 0;
END_VAR
VAR
END_VAR

IF M0 THEN
    IF IS_NAN(D0) OR IS_INF(D0) OR
       IS_NAN(D1) OR IS_INF(D1) OR
       IS_NAN(D2) OR IS_INF(D2) THEN
        D10 := 0.0;
        AlarmCode := 1001; 
    ELSE
        D10 := D0 * (D1 + D2);
        AlarmCode := 0;
    END_IF;
ELSE
    D10 := 0.0;
    AlarmCode := 0;
END_IF;

END_PROGRAM