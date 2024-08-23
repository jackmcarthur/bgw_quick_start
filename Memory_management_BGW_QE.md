# Managing memory in BerkeleyGW (and QuantumESPRESSO)

GW+BSE calculations are very memory intensive, even by the standards of modern high performance computers. We try to provide accurate memory estimates at the start of each calculation along with warnings if they will exceed available memory, but it is difficult to predict all edge cases resulting from different parallelization schemes, architectures, GPU/CPU functionality, and available libraries. As such, new users may encounter out-of-memory kills or other memory errors in the main BGW executables. Most of the time, these can be resolved by increasing the total amount of memory available (i.e. the number of nodes) and/or revising the parallelization scheme; other times, there are input flags that help minimize the needed memory.

This guide will serve to give some intuition based on the computational scaling of each executable with the GW convergence parameters, as well as additional tips for reducing memory requirements.

## Quantum ESPRESSO parallelization advice

The PWscf package distributed with Quantum ESPRESSO is a highly capable CPU+GPU+MPI+OpenMP enabled code known widely for its many levels of parallelization. The BerkeleyGW development team does not actively maintain QE and cannot always answer questions, but here we attempt to help users avoid a few common problems in the QE->BGW workflow that stem from asking PWscf to calculate something it is not always optimized for--calculating hundreds or thousands of empty bands. The `pw.x` documentation of its parallelization levels is found [here](https://www.quantum-espresso.org/Doc/user_guide/node20.html), and here is [a summer school presentation](https://indico.ictp.it/event/9616/session/53/contribution/89/material/slides/0.pdf) which gives a lot of background about the memory and communication loads of the main parallelization levels.

First: running out of memory in QE:
```
typical segfault or OOM kill
```
Using too many MPI tasks/poor parallelization strategy:
```
MPICH ERROR [Rank 1] [job id 29698631.0] [Fri Aug 23 13:52:04 2024] [nid006232] - Abort(604933) (rank 1 in comm 0): Fatal error in PMPI_Comm_free: Invalid communicator, error stack:
PMPI_Comm_free(139): MPI_Comm_free(comm=0x7ffc43a888a0) failed
PMPI_Comm_free(86).: Null communicator
```

Most QE->BGW calculations are on systems with O(10-100) symmetry reduced k-points and O(100-5000) bands. Parallelization over k-points is trivial in QE, but the diagonalization of H at a single k-point is often slow and may only scale up to 10-50 MPI tasks before saturating. In order to minimize wall time without exceeding available memory, one must optimize an MPI/OpenMP parallelization strategy over plane waves, task groups, subspace diagonalization groups, and OpenMP threads.

WIP:

`pw.x` for QE->BGW users has four parallelization flags that can group MPI tasks, as well as PW parallelization and OpenMP threads.
* `-npools`: number of pools of k-points
  * Maximum value: number of irreducible k-points
  * Maximum processers per pool: no limit
* `-nband`: number of pools for KS orbitals
  * Can accelerate calculations somewhat, but does not reduce memory.
* PW parallelization: not a flag, default parallelization for any levels not specified
  * Maximum value: often 8-16
* `-ntg`: number of task groups for FFTs
  * For when there are a large number of processors and PW parallelization is maxed out. High communication load, only recommended up to 4 task groups (for very large numbers of procs.)
* `-ndiag`: number of processors for diagonalizing the subspace Hamiltonian
  * Optimal value: depends on linear algebra solver (ELPA, ScaLAPACK...), always a square number, usually between 1 and 144.
* OpenMP threads
  * Maximum value: 4-8 per processor


### QE 7.x, GPU version
We recommend using the GPU version of QE when possible, as GPU offloading provides a significant speedup to all `pw.x` runs and circumvents memory bottlenecks associated with typical QE->BGW calculations.

For a bog-standard QE->BGW coarse grid calculation (O(10-100) symmetry reduced k-points, O(100-5000) bands, and O(1-10) GPU nodes):
* Set `-npools` to the number of nodes, so that each node handles one k-point at a time.
* Set `-ndiag` to `1`, 

#### QE 7.x, CPU version

By default, Q
