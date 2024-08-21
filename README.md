# bgw_quick_start
Markdown pages meant to serve as a quick start guide to using BerkeleyGW to calculate one's own materials.

# GW calculations on your own materials: quick start guide

This guide is meant to give the reader an understanding of those parts of the mean field -> GW (-> BSE) workflow codes that vary on a material-dependent basis. It is intended for readers with basic comprehension of the GW-BSE method who have performed some of the example calculations on the website of our [most recent tutorial workshop](https://workshop.berkeleygw.org/tutorial-workshop/about). When moving on to materials of interest, consider adapting input files from the tutorial most similar to your desired calculation as a starting point (e.g. the hBN/MoS2 tutorials for 2D materials, the sodium tutorial for calculations of metals, the SOC tutorial for fully-relativistic calculations...). Some other example input files can be found in the [BerkeleyGW examples repository](https://github.com/BerkeleyGW/BerkeleyGW-examples/tree/master) or even the [test suite](https://github.com/BerkeleyGW/BerkeleyGW/tree/master/testsuite).

There are two classes of parameters that aspiring BerkeleyGW users need to vary on a material-dependent basis: **calculation settings**, the input flags which switch different routines on and off in the code, and **convergence parameters**, the input flags with values that are varied to trade off between computational cost and accuracy. Discussions of all of these quantities (and most of the information in this guide) can be found in the presentations from the [most recent tutorial workshop](https://workshop.berkeleygw.org/tutorial-workshop/about).


## Mean field calculations

All calculations in BerkeleyGW must begin with mean-field calculations in one of our [supported DFT codes](http://manual.berkeleygw.org/4.0/meanfield/), followed by conversion to one of the BerkeleyGW wavefunction formats, `WFN` (a Fortran binary) or `WFN.h5` (an HDF5 file, which maximizes I/O performance), along with other supplementary files (`RHO`...). BerkeleyGW supports a wide variety of material-specific features found in modern DFT codes, including spin-polarized and non-collinear spinor wavefunctions, meta-GGA and hybrid functionals, and DFT+U.

### Essential settings in mean field input files:

#### Pseudopotentials

* You must use norm conserving pseudopotentials, not PAW or ultrasoft. We recommend those from [Pseudo Dojo](http://www.pseudo-dojo.org/).

* Norm conserving pseudopotentials require larger wavefunction cutoffs than PAW/ultrasoft. We recommend a 100 Ry cutoff for wavefunctions and 400 Ry for the charge density (or 80 Ry/320 Ry for more intensive computations). This is `ecutwfc = 80.0` in Quantum ESPRESSO (QE).

#### K-grids

* k-point grids in bands calculations must be generated with `kgrid.x`, to be compatible with the symmetries used in BGW. For QE, this can be done quickly with the `data-file2kgrid.py` utility:

  1. Run an SCF calculation with an 'automatic' grid.

  2. Generate a gamma-centered 6x6x6 k-grid (for `WFN`) via:
  ```sh
  python data-file2kgrid.py --kgrid 6 6 6 data-file-schema.xml kgrid.inp
  kgrid.x kgrid.inp kgrid.out kgrid.log
  ```

  3. Generate a 6x6x6 k-grid shifted along $b_1$ (for `WFNq`) via:
  ```sh
  python data-file2kgrid.py --kgrid 6 6 6 --qshift 0.001 0.0 0.0 data-file-schema.xml kgridq.inp
  kgrid.x kgridq.inp kgridq.out kgridq.log
  ```
  4. Use these grids in the `bands` calculations used for `WFN` and `WFNq`.
*  See tutorials, but note that semiconductors and insulators can generally be calculated with somewhat coarse k-grids. Metals however require very fine k-grid sampling to resolve the Fermi surface. `Epsilon` and `Sigma` are also compatible with occupation smearing, though note the treatment is somewhat simple (occupations < 0.95 are considered unoccupied).


<details>
<summary><b>How do I set up the k/q-grids in `epsilon.inp`/`sigma.inp`?</b> (click for dropdown)</summary>
<br>
Once both kgrids for `WFN` and `WFNq` have been generated, do the following to generate the q-points in `epsilon.inp`:
  
  1. Copy/paste the kgrid from the WFN `pw.x` input file exactly: (q-grid has the same symmetry as the k-grid)
  
```
# contents of epsilon.inp:
(other flags go here)

begin qpoints
  0.000000000  0.000000000  0.000000000  1.0
  0.000000000  0.000000000  0.250000000  3.0
  0.000000000  0.000000000  0.500000000  6.0
  (etc.)
end qpoints
```
  2. Change all QE k-point weights (the fourth column) to 1.0, and add a fifth column of all 0's:
```
# contents of epsilon.inp:
(other flags go here)

begin qpoints
  0.000000000  0.000000000  0.000000000  1.0 0
  0.000000000  0.000000000  0.250000000  1.0 0
  0.000000000  0.000000000  0.500000000  1.0 0
  (etc.)
end qpoints
```
  3. Change the $\Gamma$ k-point to the shifted k-point (in crystal coordinates) in the `WFNq` `pw.x` input file, and change the last column to 1 (indicating to read `WFNq`):
```
# contents of epsilon.inp:
(other flags go here)

begin qpoints
  0.001000000  0.000000000  0.000000000  1.0 1
  0.000000000  0.000000000  0.250000000  1.0 0
  0.000000000  0.000000000  0.500000000  1.0 0
  (etc.)
end
```
  4. The k-grid in `sigma.inp` consists of the same list of points; copy-paste only the first four columns and change the shifted point back to $(0.0, 0.0, 0.0)$. (Remember to change `begin qpoints` to `begin kpoints`).
```
# contents of sigma.inp:
(other flags go here)

begin kpoints
  0.000000000  0.000000000  0.000000000  1.0
  0.000000000  0.000000000  0.250000000  1.0
  0.000000000  0.000000000  0.500000000  1.0
  (etc.)
end
```

*  TODO: pw2bgw kgrid info

A common source of confusion is the convention for shifted k/q-points in `kgrid.inp`, QE input files, `pw2bgw.inp`, `epsilon.inp`, and `sigma.inp`. Consider a system with a 4x4x4 kgrid and a `WFNq` shift along $b_1$.

**Setting the shift in kgrid.x**

In `kgrid.inp` (or `data-file2kgrid.py`), define the shift vector using the q-shift option. The shift will be in **crystal coordinates**. As an example:
<pre>
  # calling data-file2kgrid.py:
  python data-file2kgrid.py --kgrid 6 6 6 <b>--qshift 0.001 0.0 0.0</b> data-file-schema.xml kgridq.inp
  kgrid.x kgridq.inp kgridq.out kgridq.log

  # ----- alternatively at top of kgridq.inp directly: -------
  4   4   4             ! numbers of k-points along b1,b2,b3
  0.0 0.0 0.0           ! "offset": units of k-grid steps
  <b>0.0 0.0 0.001</b>         ! "q-shift": units of crystal coordinates
  (rest of kgridq.inp goes here)
</pre>
The output will be:
```
K_POINTS crystal
  (number of symmetry-reduced k-points)
  0.001000000  0.000000000  0.000000000  1.0
  0.001000000  0.000000000  0.250000000  1.0
  0.001000000  0.000000000  0.500000000  1.0
  (etc.)
```
In `pw2bgw.inp`, the grid shift defined by `dk1` should be defined in **units of the distance between k-points**, so you would put:
```
(...)
nk1 = 4
nk2 = 4
nk3 = 4
dk1 = 0.004
dk2 = 0.0
dk3 = 0.0
(...)
```
This will create a grid shifted by **four thousandths of the x-distance between two k-points in a 4x4x4 grid, or one thousandth of $b_1$**.
In `epsilon.inp`, the k-points are provided in crystal coordinates, so you would put `0.001000000  0.000000000  0.000000000  1.0 1` as the first k-point.

(random shift for absorption with kshift goes here...)
<br>
</details>




### Considerations for certain systems:

#### Magnetism and spin orbit coupling
* BerkeleyGW is compatible with spin-polarized and non-collinear spinor wavefunctions with no additional flags as long as the mean-field wrapper being used supports them, which is currently the case for `pw2bgw`. Simply include compatible flags and pseudopotentials in your mean field input. Be aware that the GW formalism as implemented assumes time-reversal symmetry, but in testing we have seen that the error caused by this assumption is very small.
* For spin-polarized calculations (those using scalar relativistic pseudopotentials and `nspin = 2` in Quantum ESPRESSO, *not* spinor calculations, `nspin=4`), you will need to set:
```
spin_index_min 1
spin_index_max 2
```
in `sigma.inp` to generate QP corrections for both spins, as the default is the first spin only.

#### 2D and 1D materials
* Review the [tutorial workshop's presentations](https://workshop.berkeleygw.org/tutorial-workshop/about) for information about convergence in low-dimensional systems. These calculations are harder to converge due to the behavior of the dielectric function in low dimensions; the NNS and CSI methods are recommended to improve convergence.
* Use the `surface.x` code to find the size of your unit cell necessary for convergence. Aperiodic cell dimensions should be twice those of the 99% charge density isosurface.
  * *Directly use the value in a.u. outputted by `surface.x`. It has already been doubled.*
* In 2D systems, the z direction must be aperiodic. In 1D systems, the z direction must be periodic (x and y aperiodic).
* The only necessary changes to BerkeleyGW input files are `cell_slab_truncation` or `cell_wire_truncation` to truncate the Coulomb interaction. Note also for QE users that QE has an `assume_isolated` flag which truncates the Coulomb interaction also. This may slightly improve wavefunction quality for these systems.

#### Molecules/isolated systems
* Molecules are somewhat special even among low dimensional systems. Use the `cell_box_truncation` flag for the Coulomb interaction, and there is no need for a `WFNq` file in the calculation, only the `WFN` file with k-point $k=(0,0,0)$.
* Molecules often require thousands of unoccupied bands to converge the GW quasiparticle energies. Parabands (with stochastic pseudobands) is extra-strongly recommended to accelerate the calculations in these cases.
* It is known that QP energies of molecules are more likely to benefit from full-frequency GW calculations (`frequency_dependence 2`), and absorption spectra are also more likely to benefit from non-Tamm Dancoff Approximation BSE calculations (`extended_kernel` in `kernel.inp` and `full_bse` in `absorption.inp`). Consult the literature to make an informed choice.
* Look at the benzene tutorial example to learn how to correct the DFT eigenvalues for the vacuum level. This involves the flag `avgpot [float]`.

#### Interfaces and systems adsorbed to a surface or screened by a solvent
The GW approximation is often used to calculate the QP energy levels and absorption spectra of molecules or other materials adsorbed to a surface or slab. This is most often done to simulate the environmental screening in an experiment accurately or for studies relevant to catalysis. A naive method to do this is to explicitly incorporate several layers of the surface in your GW/BSE calculation (which can be expensive, and will overlay the bands of your system of interest with those of the substrate). BerkeleyGW 4.0 has some new features that allow one to calculate the polarizability of a surface via an `Epsilon` calculation and add this to the screening of your molecule/system of interest via the `read_chi_add` flag. See documentation for `Epsilon`, as well as features in JDFTx that allow for a fluid polarizability to be used. This will give the molecular QP energy levels in the presence of the environmental screening, though it will neglect wavefunction hybridization between substrate and absorbant.

#### Metallic and semimetallic systems
* By default, BerkeleyGW assumes that systems have a band gap. For metallic systems, specify `screening_metal` in `Sigma`, `Kernel,` and `Absorption` to treat the q->0 limit of the dielectric function correctly.
* ** need to check with other developers: Kernel and Absorption have the `screening_metal` flag in the documentation, but BSE calculations on metals are said not to be supported.
* Be aware that metals/semimetals require much denser k-grids than semiconductors/insulators to converge the Fermi surface. See the literature; a 16x16x16 k-grid is a typical starting point for some simple metals.
* `Inteqp` may not work for metals, making it difficult to obtain a plottable bandstructure. You can try the flag `unrestricted_transformation` for a possible workaround, manually sample points from the `eqp1.dat` grid, or use Wannier90 instead to interpolate the bandstructure; see the [sig2wan utility](http://manual.berkeleygw.org/4.0/sig2wan-input/) and [a provided example](https://github.com/BerkeleyGW/BerkeleyGW-examples/tree/master/DFT/silicon).
* BerkeleyGW 4.0 allows for occupation smearing in metals to be used in the `Epsilon` and `Sigma` calculations. Setting `wfng_occupation = .true.` in `pw2bgw.inp` is recommended to write the smeared occupations used by QE to the `WFN` file, then no other flags are needed in `Epsilon` and `Sigma`. You can also have BerkeleyGW recalculate its own broadening and/or modify the Fermi level by setting `occ_broadening` and `fermi_level_absolute`; see `Epsilon` documentation.
* The dielectric function in metals may differ significantly from those predicted in plasmon-pole approximations. Full-frequency calculations are recommended; they are rigorously correct in these cases.
* Although dense k-grids and full-frequency calculations have a large additional cost, this is slightly offset since QP energies in metals converge with fewer bands in `Epsilon`/`Sigma`, often 300-500 for small systems. This is because the screening is dominated by a small number of mostly intraband transitions.

#### Systems with implicit doping
* The Fermi level in all input files can be set with `fermi_level [value in eV]`. Denser k-point sampling is needed to resolve the Fermi surface in the presence of doping, and plasmon-pole approximations may be inadequate; full-frequency GW calculations may be necessary. Recent work by [Champagne et al.](https://pubs.acs.org/doi/10.1021/acs.nanolett.3c00386) may be helpful.

#### DFT+U, meta-GGA and hybrid functionals
* For correlated systems, DFT+U and meta-GGA/hybrid functionals are often used to improve the quality of your mean-field wavefunctions. BerkeleyGW can be used with DFT+U and meta-GGA/hybrid functionals with certain inputs fixed: check the [`pw2bgw.x` input documentation](http://manual.berkeleygw.org/4.0/pw2bgw-input/) for relevant flags.
* In particular, note the use of the `kih.dat` file rather than `vxc.dat` with the flag `kih_file=.true.` Run `pw2bgw.x` in serial when writing `kih.dat`, and use `use_kih_dat / dont_use_vxcdat` in `sigma.inp`.
  * Why this difference? Note $E^{DFT}=K+I+H+V_{xc}(+ V_{hub})$ ($K$ = kinetic energy, $I$ = ionic potential energy, $H$ = Hartree energy, $V_{xc}$ = exchange-correlation energy, $V_{hub}$ = Hubbard U energy). Since $E^{GW} = K + I + H + \Sigma^{GW}$, we need to subtract off the $V_{xc}$ energy (and $V_{hub}$ if present) to obtain the correct QP energies in `Sigma`. Older versions of BerkeleyGW only accounted for $V_{xc}$, writing $\langle nk | V_{xc} | nk \rangle$ to `vxc.dat`. Now that newer functionals include exact exchange or Hubbard contributions, we are switching over to writing $K+I+H$ to `kih.dat`.
  * Although we recommend using `kih.dat` for `Sigma`, the `pw2bgw.x` input documentation also shows an option to write $V_{hub}$ to the file `vhub.dat`, which may be useful for analysis. Be aware that if DFT+U+J+V is used, only the U energy is written to file. (+J+V is still compatible with `kih.dat`.)
* BerkeleyGW calculations can be performed on top of hybrid functionals, using `pw2bgw.x` with `kih.dat`, however, their functionality is somewhat limited in QE (no nscf calculations are available). `WFN` and `WFNq` files must be generated by two separate scf calculations, and workarounds are necessary to obtain a bandstructure along a k-path for plotting. [See BerkeleyGW+HSE example here.](https://github.com/BerkeleyGW/BerkeleyGW-examples/tree/master/DFT/silicon_HSE06_KIH)

#### Strongly correlated systems (transition metal oxides, etc.)
* For transition metal oxides or other correlated d/f block systems, see the literature for convergence parameters of systems similar to your own:
    * Large screened cutoffs of 30-40 Ry are necessary for the `Epsilon` and `Sigma` codes.
    * For the kernel calculation, a separate `Epsilon` calculation can be done with a cutoff of <~20 Ry to reduce costs, as the very-low-G-vector screening dominates.
    * Thousands of bands are generally needed for convergence of QP energies, and as such Parabands with stochastic pseudobands is recommended.
* The default QP energy calculation in BerkeleyGW is a "single-shot" $G_0W_0$ calculation, where the dielectric function and QP energies are calculated for the provided DFT wavefunctions. For correlated systems, $G_0W_0$ can be inadequate to capture the quasiparticle band gap if the DFT wavefunctions are far from the physical ones. Self-consistent updates of the QP wavefunctions and energies ('self consistent GW') may improve the quality of the QP bandstructure; the tool `Sigma/scGWtool.py` can be used to update the wavefunctions in a subspace for multiple self-consistent iterations of `Epsilon`/`Sigma`.
    * Self-consistent GW is known to systematically overestimate band gaps due to the compounding of approximations made in the GW method (the random phase approximation, neglecting vertex corrections). It is not necessarily preferable to $G_0W_0$, which is known to have some fortuitous error cancellation.
    * There are many techniques used to do self-consistent GW, consult the literature for more information. The default option with `scGWtool.py` is to perform "$QSGW_0$" calculations (repeat `Sigma` with updated wavefunctions/eigenvalues while leaving the dielectric matrix fixed from DFT). Fully self-consistent "QSGW" (repeating both `Epsilon` and `Sigma`) is also possible, but note that the charge density `RHO` and `WFNq` files are not updated with the wavefunctions; unless treated manually, use of these DFT files is another approximation.

## Epsilon
* There are three possible values for the `frequency_dependence` flag. The default `0` is to calculate only the zero-frequency dielectric matrix. This is used in the Hybertsen-Louie Generalized Plasmon Pole Model (HL-GPP), which offers ~0.1-0.2 eV accuracy of the QP energies near the Fermi energy at low cost. Another option, `3`, is to compute the two frequencies used by the Godby-Needs Plasmon Pole Model, which is known to perform better in certain systems with localized electrons, see [[1]](https://journals.aps.org/prb/pdf/10.1103/PhysRevB.88.125205) and other literature. Full frequency calculations, `2`, calculate the dielectric matrix across the whole frequency range, increasing accuracy and giving access to spectral functions and lifetimes. It is also more accurate further from the Fermi energy and in systems with localized d/f electrons, though it has a much greater cost. However, the Static Subspace Approximation (SSA) (see `Epsilon` documentation) can allow for full-frequency calculations with only a small overhead compared to the HL-GPP.
* If an `Epsilon` calculation is killed by a time limit or a crash before finishing, it can be restarted from the last q-point calculated by adding the flag `restart` to `epsilon.inp`. This requires `WFN` and `WFNq` to be in the HDF5 format (convert with `wfn2hdf.x BIN WFN(q) WFN(q).h5` and add flag `use_wfn_hdf5` to `epsilon.inp`).

## Sigma
* The (default) static remainder option in the code extrapolates $\Sigma_{nk}$ from the finite sum-over-bands to the infinite sum limit. It is recommended in all cases.
* There is no `restart` feature in `sigma.inp`, however, QP energies are written to `eqp1.dat` one k-point at a time. If the `Sigma` job dies before finishing, you can save `eqp1.dat` from the first run, do another run for only the incomplete k-points from `sigma.inp`, and then copy-paste each `eqp1.dat` into one final file at the end. (It may also be useful to save `sigma_hp.log` from each run if you want to analyze it and/or use self consistent GW.)
* If you use a different frequency dependence model in `Epsilon` than the HL-GPP (the default for both `Epsilon` and `Sigma`), set the value of `frequency_dependence` in `Sigma` as well.

## Kernel

## Absorption
* Exciton binding energies generally converge slowly and non-monotonically with the fine-k-grid size in `WFN_fi`, and the more localized an exciton in k-space, the denser the k-grid must be for convergence. This is especially challenging in certain (low-dimensional) systems like 2D TMDs, where the excitons are tightly localized to the K and K' valleys. The patched sampling feature is useful in these cases.

## Convergence parameters for all systems
*These parameters all vary by system, and convergence should always be tested for novel systems. See the literature and the [tutorial worshop slides](https://workshop.berkeleygw.org/tutorial-workshop/about) for more guidance.*
There is both new and old literature benchmarking GW convergence parameters for different systems; two examples are [this recent work](https://www.nature.com/articles/s41524-024-01311-9) which converges the parameters below for many bulk semiconductors, and [this work](https://pubs.acs.org/doi/full/10.1021/acs.jctc.5b00453) which does the same for the "GW100" set of molecules.
* **Screened Coulomb (G-vector) cutoff for the dielectric matrix/self-energy calculation**: Typical values for ~50 meV accuracy for simple sp semiconductors (without semicore states) are 15-20 Ry. For systems with semicore electrons or d/f electrons, the converged value can be as high as 40-50 Ry.
* **Number of unoccupied bands in the dielectric matrix summation/Coulomb-hole summation**: This scales as the number of atoms in your unit cell, making it hard to give ballpark values, but it is generally larger when atoms with semicore electrons or d/f electrons are present. For silicon (2 atoms in unit cell), 100 bands are necessary for ~50 meV accuracy. For transition metal oxides, 1000+ bands are needed with 3000+ in the most pathological cases. `Epsilon` and `Sigma` can be sped up enormously if you compress the unoccupied bands in the `WFN` file with Stochastic Pseudobands, included with BerkeleyGW.
* **k-grid size**: Typical calculations involve one coarse k/q-grid used in `Epsilon`, `Sigma`, and `Kernel`, and a fine grid used only in `Absorption`. Both of these need to be converged w.r.t. density.
  * It is hard to estimate the k-grid size that a GW calculation will need a priori, since it will depend on unit cell size (larger unit cell = less dense grid), system-dependent screening, and how strongly the $\Sigma$ operator varies in k-space.
    * Coarse k-grid (GW bands, `Kernel`):
      * QP energies of simple bulk (3D) semiconductors (Si, GaN...) often converge somewhere between 4x4x4 and 8x8x8.
      * Simple metals may require 12x12x12 to 20x20x20+ to resolve the Fermi surface.
      * 2D/1D materials may require very dense k-grids due to the complex screening behavior (see tutorial workshop and literature); the NNS method is recommended as it can allow for convergence around 12x12x1 k-grid sizes where 200x200x1+ would be necessary without.
    * Fine k-grid (BSE solutions, `Absorption`)
      * For accurate exciton binding energies, fine k-grids need to be dense enough to resolve the exciton wavefunction in reciprocal space. Very spread out, Wannier-type excitons are very localized in reciprocal space and require dense k-grids. Frenkel excitons are delocalized in reciprocal space and may converge with k-grids close to those above.



## Tips for advanced users:
#### General optimizations for (much) faster calculations:
* Convert the `WFN`/`WFNq` files to the HDF5 format with `wfn2hdf.x BIN WFN WFN.h5`, then add the `use_wfn_hdf5` flags to `epsilon.inp`,`sigma.inp`, etc. This allows for faster I/O.
* Use [Parabands with Stochastic Pseudobands](http://manual.berkeleygw.org/4.0/parabands-overview/), a module inside BerkeleyGW to effectively compress hundreds of unoccupied bands in `WFN.h5` by a factor of >50. This is a new and exciting feature in BerkeleyGW that can speed up `epsilon`/`sigma` calculations by 10x-1000x. (There are two ways to use pseudobands: the first is to perform a QE calculation on the occupied bands + at least one unoccupied band, then use the Parabands Fortran module with the input files above. This is generally faster than QE but is not compatible with DFT+U or hybrid functionals. For those cases, you can calculate all desired band with QE and use `pseudobands.py` to compress the QE wavefunctions; this works in all cases).
* Consider doing full-frequency `Epsilon` calculations using the flags for the [Static Subspace Approximation](http://manual.berkeleygw.org/4.0/epsilon-keywords/#static-subspace-approximation), which allows for the full range of frequencies to be computed at little added cost to the zero-frequency dielectric matrix.
* Use the GPU-accelerated version of the BerkeleyGW code when possible. Architectures vary, but at NERSC Perlmutter it is consistently 5x faster on $N$ GPU-enabled nodes than $N$ CPU-enabled nodes. The ELPA solver if compiled can also accelerate Parabands and Absorption significantly.
#### Other tricks, analyses
* A good way to check the quality of the DFT wavefunctions (and therefore to check if self-consistent GW updates are necessary) is to calculate off-diagonal elements of the self-energy operator using the `sigma_matrix` flag in `Sigma`. You must also use the flags `vxc_offdiag_min` and `vxc_offdiag_max` in `pw2bgw.x`. You can construct and diagonalize the matrix $E_{nk}\delta_{mn} - V_{xc, mnk} + \Sigma_{mnk}$ to find out how much the DFT wavefunctions are mixed by the self-energy operator.
* The k-grid used in `Sigma` does not have to be identical to the q-grid used in `Epsilon`; it only needs to be commensurate. Therefore, one can use a 3x3x3 q-grid in `Epsilon` (in 2D materials, possibly 3x3x1 with NNS) and a 6x6x6 k-grid in `Sigma`. This will sacrifice a little bit of accuracy for computational time, but still converge QP energies carefully throughout the BZ (perhaps if you have a metallic system or many band crossings, or if QP shifts are very non-uniform throughout the BZ).



