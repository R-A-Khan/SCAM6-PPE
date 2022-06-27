#!/bin/bash

# Running 32 simulations in parallel per iteration, for a total of 20 iterations and 640 simulation runs

start=1; end=32
chunksize=32; loops=20;

par_version=case_V4.3

while (($start<=${chunksize}*$((loops-1))+1))
do
    echo "Commencing parallel runs for iterations  ${start} to  ${end}"
    sed -n ${start},${end}p parameter_file | xargs -n 10 ./run_model_loop.sh
    echo -e  "\nFinished running model for parametersets ${start} to ${end}\n"
    rm -f /home/.../ic_em_files/$par_version/*
    rm -f /home/.../par_files/$par_version/*
    # rm -f /home/.../iop_files/$par_version/*
    start=$((start+chunksize))
    end=$((end+chunksize))
done

