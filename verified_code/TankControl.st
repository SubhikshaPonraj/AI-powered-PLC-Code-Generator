PROGRAM TankControl
VAR_INPUT
    I_OFF_BUTTON : BOOL;
END_VAR
VAR_OUTPUT
    Q_TANK_ON    : BOOL := FALSE; (* CORRECTED: Initialized to FALSE for fail-safe operation *)
END_VAR

(* CORRECTED: Explicit and deterministic control for Q_TANK_ON. *)
(* Q_TANK_ON will be TRUE only when I_OFF_BUTTON is not pressed, and FALSE otherwise. *)
(* This ensures deterministic output control and fail-safe behavior on start-up. *)
Q_TANK_ON := NOT I_OFF_BUTTON;

END_PROGRAM