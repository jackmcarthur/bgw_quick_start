# bgw_quick_start
Markdown pages meant to serve as a quick start guide to using BerkeleyGW to calculate one's own materials.

# GW calculations on your own materials: quick start guide

This guide is meant to give the reader an understanding of those parts of the mean field -> GW (-> BSE) workflow codes that vary on a material-dependent basis. Before performing calculations on your own materials, we strongly recommend performing some of the example calculations found on the website from our [most recent tutorial workshop](https://workshop.berkeleygw.org/tutorial-workshop/about). When moving on to your own materials of interest, you can adapt input files from the tutorial most similar to your desired calculation as a starting point (i.e. the hBN/MoS2 tutorials for 2D materials, the sodium tutorial for calculations of metals, the SOC tutorial for fully-relativistic calculations...). Some other example input files can be found in the [BerkeleyGW examples repository](https://github.com/BerkeleyGW/BerkeleyGW-examples/tree/master) or even the [test suite](https://github.com/BerkeleyGW/BerkeleyGW/tree/master/testsuite).

There are two classes of parameters that aspiring BerkeleyGW users will need to change for each material considered: **physical parameters** and **convergence parameters**. Discussions of all of these quantities (and most of the information in this guide) can be found in the presentations from the [most recent tutorial workshop](https://workshop.berkeleygw.org/tutorial-workshop/about).


## Mean field calculations

All calculations in BerkeleyGW must begin with mean-field calculations in one of our [supported DFT codes](http://manual.berkeleygw.org/4.0/meanfield/), followed by conversion to one of the BerkeleyGW wavefunction formats, `WFN` (a Fortran binary) or `WFN.h5` (an HDF5 file, which maximizes I/O performance), along with other supplementary files (`RHO`...). BerkeleyGW supports a wide variety of material-specific features found in modern DFT codes, including spin-polarized and non-collinear spinor wavefunctions, meta-GGA and hybrid functionals, and DFT+U.

Essential settings in mean field input files:

* You must use norm conserving pseudopotentials, not PAW or ultrasoft. We recommend those from [Pseudo Dojo](http://www.pseudo-dojo.org/).

* Norm conserving pseudopotentials require larger wavefunction cutoffs than PAW/ultrasoft. We recommend a 100 Ry cutoff for wavefunctions and 400 Ry for the charge density (or 80 Ry/320 Ry for more intensive computations). This is `ecutwfc = 80.0` in QE.

* k-point grids in bands calculations must be generated with `kgrid.x`, to be compatible with the symmetries used in BGW. For QE, this can be done quickly with the `data-file2kgrid.py` utility:

  1. Run an SCF calculation with an 'automatic' grid.

  2. Generate a gamma-centered 6x6x6 k-grid (for `WFN`) via:
  ```python
  python data-file2kgrid.py --kgrid 6 6 6 data-file-schema.xml kgrid.inp
  kgrid.x kgrid.inp kgrid.out kgrid.log
  ```

  3. Generate a 6x6x6 k-grid shifted along $b_1$ (for `WFNq`) via:
  ```python
  python data-file2kgrid.py --kgrid 6 6 6 --kshift 0.001 0.0 0.0 data-file-schema.xml kgridq.inp
  kgrid.x kgridq.inp kgrid.out kgrid.log
  ```
  4. Use these grids in the `bands` calculations used for `WFN` and `WFNq`.
