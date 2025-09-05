PROGRAM TankControlProgram
VAR_INPUT
    I_OFF_BUTTON_CH1 : BOOL; (* Input from Normally Closed (NC) contact of OFF button, Channel 1 *)
    I_OFF_BUTTON_CH2 : BOOL; (* Input from Normally Closed (NC) contact of OFF button, Channel 2 *)
END_VAR
VAR_OUTPUT
    Q_TANK_VALVE : BOOL;
END_VAR
VAR
    bSafetyRunPermitted : BOOL;
END_VAR

bSafetyRunPermitted := I_OFF_BUTTON_CH1 AND I_OFF_BUTTON_CH2;

Q_TANK_VALVE := bSafetyRunPermitted;

END_PROGRAM