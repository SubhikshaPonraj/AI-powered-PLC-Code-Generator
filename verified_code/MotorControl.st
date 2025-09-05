PROGRAM MotorControl
VAR_INPUT
    I_Single_PB : BOOL;
    I_EStop_Active : BOOL; (* Emergency Stop - Active LOW, so TRUE when not pressed *)
    I_SafetyGuard_Closed : BOOL; (* Safety Guard Status - TRUE when closed *)
END_VAR
VAR_OUTPUT
    Q_Fwd_Motor : BOOL;
END_VAR
VAR
    M_PB_Edge : R_TRIG;
    M_Motor_State : BOOL := FALSE;
END_VAR

M_PB_Edge(CLK := I_Single_PB);

IF M_PB_Edge.Q THEN
    M_Motor_State := NOT M_Motor_State;
END_IF;

(* Incorporate safety conditions: Motor runs only if its internal state is ON AND E-Stop is NOT active AND Safety Guard is closed *)
Q_Fwd_Motor := M_Motor_State AND I_EStop_Active AND I_SafetyGuard_Closed;

END_PROGRAM