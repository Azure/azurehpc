## Tests

These tests should all run even if launched from a different working directory (opened files are relative to the config file that is passed).

# simple test to read a variable

    azhpc get variables.hpc_image

# this expects the variable substitution in the string

    azhpc get cyclecloud.clusters.pbscycle.parameters.SubnetId

# this should show the variables section in the output

    azhpc preprocess
