-- Libraries and packages
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL; -- Standard Logic Package
USE IEEE.NUMERIC_STD.ALL; -- Numeric Standard Package for arithmetic operations
USE work.COMMON_PACK.ALL; -- Work package

ENTITY dataConsume IS
  PORT(
    clk: IN STD_LOGIC; -- Clock signal
    reset: IN STD_LOGIC; -- Reset signal
    start: IN STD_LOGIC; -- Start signal
    numWords_bcd: IN BCD_ARRAY_TYPE(2 DOWNTO 0); -- Input data in BCD format
    CtrlIn: IN STD_LOGIC; -- Control signal input
    data: IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Data input
    CtrlOut: OUT STD_LOGIC; -- Control signal output
    dataReady: OUT STD_LOGIC; -- Data ready signal
    byte: OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := x"FF"; -- Byte output
    maxIndex: OUT BCD_ARRAY_TYPE(2 DOWNTO 0); -- Maximum index output
    dataResults: OUT CHAR_ARRAY_TYPE(0 TO RESULT_BYTE_NUM-1); -- Data results output
    seqDone: OUT STD_LOGIC); -- Sequence done signal
END dataConsume;

ARCHITECTURE Behavioral OF dataConsume IS
  
  TYPE STATE IS (S0, S1, S2, S3, S4, S5, S6); -- States
  SIGNAL current_state, next_state: STATE; -- Current and next state signals
  SIGNAL Init_4: STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0'); -- Initialisation signal
  SIGNAL All_7: STD_LOGIC_VECTOR(55 DOWNTO 0) := (OTHERS => '0'); -- All 7 signal
  SIGNAL Counter: integer RANGE 0 TO 999 := 0; -- Counter signal
  SIGNAL numWords_decimal: integer RANGE 0 TO 999; -- Number words in decimal
  SIGNAL Ctrl_2_delayed, Ctrl_2_detected: STD_LOGIC; -- Control 2 delayed and detected signals
  SIGNAL Ctrl_1_internal: STD_LOGIC := '0'; -- Control 1 internal signal
  SIGNAL Max_position: integer RANGE 0 TO 999 := 0; -- Maximum position signal
  SIGNAL resetseven: STD_LOGIC := '0'; -- Reset all_7 signal
  SIGNAL positioncounter: integer RANGE 0 TO 999; -- Position counter signal

BEGIN
  -- Delay process
  DELAY_IN: PROCESS(clk)
    BEGIN
      IF clk'EVENT AND CLK = '1' THEN
        Ctrl_2_delayed <= CtrlIn; -- Delay control input
      END IF;
    END PROCESS;
    Ctrl_2_detected <= CtrlIn XOR Ctrl_2_delayed; -- Detect control input
    
  -- Convert number of words from BCD to decimal
  numWords_decimal <= TO_INTEGER(UNSIGNED(numWords_bcd(2)))*100 + TO_INTEGER(UNSIGNED(numWords_bcd(1)))*10 + TO_INTEGER(UNSIGNED(numWords_bcd(0)));
  
  -- State register process
  stateregister: PROCESS(reset, clk)
  BEGIN
    IF clk'event AND clk = '1' THEN
      IF reset = '1' THEN
        current_state <= S0; -- Reset state
      ELSE
        current_state <= next_state; -- Update state
      END IF;
    END IF;
  END PROCESS;
  
  -- Next state logic process
  nextstatelogic: PROCESS(current_state, clk)
  BEGIN
    IF clk'EVENT AND CLK = '1' THEN
      CASE current_state IS 
        WHEN S0 => 
          next_state <= S1; -- Transition to state S1
        WHEN S1 =>
          IF start = '1' THEN
            next_state <= S2; -- Transition to state S2 if start is high
          END IF;
        WHEN S2 =>
          next_state <= S3; -- Transition to state S3
        WHEN S3 => 
          IF Ctrl_2_detected = '1' THEN 
            next_state <= S4; -- Transition to state S4 if control 2 is detected
          END IF;
        WHEN S4 => 
          next_state <= S5; -- Transition to state S5
        WHEN S5 =>
          IF Counter = numWords_decimal THEN 
            next_state <= S6; -- Transition to state S6 if counter equals number of words
          ELSIF Counter < numWords_decimal THEN 
            next_state <= S1; -- Transition back to state S1 if counter is less than number of words
          END IF;
        WHEN OTHERS =>
          next_state <= S0; -- Default state
      END CASE;
    END IF;
  END PROCESS;

  -- Comparator process
comparator: PROCESS(clk, reset)
BEGIN 
  IF reset = '1' THEN
    All_7 <= (OTHERS => '0'); -- Reset all 7
    Max_position <= 0; -- Reset maximum position
    positioncounter <= 0; -- Reset position counter
  ELSIF rising_edge(clk) THEN
    IF resetseven = '1' THEN
      All_7 <= (OTHERS => '0'); -- Reset all 7
      Max_position <= 0; -- Reset maximum position
      positioncounter <= 0; -- Reset position counter
    ELSE
      IF SIGNED(Init_4(31 DOWNTO 24)) > SIGNED(All_7(31 DOWNTO 24)) THEN
        All_7(31 DOWNTO 0) <= Init_4(31 DOWNTO 0); -- Update all 7
        All_7(55 DOWNTO 32) <= (OTHERS => '0'); -- Reset upper bits of all 7
        Max_position <= positioncounter - 1; -- Update maximum position
      ELSIF SIGNED(Init_4(31 DOWNTO 24)) < SIGNED(All_7(31 DOWNTO 24)) THEN
        IF All_7(39 DOWNTO 32) = "00000000" THEN
          All_7(39 DOWNTO 32) <= Init_4(31 DOWNTO 24); -- Update all 7
        ELSIF All_7(39 DOWNTO 32) /= "00000000" AND All_7(47 DOWNTO 40) = "00000000" THEN
          All_7(47 DOWNTO 40) <= Init_4(31 DOWNTO 24); -- Update all 7
        ELSIF All_7(39 DOWNTO 32) /= "00000000" AND All_7(47 DOWNTO 40) /= "00000000" AND All_7(55 DOWNTO 48) = "00000000" THEN
          All_7(55 DOWNTO 48) <= Init_4(31 DOWNTO 24); -- Update all 7
        END IF;
      END IF;
      positioncounter <= positioncounter + 1; -- Increment position counter
    END IF;
  END IF;
END PROCESS;

  
  -- Controls process
  controls: PROCESS(current_state) 
  BEGIN
    CASE current_state IS 
      WHEN S0 =>
        Init_4 <= (OTHERS => '0'); -- Reset initialisation signal
        dataReady <= '0'; -- Reset data ready signal
        seqDone <= '0'; -- Reset sequence done signal
        Counter <= 0;  -- Reset counter
        maxIndex <= (OTHERS => (OTHERS => '0')); -- Reset maximum index
        resetseven <= '1'; -- Set reset seven signal
      WHEN S1 =>
        dataReady <= '0'; -- Reset data ready signal
      WHEN S2 =>
        Ctrl_1_internal <= NOT Ctrl_1_internal; -- Toggle control 1 internal signal
        CtrlOut <= Ctrl_1_internal; -- Update control output
      WHEN S3 =>
        resetseven <= '0'; -- Reset all_7 signal
        CtrlOut <= Ctrl_1_internal; -- Update control output
      WHEN S4 =>
        Init_4(7 DOWNTO 0) <= Init_4(15 DOWNTO 8); -- Shift initialisation signal
        Init_4(15 DOWNTO 8) <= Init_4(23 DOWNTO 16); -- Shift initialisation signal
        Init_4(23 DOWNTO 16) <= Init_4(31 DOWNTO 24); -- Shift initialisation signal
        Init_4(31 DOWNTO 24) <= data; -- Update initialisation signal with data
        dataReady <= '1'; -- Set data ready signal
        Counter <= Counter + 1;  -- Increment counter
      WHEN S5 =>
        byte <= Init_4(31 DOWNTO 24);  -- Update byte with initialisation signal
      WHEN S6 =>
        seqDone <= '1'; -- Set sequence done signal
        dataResults(6) <= All_7(7 DOWNTO 0); -- Update data results
        dataResults(5) <= All_7(15 DOWNTO 8); -- Update data results
        dataResults(4) <= All_7(23 DOWNTO 16); -- Update data results
        dataResults(3) <= All_7(31 DOWNTO 24); -- Update data results
        dataResults(2) <= All_7(39 DOWNTO 32); -- Update data results
        dataResults(1) <= All_7(47 DOWNTO 40); -- Update data results
        dataResults(0) <= All_7(55 DOWNTO 48); -- Update data results
        maxIndex(0) <= STD_LOGIC_VECTOR(TO_UNSIGNED(Max_position mod 10, 4));
        maxIndex(1) <= STD_LOGIC_VECTOR(TO_UNSIGNED(Max_position/10 mod 10, 4));
        maxIndex(2) <= STD_LOGIC_VECTOR(TO_UNSIGNED(Max_position/100 mod 10, 4));
      WHEN OTHERS =>
        NULL; -- To catch it
    END CASE;
  END PROCESS;

END Behavioral;