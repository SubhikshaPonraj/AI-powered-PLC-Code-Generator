PROGRAM Main
    VAR_INPUT
        I_StartButton : BOOL;
        I_StopButton : BOOL;
        I_EmergencyStop : BOOL;
    END_VAR

    VAR_OUTPUT
        Q_Motor : BOOL;
    END_VAR

    VAR
        FB_Motor_SR : SR;
        Internal_Motor_Run_Cmd : BOOL;
    END_VAR

    FB_Motor_SR(SET1 := I_StartButton, R1 := I_StopButton, Q1 => Internal_Motor_Run_Cmd);

    Q_Motor := Internal_Motor_Run_Cmd AND NOT I_EmergencyStop;

END_PROGRAM