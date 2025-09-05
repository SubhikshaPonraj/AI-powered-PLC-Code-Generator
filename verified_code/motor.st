PROGRAM Main
VAR
    StartButton : BOOL;
    StopButton : BOOL;
    Motor : BOOL;
END_VAR

IF StartButton AND NOT StopButton THEN
    Motor := TRUE;
ELSIF StopButton THEN
    Motor := FALSE;
END_IF;
END_PROGRAM

