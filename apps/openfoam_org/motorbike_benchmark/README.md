# Motorbike benchmark

These scripts break down the OpenFOAM workflow to three steps:

* Generate the mesh in parallel and reconstruct into a single model
* Decompose for the size required
* Run the simulation

These are the steps to do this with PBS using job dependencies so they can all be submitted at once:

```
all_nodes=(1 2 4 8 16 32 64 128)
all_ppn=(60 45)
data_dir=/scratch
case_name=motorbike22M
blockmesh_dims="100 40 40"
# Use the following for a 150M cell mesh:
#case_name=motorbike150M
#blockmesh_dims="200 80 80"

jobid_mesh=$(qsub -f -N ${case_name} -k oe -j oe -l select=1:ncpus=${all_ppn[0]}:mpiprocs=${all_ppn[0]} -- ~/motorbike_benchmark/generate_mesh.sh $data_dir ${case_name} "$blockmesh_dims")

for nnodes in ${all_nodes[@]}; do
    for ppn in ${all_ppn[@]}; do
        # decompose
        jobid=$(qsub -W depend=afterok:${jobid_mesh} -f -N ${case_name}_decomp_${nnodes}x${ppn} -k oe -j oe -l select=1:ncpus=$ppn:mpiprocs=$ppn -- ~/motorbike_benchmark/decompose.sh $data_dir ${case_name} $nnodes $ppn)
        # solve
        qsub -W depend=afterok:${jobid} -f -N ${case_name}_run_${nnodes}x${ppn} -k oe -j oe -l select=$nnodes:ncpus=$ppn:mpiprocs=$ppn -- ~/motorbike_benchmark/run_benchmark.sh $data_dir ${case_name} $nnodes $ppn
    done
done
```