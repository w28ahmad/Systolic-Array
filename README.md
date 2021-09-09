# Matrix Multiplication Systolic Array Design 

Designed a Systolic Array using verilog for matrix multiplication. Deployed the design of PYNQ FPGA board for testing. 

## Design Description:
![systolic](img/systolic.png)

- Matrices are streamed through A and B
- pe.v that performs multiply-accumulate operation on streaming signals in_a and in_b.
- After each iteration the results are stored in the RAM block D

## Limitations
- The design was tested on the PYNQ boart at 120MHz with N1 = N2 = 12