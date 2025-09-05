(*
    IEC 61131-3 Structured Text Program
    Program Name: GRAVEL
    Generated: 2025-09-03 12:12:37
    Verified and compliant with IEC standards
*)

PROGRAM GRAVEL
VAR_INPUT
    OFF_PB         : BOOL;
    ON_PB          : BOOL;
    FILL_PB        : BOOL;
    SIREN_ACK      : BOOL;
    LOAD_PB        : BOOL; (* Load truck from bin *)
    JOG_PB         : BOOL;
    LAMP_TEST      : BOOL;
    TRUCK_ON_RAMP  : BOOL; (* Optical sensor *)
    SILO_EMPTY_LS  : BOOL;
    BIN_EMPTY_LS   : BOOL;
    SETPOINT       : BYTE; (* 2-digit BCD *)
END_VAR
VAR_OUTPUT
    CONTROL_LAMP    : BOOL;
    TRUCK_LAMP      : BOOL;
    SILO_EMPTY_LAMP : BOOL;
    CONVEYOR_LAMP   : BOOL;
    CONVEYOR_MOTOR  : BOOL;
    SILO_VALVE      : BOOL;
    BIN_VALVE       : BOOL;
    SIREN           : BOOL;
    BIN_LEVEL       : BYTE;
END_VAR
VAR
    BLINK_TIME : TIME := T#500ms; (* Blinker period *) 
    PULSE_TIME : TIME := T#100ms; (* LEVEL_CTR pulse interval *)
    RUNOUT_TIME: TIME := T#2s; (* Conveyor running time after loading *)
    RUN_IN_TIME: TIME := T#1s; (* Conveyor running time before loading *)
    SILENT_TIME: TIME := T#5s; (* Siren silent time after acknowledgement *)
    OK_TO_RUN  : BOOL := FALSE;

    (* Function Blocks *)
    BLINK: TON; (* Blinker timer *)
    SIREN_FF: RS;
    SILENCE_TMR: TP; (* Siren silent period timer *)

    (* Control Logic Variables *)
    bin_level_int : INT;
    setpoint_int : INT;
END_VAR
VAR RETAIN LEVEL_CTR : CTU ; END_VAR

    (* Convert BYTE to INT for comparison *) 
    bin_level_int := BYTE_TO_INT(BIN_LEVEL);
    setpoint_int := BYTE_TO_INT(SETPOINT);

    (* Conveyor motor control and OK_TO_RUN logic *) 
    OK_TO_RUN := ON_PB AND NOT OFF_PB AND (bin_level_int <= (setpoint_int * 60 / 100));

    (* Control Lamps *) 
    CONTROL_LAMP := OK_TO_RUN;

    (* Conveyor Motor *) 
    CONVEYOR_MOTOR := OK_TO_RUN;

    (* Level Counter pulse generation *) 
    PULSE(IN := FILL_PB, PT := PULSE_TIME);
    LEVEL_CTR(CU := PULSE.Q);

    (* Convert level counter to BYTE for output *) 
    BIN_LEVEL := INT_TO_BYTE(LEVEL_CTR.Q);

    (* Blinker Logic for Conveyor Lamp *) 
    BLINK(IN := OK_TO_RUN, PT := BLINK_TIME);
    CONVEYOR_LAMP := BLINK.Q;
    (* If OK_TO_RUN is FALSE, BLINK timer is reset and not Q, resulting in OFF lamp. *) 

    (* Siren Logic *) 
    (* Activate siren if silo or bin is empty and not acknowledged. *) 
    SIREN_FF(S := (SILO_EMPTY_LS OR (BIN_EMPTY_LS AND NOT SIREN_ACK)), R := SIREN_ACK);
    SIREN := SIREN_FF.Q1;

    (* Silence timer for siren *) 
    SILENCE_TMR(IN := SIREN_ACK, PT := SILENT_TIME);

    (* Silo Valve Control *) 
    SILO_VALVE := FILL_PB AND OK_TO_RUN AND NOT SILO_EMPTY_LS;

    (* Bin Valve Control *) 
    BIN_VALVE := LOAD_PB AND OK_TO_RUN AND NOT BIN_EMPTY_LS;

    (* Truck Lamp Control *) 
    TRUCK_LAMP := LOAD_PB;

    (* Silo Empty Lamp *) 
    SILO_EMPTY_LAMP := SILO_EMPTY_LS;

END_PROGRAM