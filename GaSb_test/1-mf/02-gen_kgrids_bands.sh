#!/bin/bash

# in terminal: "module load berkeleygw" and "module load python"
module load berkeleygw
BGWPATH=$HOME
# List of directories to create
directories=("2.1-wfn" "2.2-wfnq" "2.3-wfn_fi" "2.4-wfnq_fi")
# Number of bands for each calculation
nbnds=(1600 114 124 124) 
prefix="GaSb"

# first: run the data-file2kgrid.py script
cd 1-scf

data-file2kgrid.py --kgrid 6 6 6 $prefix.save/data-file-schema.xml kgrid1.inp
data-file2kgrid.py --kgrid 6 6 6 --qshift 0.001 0 0 $prefix.save/data-file-schema.xml kgrid2.inp
data-file2kgrid.py --kgrid 10 10 10 --kshift 0.14 0.72 0.53 $prefix.save/data-file-schema.xml kgrid3.inp
data-file2kgrid.py --kgrid 10 10 10 --kshift 0.14 0.72 0.53 --qshift 0.001 0 0 $prefix.save/data-file-schema.xml kgrid4.inp

kgrid.x kgrid1.inp kgrid1.out kgrid1.log
kgrid.x kgrid2.inp kgrid2.out kgrid2.log
kgrid.x kgrid3.inp kgrid3.out kgrid3.log
kgrid.x kgrid4.inp kgrid4.out kgrid4.log

cd ..

# Source files
scf_in="1-scf/scf.in"

# Initialize counter
index=1

# Loop through each directory with index
for dir in "${directories[@]}"; do
    # Create the directory if it doesn't exist
    if [ ! -d "$dir" ]; then
        mkdir "$dir"
        mkdir "$dir/$prefix.save"
        cd "$dir"
        ln -sf ../1-scf/*.upf .
        cd "$prefix.save"
        ln -sf ../../1-scf/$prefix.save/data-file-schema.xml .
        ln -sf ../../1-scf/$prefix.save/charge-density.hdf5 .
        ln -sf ../../1-scf/$prefix.save/charge-density.dat . # compatibility across versions
        ln -sf ../../1-scf/$prefix.save/*.upf .
        cd ../..
    fi

    # Copy scf.in to bands.in in the directory
    cp "$scf_in" "$dir/bands.in"
    # change calculation type and nbnd from scf input
    sed -i 's/scf/bands/g' $dir/bands.in
    sed -i "s/nbnd = .*/nbnd = ${nbnds[$index-1]}/" $dir/bands.in
    sed -i '/K_POINTS/,$d' $dir/bands.in

    # Concatenate kgridn.out to the end of bands.in
    kgrid_out="1-scf/kgrid$index.out"
    cat "$kgrid_out" >> "$dir/bands.in"

    # Print the index and directory name (optional)
    echo "Processed directory $index: $dir"

    # Increment the counter
    index=$((index + 1))
done