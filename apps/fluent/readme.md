# Fluent Benchmarks

Install as follows:

```
./install_fluent.sh /path/to/fluent_install_file.tar
```

> Note: This will install into `/apps`.

In the run script you will need to update the license server.  Currently it is set to localhost which would require a tunnel to be created (currently the ssh tunnel command commented out in the script).

Now, you can run as follows:

```
for ppn in 60 45 30; do
    for nodes in 2 4 8 16 32 64 128; do
        name=racecar_hpcx_${nodes}x${ppn}
        mkdir $name
        cd $name
        cp ../run_hpcx.sh .
        qsub -l select=${nodes}:ncpus=${ppn}:mpiprocs=${ppn},place=scatter:excl -N $name ./run_hpcx.sh
        cd -
    done
done
```
