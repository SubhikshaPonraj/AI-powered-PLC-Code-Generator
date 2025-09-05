PROGRAM MotorStopControl
VAR_INPUT
    I_Button_i_Pressed : BOOL;
END_VAR
VAR_OUTPUT
    Q_Motor_Output : BOOL := FALSE;
END_VAR

Q_Motor_Output := Q_Motor_Output AND NOT I_Button_i_Pressed;

END_PROGRAM