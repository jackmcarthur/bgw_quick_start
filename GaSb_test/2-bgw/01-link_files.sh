#!/bin/bash

cd 1.1-epsilon-gpp-full
ln -sf ../../1-mf/2.1-wfn/WFN.h5 WFN.h5
ln -sf ../../1-mf/2.2-wfnq/WFN.h5 WFNq.h5

# link wavefunctions (WITH valence pseudobands, if used)
cd ../1.2-epsilon-gpp-pseudo
ln -sf ../../1-mf/2.1-wfn/WFN_psb_gpp.h5 WFN.h5
ln -sf ../../1-mf/2.1-wfn/WFNq_psb_gpp.h5 WFNq.h5

cd ../1.3-epsilon-ff-pseudo
ln -sf ../../1-mf/2.1-wfn/WFN_psb_ff.h5 WFN.h5
ln -sf ../../1-mf/2.1-wfn/WFNq_psb_ff.h5 WFNq.h5


cd ../2.1-sigma-gpp-full
ln -sf ../../1-mf/2.1-wfn/WFN.h5 WFN_inner.h5
ln -sf ../../1-mf/2.1-wfn/kih.dat .
ln -sf ../../1-mf/2.1-wfn/RHO .
# these should normally be the 1.1-full files, but computing them is too expensive.
ln -sf ../1.2-epsilon-gpp-pseudo/eps0mat.h5 eps0mat.h5
ln -sf ../1.2-epsilon-gpp-pseudo/epsmat.h5 epsmat.h5

cd ../2.2-sigma-gpp-pseudo
ln -sf ../../1-mf/2.1-wfn/WFN_psb_sigma.h5 WFN_inner.h5
ln -sf ../../1-mf/2.1-wfn/kih.dat .
ln -sf ../../1-mf/2.1-wfn/RHO .
ln -sf ../1.2-epsilon-gpp-pseudo/eps0mat.h5 eps0mat.h5
ln -sf ../1.2-epsilon-gpp-pseudo/epsmat.h5 epsmat.h5

cd ../2.3-sigma-ff-pseudo
ln -sf ../../1-mf/2.1-wfn/WFN_psb_sigma.h5 WFN_inner.h5
ln -sf ../../1-mf/2.1-wfn/kih.dat .
ln -sf ../1.3-epsilon-ff-pseudo/eps0mat.h5 eps0mat.h5
ln -sf ../1.3-epsilon-ff-pseudo/epsmat.h5 epsmat.h5
