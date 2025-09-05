PROGRAM ProximityLightControl
VAR_INPUT
    ProximitySensor : BOOL; // TRUE when object is detected
    LightEnable     : BOOL; // TRUE to enable light control
END_VAR
VAR_OUTPUT
    LightControl    : BOOL; // FALSE to turn off light
END_VAR

VAR
    SensorActive    : BOOL; // Internal state to track sensor detection
END_VAR

VAR CONSTANT
    LIGHT_OFF_DELAY : TIME := T#100ms;
END_VAR

VAR
    T_LightOffDelay : TON;
END_VAR

IF LightEnable THEN
    // If proximity sensor detects an object, set internal active flag
    IF ProximitySensor THEN
        SensorActive := TRUE;
    END_IF;

    // Manage light control based on sensor activity and timer
    IF SensorActive THEN
        T_LightOffDelay(IN := TRUE, PT := LIGHT_OFF_DELAY); // Start timer to delay light off
        IF T_LightOffDelay.Q THEN
            LightControl := FALSE; // Turn off light after delay
            SensorActive := FALSE; // Reset sensor active state
            T_LightOffDelay(IN := FALSE); // Reset timer
        END_IF;
    ELSE
        LightControl := TRUE; // Keep light on if no sensor activity or pending off-delay
        T_LightOffDelay(IN := FALSE); // Reset timer if sensor is inactive
    END_IF;
ELSE
    // If light control is disabled, ensure light is off and reset all states for safety
    LightControl := FALSE;
    SensorActive := FALSE;
    T_LightOffDelay(IN := FALSE);
END_IF;

END_PROGRAM