# Gemini Matlab scripts

[![Build Status](https://dev.azure.com/mhirsch0512/Gemini3D/_apis/build/status/gemini3d.mat_gemini?branchName=master)](https://dev.azure.com/mhirsch0512/Gemini3D/_build/latest?definitionId=20&branchName=master)
[![DOI](https://zenodo.org/badge/246748210.svg)](https://zenodo.org/badge/latestdoi/246748210)
[![View MatGemini on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/78676-matgemini)

These scripts form the basic core needed to work with Gemini3D ionospheric model to:

* generate a new simulation from scratch
* read simulation output
* plot simulation

Matlab R2020a Update 5 and newer have better plot quality due to new Matlab graphics backend.

## Quick Start

We assume you already have a Fortran compiler and MPI library installed.

```sh
git clone --recurse-submodules https://github.com/gemini3d/mat_gemini
```

To enable mat_gemini functions, from the "mat_gemini/" directory in Matlab:

```matlab
setup
```

### Self-check (optional, but recommended)

Run the self-tests from Matlab in the mat_gemini/ directory:

```matlab
TestGemini
```

If there are failures with SSL certificate errors, you may need to tell Git the location of your system SSL certificates. This can be an issue in general on HPC.
If this is an issue, and assuming your SSL certificates are at "/etc/ssl/certs/ca-bundle.crt", do these two steps from Terminal (not Matlab), one time.

1. edit ~/.bashrc to have

    ```sh
    export SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
    ```
2. issue Terminal command:

    ```sh
    git config --global http.sslCAInfo /etc/ssl/certs/ca-bundle.crt
    ```

## Usage

Generally, one sets up a simulation, runs, then plots the outputs of that simulation.
Once that works, one perhaps changes simulation parameters, perhaps by perturbing the plasma or inputs with custom functions.

The model setup creates a neutral atmosphere using MSIS.
The default is to use MSISE00, but MSIS 2.0 is also available.
This is user selectable in the simulation config.nml file like:

```
&neutral_BG
msis_version = 20
/
```

where `0` is MSISE00 (default) and `20` is MSIS 2.0.

### Run Simulation

The Matlab Live Scripts [Examples/ns_fang.mlx](./Examples/ns_fang.mlx) interactively demonstrates running a 2D simulation.
Open and run this script, or simply run from Matlab:

```matlab
gemini3d.run(out_dir, 'Examples/init/2dns_fang.nml')
```

### Load a data frame

The data writes out to a file each time step it's commanded to by the config.nml "dtout" parameter.
You can load these by filename, or by directory + time:

```matlab
dat = gemini3d.read.frame(filename);
```

```matlab
dat = gemini3d.read.frame(directory, 'time', datetime(2012,1,20,12,5,3));
```

### Plot all simulation outputs

```matlab
gemini3d.plot(out_dir, "png")
```

generates plots under `out_dir + "/plots"`
Will save all plots under the `mysim/plots/` directory. Omitting `'png'` just displays the plots without saving.

### Plot simulation grid

Plots of the simulation grid can be made:

```matlab
gemini3d.plot.grid(sim_path)
```

This can help show if something unintended happened.

## Advanced usage

### Custom functions

Often users will desire to perturb the quiescent equilibrium data with custom Matlab functions.
Assuming these functions have an interface like

```matlab
myfunc(cfg, xg)
```

then they can be specified in the config.nml file under setup/setup_functions.
For examples see
[GDI_periodic_lowres](https://github.com/gemini3d/gemini-examples/tree/master/init/GDI_periodic_lowres) and
[KHI_periodic_lowres](https://github.com/gemini3d/gemini-examples/tree/master/init/KHI_periodic_lowres).

### compare data directories

It can be useful to compare a simulation output and/or input with a "known good" reference case.
We provide this facility within the Matlab unittest framework for robustness and clarity.

```matlab
gemini3d.compare(new_dir, reference_dir)
```

That compares simulation inputs and outputs.

---

To only compare simulation input:

```matlab
gemini3d.compare(new_dir, reference_dir, 'in')
```

---

To only compare simulation output:

```matlab
gemini3d.compare(new_dir, reference_dir, 'out')
```

### Regenerate self-test reference datasets

This is intended for use by developers working with the internals of Gemini3D, the average user doesn't need this.
When a significant change is made to internal Gemini3D code, this may change the reference data and cause the self-tests to fail.
If determined that new reference datasets are needed:

```matlab
gemini3d.setup.generate_reference_data('../gemini-examples/initialize', '~/sim', 'test2d')
```

That makes all tests with subdirectory names containing "test2d".
A cell array or string array of names can also be specified.
