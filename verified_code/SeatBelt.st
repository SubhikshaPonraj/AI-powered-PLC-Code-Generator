(*
    IEC 61131-3 Structured Text Program
    Program Name: SeatBelt
    Generated: 2025-09-03 12:38:25
    Verified and compliant with IEC standards
*)

PROGRAM SeatBelt
VAR
    Step : INT := 0; // Current state in the process
    OK_Part : BOOL := FALSE; // Flag indicating a successfully processed part
    NOK_Part : BOOL := FALSE; // Flag indicating a faulty processed part
    CycleStartTime : TIME; // Timestamp for the start of a cycle
    CycleEndTime : TIME; // Timestamp for the end of a cycle
    CycleTime : TIME; // Calculated duration of a cycle
    AlarmCode : INT := 0; // Code indicating the type of alarm or fault
    
    // Standard IEC Timer instances for riveting steps
    Rivet1Timer : TON;
    Rivet2Timer : TON;
    Rivet3Timer : TON;
END_VAR

CASE Step OF

    0:  (* Index 1 - Presence & Barcode Check *)
        CycleStartTime := TIME();  // Start Cycle Timer
        AlarmCode := 0;
        IF NOT LR_Frame THEN
            AlarmCode := 101; // Frame Missing
        ELSIF NOT LR_Spool THEN
            AlarmCode := 102; // Spool Missing
        ELSIF NOT LR_PTHousing THEN
            AlarmCode := 103; // PT Housing Missing
        ELSIF NOT Barcode_OK THEN
            AlarmCode := 104; // Barcode Failed
            NOK_Part := TRUE;
            Step := 7; // Skip to unload as NOK
        ELSE
            Step := 1;
        END_IF

    1:  (* Index 2 - LVDT Before Riveting *)
        AlarmCode := 0;
        IF NOT ALL_LVDT_OK(LVDT_Height_Before) THEN
            AlarmCode := 201; // Pre-Rivet Height Out of Range
            NOK_Part := TRUE;
            Step := 7;
        ELSE
            Step := 2;
        END_IF

    2:  (* Index 3 - Press First Rivet *)
        Press_Rivet_1 := TRUE;
        Rivet1Timer(IN := TRUE, PT := T#5S);
        IF Rivet1Timer.Q THEN
            Press_Rivet_1 := FALSE;
            Rivet1Timer(IN := FALSE);
            IF NOT Rivet_Press_1_Done THEN
                AlarmCode := 301; // Rivet 1 Press Failure (Expected signal not received)
                NOK_Part := TRUE;
                Step := 7;
            ELSE
                AlarmCode := 0;
                Step := 3;
            END_IF
        END_IF

    3:  (* Index 4 - Press Long Rivet *)
        Press_Rivet_2 := TRUE;
        Rivet2Timer(IN := TRUE, PT := T#5S);
        IF Rivet2Timer.Q THEN
            Press_Rivet_2 := FALSE;
            Rivet2Timer(IN := FALSE);
            IF NOT Rivet_Press_2_Done THEN
                AlarmCode := 302; // Rivet 2 Press Failure
                NOK_Part := TRUE;
                Step := 7;
            ELSE
                AlarmCode := 0;
                Step := 4;
            END_IF
        END_IF

    4:  (* Index 5 - Press Remaining Rivets *)
        Press_Rivet_3 := TRUE;
        Rivet3Timer(IN := TRUE, PT := T#5S);
        IF Rivet3Timer.Q THEN
            Press_Rivet_3 := FALSE;
            Rivet3Timer(IN := FALSE);
            IF NOT Rivet_Press_3_Done THEN
                AlarmCode := 303; // Rivet 3 Press Failure
                NOK_Part := TRUE;
                Step := 7;
            ELSE
                AlarmCode := 0;
                Step := 5;
            END_IF
        END_IF

    5:  (* Index 6 - LVDT After Riveting *)
        AlarmCode := 0;
        IF ALL_LVDT_OK(LVDT_Height_After) THEN
            OK_Part := TRUE;
        ELSE
            NOK_Part := TRUE;
            AlarmCode := 401; // Post-Rivet Height Out of Range
        END_IF
        Step := 6; // Move to unload preparation

    6:  (* Index 7 - Unloading Preparation *)
        // This step just prepares for unloading logic which is in the next state
        // If NOK_Part was set, the system will proceed to unload it.
        // If OK_Part was set, the system will proceed to unload it.
        Step := 7;

    7:  (* Index 8 - Unloading *)
        // Output control for the unload conveyor
        Unload_Conveyor_Fwd := FALSE;
        Unload_Conveyor_Rev := FALSE;

        IF OK_Part THEN
            Unload_Conveyor_Fwd := TRUE;
        ELSIF NOK_Part THEN
            Unload_Conveyor_Rev := TRUE;
        END_IF

        // Wait for the part to be cleared from the unload station
        IF NOT Part_At_Unload THEN
            CycleEndTime := TIME();
            CycleTime := CycleEndTime - CycleStartTime;

            // Reset state variables for the next cycle
            OK_Part := FALSE;
            NOK_Part := FALSE;
            Press_Rivet_1 := FALSE;
            Press_Rivet_2 := FALSE;
            Press_Rivet_3 := FALSE;
            Unload_Conveyor_Fwd := FALSE;
            Unload_Conveyor_Rev := FALSE;
            AlarmCode := 0;
            
            Index_Forward := TRUE; // Assume forward movement for indexing
            Step := 0; // Reset to initial state
        END_IF
END_CASE

END_PROGRAM


FUNCTION ALL_LVDT_OK : BOOL
VAR_INPUT
    Heights : ARRAY[1..5] OF REAL;
END_VAR
VAR
    i : INT;
END_VAR

// Checks if all provided LVDT height measurements are within the acceptable range.
ALL_LVDT_OK := TRUE;
FOR i := 1 TO 5 DO
    // LVDT height must be between 10.0 and 12.0
    IF Heights[i] < 10.0 OR Heights[i] > 12.0 THEN
        ALL_LVDT_OK := FALSE;
        // Exit loop early if any measurement is out of range
        EXIT;
    END_IF;
END_FOR;
END_FUNCTION
