# bgw_quick_start
Markdown pages meant to serve as a quick start guide to using BerkeleyGW to calculate one's own materials.

# GW calculations on your own materials: quick start guide

This guide is meant to give the reader an understanding of those parts of the mean field -> GW (-> BSE) workflow codes that vary on a material-dependent basis. Before performing calculations on your own materials, we strongly recommend performing some of the example calculations found on the website from our [most recent tutorial workshop](https://workshop.berkeleygw.org/tutorial-workshop/about). When moving on to your own materials of interest, you can adapt input files from the tutorial most similar to your desired calculation as a starting point (i.e. the hBN/MoS2 tutorials for 2D materials, the sodium tutorial for calculations of metals, the SOC tutorial for fully-relativistic calculations...). Some other example input files can be found in the [BerkeleyGW examples repository](https://github.com/BerkeleyGW/BerkeleyGW-examples/tree/master) or even the [test suite](https://github.com/BerkeleyGW/BerkeleyGW/tree/master/testsuite).

There are two classes of parameters that aspiring BerkeleyGW users need to vary on a material-dependent basis: **calculation settings**, the input flags which switch different routines on and off in the code, and **convergence parameters**, the input flags with values that are varied to trade off between computational cost and accuracy. Discussions of all of these quantities (and most of the information in this guide) can be found in the presentations from the [most recent tutorial workshop](https://workshop.berkeleygw.org/tutorial-workshop/about).


## Mean field calculations

All calculations in BerkeleyGW must begin with mean-field calculations in one of our [supported DFT codes](http://manual.berkeleygw.org/4.0/meanfield/), followed by conversion to one of the BerkeleyGW wavefunction formats, `WFN` (a Fortran binary) or `WFN.h5` (an HDF5 file, which maximizes I/O performance), along with other supplementary files (`RHO`...). BerkeleyGW supports a wide variety of material-specific features found in modern DFT codes, including spin-polarized and non-collinear spinor wavefunctions, meta-GGA and hybrid functionals, and DFT+U.

Essential settings in mean field input files:

#### Pseudopotentials

* You must use norm conserving pseudopotentials, not PAW or ultrasoft. We recommend those from [Pseudo Dojo](http://www.pseudo-dojo.org/).

* Norm conserving pseudopotentials require larger wavefunction cutoffs than PAW/ultrasoft. We recommend a 100 Ry cutoff for wavefunctions and 400 Ry for the charge density (or 80 Ry/320 Ry for more intensive computations). This is `ecutwfc = 80.0` in Quantum ESPRESSO (QE).

#### K-grids

* k-point grids in bands calculations must be generated with `kgrid.x`, to be compatible with the symmetries used in BGW. For QE, this can be done quickly with the `data-file2kgrid.py` utility:

  1. Run an SCF calculation with an 'automatic' grid.

  2. Generate a gamma-centered 6x6x6 k-grid (for `WFN`) via:
  ```bash
  python data-file2kgrid.py --kgrid 6 6 6 data-file-schema.xml kgrid.inp
  kgrid.x kgrid.inp kgrid.out kgrid.log
  ```

  3. Generate a 6x6x6 k-grid shifted along $b_1$ (for `WFNq`) via:
  ```bash
  python data-file2kgrid.py --kgrid 6 6 6 --kshift 0.001 0.0 0.0 data-file-schema.xml kgridq.inp
  kgrid.x kgridq.inp kgridq.out kgridq.log
  ```
  4. Use these grids in the `bands` calculations used for `WFN` and `WFNq`.
*  See tutorials, but note that semiconductors and insulators can generally be calculated with somewhat coarse k-grids. Metals however require very fine k-grid sampling to resolve the Fermi surface. `Epsilon` and `Sigma` are compatible with

#### Magnetism and spin orbit coupling
* BerkeleyGW is compatible with spin-polarized and non-collinear spinor wavefunctions with no additional flags as long as the mean-field wrapper being used supports them, which is currently the case for `pw2bgw`. Simply include compatible flags and pseudopotentials in your mean field input. Be aware that the GW formalism as implemented assumes time-reversal symmetry, but in testing we have seen that the error caused by this assumption is very small.

#### 2D and 1D materials
* Review the [tutorial workshop's presentations](https://workshop.berkeleygw.org/tutorial-workshop/about) for information about convergence in low-dimensional systems. These calculations are harder to converge due to the behavior of the dielectric function in low dimensions.
* Use the `surface.x` code to find the size of your unit cell necessary for convergence. Aperiodic cell dimensions should be twice those of the 99% charge density isosurface.
  * *Directly use the value in a.u. outputted by `surface.x`. It has already been doubled.*
* In 2D systems, the z direction must be aperiodic. In 1D systems, the z direction must be periodic (x and y aperiodic).
* The only necessary changes to BerkeleyGW input files are `cell_slab_truncation` or `cell_wire_truncation` to truncate the Coulomb interaction. Note also for QE users that QE has an `assume_isolated` flag which truncates the Coulomb interaction also. This may slightly improve wavefunction quality for these systems.

#### Molecules/isolated systems
* Molecules are somewhat special even among low dimensional systems. Use the `cell_box_truncation` flag for the Coulomb interaction, and there is no need for a `WFNq` file in the calculation, only the `WFN` file with k-point $k=(0,0,0)$.
* Molecules often require many thousands of unoccupied bands to converge the GW quasiparticle energies. Parabands (with stochastic pseudobands) is extra-strongly recommended to accelerate the calculations in these cases.
* QP energies of molecules are more likely to benefit from full-frequency GW calculations (`frequency_dependence 2`), and BSE calculations are also more likely to require non-Tamm Dancoff Approximation BSE calculations (`extended_kernel`). Consult the literature to make an informed choice.
* Look at the benzene tutorial example to learn how to correct the DFT eigenvalues for the vacuum level. This involves the flag `avgpot [float]`. 

#### Systems with implicit doping
* The Fermi level in all input files can be set with `fermi_level [value in eV]`. Higher k-point sampling may be needed to resolve the Fermi surface in the presence of doping, and plasmon-pole approximations may be inadequate; full-frequency GW calculations may be necessary. Recent work by [Champagne et al.](https://pubs.acs.org/doi/10.1021/acs.nanolett.3c00386) may be helpful.



#### DFT+U, Meta-GGA and hybrid functionals
* BerkeleyGW can be used with Meta-GGA and hybrid functionals with certain settings fixed: check the [`pw2bgw.x` input documentation](http://manual.berkeleygw.org/4.0/pw2bgw-input/) for relevant flags.
* In particular, we recommend using the `kih.dat` file rather than `vxc.dat` with the flag `kih_file=.true.` Run `pw2bgw.x` in serial when writing `kih.dat`, and use `use_kih_dat / dont_use_vxcdat` in `sigma.inp`.
  * Why this difference? Note $E^{DFT}=K+I+H+V_{xc}(+ V_{hub})$ ($K$ = kinetic energy, $I$ = ionic potential energy, $H$ = Hartree energy, $V_{xc}$ = exchange-correlation energy, $V_{hub}$ = Hubbard U energy). Since $E^{GW} = K + I + H + \Sigma^{GW}$, we need to subtract off the $V_{xc}$ energy (and $V_{hub}$ if present) to obtain the correct QP energies in `Sigma`. Older versions of BerkeleyGW only accounted for $V_{xc}$, writing $\langle nk | V_{xc} | nk \rangle$ to `vxc.dat`. Now that newer functionals include exact exchange or Hubbard contributions, we are switching over to writing $K+I+H$ to `kih.dat`.
  * Although we recommend using `kih.dat` for `Sigma`, the `pw2bgw.x` input documentation also shows an option to write $V_{hub}$ to the file `vhub.dat`, which may be useful for analysis. Be aware that if DFT+U+J+V is used, only the U energy is written to file. (+J+V is compatible with `kih.dat`.)

#### Tips for advanced users:
* Convert the `WFN`/`WFNq` files to the HDF5 format with `wfn2hdf.x BIN WFN WFN.h5`, then add the `use_wfn_hdf5` flags to `epsilon.inp`,`sigma.inp`, etc. This allows for faster I/O.
* Use [Parabands with Stochastic Pseudobands](http://manual.berkeleygw.org/4.0/parabands-overview/), a module inside BerkeleyGW to effectively compress hundreds of unoccupied bands in `WFN.h5` by a factor of >50. This is a new and exciting feature in BerkeleyGW that can speed up `epsilon`/`sigma` calculations by 10x-1000x. (There are two ways to use pseudobands: the first is to perform a QE calculation on the occupied bands + at least one unoccupied band, then use the Parabands Fortran module with the input files above. This is generally faster than QE but is not compatible with DFT+U or hybrid functionals. For those cases, you can calculate all desired band with QE and use `pseudobands.py` to compress the QE wavefunctions; this works in all cases).


## Epsilon
* There are three possible values for the `frequency_dependence` flag. The default is to calculate only the zero-frequency dielectric matrix. This is used in the Hybertsen-Louie Generalized Plasmon Pole Model (GPP), which offers ~0.1-0.2 eV accuracy of the QP energies near the Fermi energy at low cost. Another option is to compute the two frequencies used by the Godby-Needs Plasmon Pole Model, which is known to perform better in certain systems with localized electrons, see [[1]](https://journals.aps.org/prb/pdf/10.1103/PhysRevB.88.125205) and other literature. Full frequency calculations calculate the dielectric matrix across the whole frequency range, increasing accuracy and giving access to spectral functions and lifetimes. It is also more accurate further from the Fermi energy and in systems with localized d/f electrons, though it has a much greater cost. 

## Sigma
* The (default) static remainder option in the code extrapolates trends from the finite sum-over-bands to the infinite sum limit. It is recommended in all cases.
