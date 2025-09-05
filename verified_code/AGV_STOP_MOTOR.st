PROGRAM AGV_STOP_MOTOR
VAR_INPUT
    SINGLE_PB : BOOL;
    E_STOP : BOOL;
END_VAR
VAR_OUTPUT
    FWD_MOTOR : BOOL := FALSE;
    REV_MOTOR : BOOL := FALSE;
END_VAR

IF SINGLE_PB OR E_STOP THEN
    FWD_MOTOR := FALSE;
    REV_MOTOR := FALSE;
ELSE
    (* Motors are not explicitly commanded to stop. For this module, assume they should remain off or await other start logic. *)
    FWD_MOTOR := FALSE;
    REV_MOTOR := FALSE;
END_IF

END_PROGRAM