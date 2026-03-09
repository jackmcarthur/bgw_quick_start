#!/bin/bash

# convert WFN files to HDF5 format.
module load berkeleygw/4.0-cpu
wfn2hdf.x BIN 2.1-wfn/WFN 2.1-wfn/WFN.h5
wfn2hdf.x BIN 2.2-wfnq/WFN 2.2-wfnq/WFN.h5

cd 2.1-wfn

# --nc: number of protected conduction bands; defaults to 100.
# --nv: number of protected valence bands; defaults to all (-1), generally useful if there are >30 valence bands.
# --nslice_c: number of slices into which the compressed conduction bands are split, default 100. (2 SPB are used for each slice!)
# --nslice_v: number of slices into which the compressed valence bands are split, not used by default. (only use for epsilon, not sigma!)

# --------------- for GPP, Epsilon calc -------------- #
/global/homes/j/jackm/software/BerkeleyGW-master/MeanField/ParaBands/pseudobands.py --nv 56 \
    --N_S_val 10 \
    --nc 30 \
    --N_S_cond 50 \
    --fname_in "WFN.h5" \
    --fname_in_q "../2.2-wfnq/WFN.h5" \
    --fname_out "WFN_psb_gpp.h5" \
    --fname_out_q "WFNq_psb_gpp.h5"

# for full frequency calcs:
# uniform width: should be half the spacing of the FF frequency grid
# max_freq must be a val in Ry larger than highest freq. used in FF epsilon (10 eV, converted to Ry)

# --------------- for FF, Epsilon calc -------------- #
/global/homes/j/jackm/software/BerkeleyGW-master/MeanField/ParaBands/pseudobands.py --nv 56 \
    --N_S_val 10 \
    --nc 30 \
    --N_S_cond 50 \
    --uniform_width 0.0913 \
    --max_freq 0.8 \
    --fname_in "WFN.h5" \
    --fname_in_q "../2.2-wfnq/WFN.h5" \
    --fname_out "WFN_psb_ff.h5" \
    --fname_out_q "WFNq_psb_ff.h5"

# for sigma calcs:
# n.b. there is no specific requirement that the pseudobands be identical to epsilon.
# the only difference is that valence pseudobands should *not* be used.

# --------------- for both GPP/FF, Sigma calc -------------- #
/global/homes/j/jackm/software/BerkeleyGW-master/MeanField/ParaBands/pseudobands.py --nv -1 \
    --nc 30 \
    --N_S_cond 50 \
    --uniform_width 0.0913 \
    --max_freq 0.8 \
    --fname_in "WFN.h5" \
    --fname_in_q "../2.2-wfnq/WFN.h5" \
    --fname_out "WFN_psb_sigma.h5" \
    --fname_out_q "WFNq_psb_sigma.h5"