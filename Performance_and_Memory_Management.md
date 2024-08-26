Outline attempt:
Guide for the reader advocating for Parabands + Stochastic Pseudobands and the Static-Subspace Approximation on top of full-frequency calcs.

Header: performance comparison of tutorial style calculations and those with pseudobands/sigma+SSA&FF
# Mean field
## Optimal performance with QE
### Parallelization in QE, efficient vs. wall-time optimized
#### CPUs
#### GPUs

## Parabands
### Workflow, inputs, parallelization
### Estimated timing
### Stochastic pseudobands
#### pseudobands.py

## Case study: pure QE vs. parabands
### QE vs. Parabands as fn. of number of bands

# Epsilon 
## Standard parallelization advice
## Case study: Epsilon/QE vs. Epsilon/Pseudobands
## Case study: FF+SSA vs. FF vs. HL-GPP

# Sigma
## Standard parallelization advice
## Case study: Sigma/QE vs. Sigma/Pseudobands
## Case study: Sigma/FF vs. Sigma/HL-GPP (performance focused)

# Kernel
## Standard parallelization advice
## Memory requirements
### Low memory option vs. high memory option

# Absorption
## Standard parallelization advice
## Memory requirements
