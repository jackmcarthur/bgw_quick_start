# Managing memory in BerkeleyGW (and QuantumESPRESSO)

GW+BSE calculations are very memory intensive, even by the standards of modern high performance computers. We try to provide accurate memory estimates at the start of each calculation along with warnings if they will exceed available memory, but it is difficult to predict all edge cases resulting from different parallelization schemes, architectures, GPU/CPU functionality, and available libraries. As such, new users may encounter out-of-memory kills or other memory errors in the main BGW executables. Most of the time, these can be resolved by increasing the total amount of memory available (i.e. the number of nodes) and/or revising the parallelization scheme; other times, there are input flags that help minimize the needed memory.

This guide will serve to give some intuition based on the computational scaling of each executable with the GW convergence parameters, as well as additional tips for reducing memory requirements.

## Quantum ESPRESSO parallelization advice

The PWscf package distributed with Quantum ESPRESSO is a CPU+GPU+MPI+OpenMP enabled code with an elaborate parallelization structure. The BerkeleyGW development team does not actively maintain QE and cannot always answer questions, but here we attempt to help users avoid a few common problems in the QE->BGW workflow that stem from asking PWscf to calculate something it is not always optimized for--calculating hundreds or thousands of empty bands. The `pw.x` documentation of its parallelization levels is found [here](https://www.quantum-espresso.org/Doc/user_guide/node20.html), and here are two powerpoint presentations: [a summer school presentation](https://indico.ictp.it/event/9616/session/53/contribution/89/material/slides/0.pdf) and (an HPC workshop presentation)[https://indico.ictp.it/event/a12226/session/133/contribution/81/material/0/0.pdf] which gives a lot of background about the memory and communication loads of the main parallelization levels.

First: running out of memory in QE:
```
typical segfault or OOM kill
```
Can be fi
Using too many MPI tasks/poor parallelization strategy:
```
MPICH ERROR [Rank 1] [job id 29698631.0] [Fri Aug 23 13:52:04 2024] [nid006232] - Abort(604933) (rank 1 in comm 0): Fatal error in PMPI_Comm_free: Invalid communicator, error stack:
PMPI_Comm_free(139): MPI_Comm_free(comm=0x7ffc43a888a0) failed
PMPI_Comm_free(86).: Null communicator
```
This can be due to QE attempting to use `-ndiag > 1` when ScaLAPACK is not enabled correctly; setting `-ndiag 1` explicitly in your `srun` command can resolve the error.



Most QE->BGW calculations are on systems with O(10-100) symmetry reduced k-points and O(100-5000) bands. Parallelization over k-points is trivial in QE, but the diagonalization of H at a single k-point is often slow and may only scale up to 10-50 MPI tasks before saturating. 

In order to minimize wall time without exceeding available memory, one must optimize an MPI/OpenMP parallelization strategy over plane waves, task groups, subspace diagonalization groups, and OpenMP threads.

WIP:

`pw.x` for QE->BGW users has four parallelization flags that can group MPI tasks, as well as PW parallelization and OpenMP threads.
* `-npools`: number of pools of k-points
  * Maximum value: number of irreducible k-points ($N_k$)
  * Optimal values:
    * Typical calculation: same as number of nodes and a divisor of $N_k$ (e.g. 20 k-points: one may use -N 20/-npools 20, or -N 10/-npools 10...)
    * Optimized for wall time: divisor of the number of nodes and a divisor of $N_k$ (e.g. 20 k-points: may use -N 20/-npools 10, -N 10/-npools 5...)
* `-nband`: number of pools for KS orbitals
  * Very useful for hybrid functionals, not useful for LDA/(meta-)GGA calculations.
* `-ntg`: number of task groups for FFTs
  * Maximum value: up to 8 or 16. Best when there are a large number of processors so that PW parallelization is maxed out. 
  * Optimal value: 1 when PW parallelization not maxed out ($N_{PW}=N_3$), and 2 or 4 (
* PW parallelization: parallelization over G-vectors within a task group. Not a flag, default parallelization for any levels not specified
  * Maximum value: $N_3$, the number of plane waves in the z direction of the FFT grid. (Likely between 20 and 100).
  * Optimal value: divisor of $N_3$
* `-ndiag`: number of processors within a task group used to diagonalize the subspace Hamiltonian. (Other procs in task group are not used during this step)
  * Maximum value: Largest square integer less than the number of procs. in a task group.
  * Optimal value: depends on linear algebra solver (ELPA, ScaLAPACK...), always a square number, usually between 1 and 144.
* OpenMP threads
  * Maximum value: 4-8 per processor
  * Optimal value: commonly 2

### QE default parallelization
When running QE on $X$ nodes with $X*Y$ CPUs, submit a job like:
```
srun -N X --ntasks-per-node Y/2 -c 2 pw.x -input bands.in > bands.out -npools X
```
For generally good performance with $X < N_{kpts}$. The code will divide the processors into as many PW parallelization groups and task groups as possible. If you run into memory issues, try adding `-ndiag 1` to the end of the `srun` line.

To reduce wall time further (at the expense of imperfect scaling), you can use multiple nodes per k-point by choosing an `-npools` that evenly divides both $N_{kpts}$ and $X$ (revise*). With fast inter-node communication this is minimally an issue, as long as $Y$ is not greater than $~N_3 * 16$.

### Simple QE parallelization
To get a QE calculation to run without giving an OOM kill or other error, 

### Advanced: fine-grained QE parallelization


### QE 7.x, GPU version
We recommend using the GPU version of QE when possible, as GPU offloading provides a significant speedup to all `pw.x` runs and circumvents memory bottlenecks associated with typical QE->BGW calculations.

For a bog-standard QE->BGW coarse grid calculation (O(10-100) symmetry reduced k-points, O(100-5000) bands, and O(1-10) GPU nodes):
* Set `-npools` to the number of nodes, so that each node handles one k-point at a time.
* Set `-ndiag` to `1`, 

#### QE 7.x, CPU version

By default, Q
