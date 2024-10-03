README

1. Overview:  
   This VHDL code implements a data consumption and processing module for a peak detection system. The system operates on a Xilinx Artix 7 FPGA and handles the detection of peaks in a stream of input data while controlling the output sequence based on specific control signals.

2. Libraries and Packages:  
   - `IEEE.STD_LOGIC_1164`: Provides standard logic operations.  
   - `IEEE.NUMERIC_STD`: Enables arithmetic operations for the module.  
   - `COMMON_PACK`: Custom package specific to the project (assumed to contain utility functions and types).

3. Main Functionalities:
   - The system operates in several states (S0 to S6) to process the incoming data and detect peaks.
   - A BCD input (`numWords_bcd`) is converted to decimal and used to control data sequence length.
   - The core logic compares and tracks the maximum values from the input data stream.

4. Inputs and Outputs:
   - **Inputs**: Clock (`clk`), Reset (`reset`), Start signal (`start`), Data (`data`), Control signal (`CtrlIn`).
   - **Outputs**: Control signals (`CtrlOut`), Data Ready (`dataReady`), Output byte (`byte`), Maximum index (`maxIndex`), Data Results (`dataResults`), and Sequence Done (`seqDone`).

5. Target Device:  
   This design is tailored for the Xilinx Artix 7 FPGA platform. The clock frequency used is 12 MHz, and it interfaces with external systems via UART (RS232 protocol).