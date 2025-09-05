(*
    IEC 61131-3 Structured Text Program
    Program Name: PackagingRejectStation
    Generated: 2025-09-03 12:31:46
    Verified and compliant with IEC standards
*)

PROGRAM PackagingRejectStation
VAR
    // Inputs
    I_ItemPresent : BOOL;         // Sensor indicating an item is present on the main conveyor
    I_DefectiveItem : BOOL;       // Signal from quality inspection indicating a defective item
    I_RejectConveyorAck : BOOL;   // Acknowledgment from the reject conveyor that an item was accepted

    // Outputs
    Q_DivertToReject : BOOL;      // Output to activate the reject diverter mechanism
    Q_RejectAlarm : BOOL;         // Output to activate the reject rate alarm

    // Internal Variables
    rejectCount : INT := 0;       // Current count of rejected items within the window
    totalCount : INT := 0;        // Current count of total items processed within the window
    rejectRate : REAL := 0.0;     // Calculated reject rate
    alarmActive : BOOL := FALSE;  // Flag to indicate if the alarm is active
    bDiverterActive : BOOL := FALSE; // Internal flag for diverter control

    // Timers and Edge Detectors
    RTrig_ItemDetected : R_TRIG;  // Detects rising edge of item presence
    TON_RejectTimer : TON;        // Timer to manage the duration of the divert action
    TON_AlarmCheckTimer : TON;    // Timer to periodically check the reject rate

    // Constants
    C_RejectRateThreshold : REAL := 0.05; // 5% reject rate threshold
    C_WindowSize : INT := 100;           // Lookback window for reject rate calculation
    C_DivertDuration : TIME := T#500ms;  // Duration for the reject diverter to be active
    C_AlarmCheckInterval : TIME := T#1s; // Interval for checking the reject rate

    // For rolling window - store states of last N items
    rgiItemHistory : ARRAY[0..99] OF BOOL; // Stores defective status for last C_WindowSize items
    uiHistoryIndex : INT := 0;            // Current index for the history buffer
    uiRingBufferPos : INT := 0;           // Position for cyclic buffer

END_VAR

// --- Main Logic ---

// Detect item presence and trigger processing
RTrig_ItemDetected(CLK := I_ItemPresent);

IF RTrig_ItemDetected.Q THEN
    // Store the defective status of the current item in the rolling history buffer
    rgiItemHistory[uiRingBufferPos] := I_DefectiveItem;

    // Manage the rolling window index
    uiRingBufferPos := (uiRingBufferPos + 1) MOD C_WindowSize;

    // Increment total count and manage defect count within the window
    IF totalCount < C_WindowSize THEN
        totalCount := totalCount + 1;
        IF I_DefectiveItem THEN
            rejectCount := rejectCount + 1;
        END_IF;
    ELSE
        // If window is full, check the oldest item entering the window
        IF rgiItemHistory[uiRingBufferPos] THEN
            rejectCount := rejectCount - 1; // Decrement reject count if the oldest item was a reject
        END_IF;
        // totalCount remains C_WindowSize for a full window
    END_IF;

    // If the item is defective, activate the diverter and its timer
    IF I_DefectiveItem THEN
        bDiverterActive := TRUE;
        TON_RejectTimer(IN := TRUE, PT := C_DivertDuration);
    END_IF;

    // Manage the reject diverter output based on the internal flag and timer completion
    IF bDiverterActive THEN
        Q_DivertToReject := TRUE;
        IF TON_RejectTimer.Q THEN
            bDiverterActive := FALSE;
            TON_RejectTimer(IN := FALSE); // Reset the timer
        END_IF;
    ELSE
        Q_DivertToReject := FALSE;
    END_IF;

    // Acknowledge reject conveyor if diverter is active (for process flow)
    IF Q_DivertToReject AND NOT I_RejectConveyorAck THEN
        // This condition might indicate a fault or require retry logic in a real system.
        // For this example, we proceed assuming normal operation or async ack.
    END_IF;

END_IF;

// Ensure diverter is off if no item is present and timer has expired
IF NOT I_ItemPresent AND NOT bDiverterActive THEN
    Q_DivertToReject := FALSE;
END_IF;

// --- Alarm Logic ---

// Start the alarm check timer if it's not running
IF NOT TON_AlarmCheckTimer.IN AND NOT TON_AlarmCheckTimer.Q THEN
    TON_AlarmCheckTimer(IN := TRUE, PT := C_AlarmCheckInterval);
END_IF;

// When the alarm check timer has elapsed
IF TON_AlarmCheckTimer.Q THEN
    TON_AlarmCheckTimer(IN := FALSE); // Reset timer for next interval

    // Calculate reject rate only if items have been processed within the window
    IF totalCount > 0 THEN
        rejectRate := REAL(rejectCount) / REAL(totalCount);
    ELSE
        rejectRate := 0.0;
    END_IF;

    // Activate alarm if reject rate exceeds the threshold
    IF rejectRate > C_RejectRateThreshold THEN
        alarmActive := TRUE;
    ELSE
        // Deactivate alarm if rate drops below threshold
        alarmActive := FALSE;
    END_IF;

    // Update the physical alarm output
    Q_RejectAlarm := alarmActive;
END_IF;

END_PROGRAM
