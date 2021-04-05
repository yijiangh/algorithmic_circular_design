# algorithmic circular design

![License MIT](https://img.shields.io/badge/License-MIT-blue.svg)

<!-- *compas_rpc_example*: example scripts for calling cpython functions from 
Grasshopper/Rhino via `compas_rpc <https://compas-dev.github.io/main/api/compas.rpc.html>`_
and `compas_xfunc <https://compas-dev.github.io/main/api/generated/compas.utilities.XFunc.html#compas.utilities.XFunc>`_. -->

This repo contains two different implementations to use the [Hungarian algorithm](https://en.wikipedia.org/wiki/Hungarian_algorithm): one using C#, the other one using a backend written in the [Julia programming language}(https://github.com/JuliaLang/julia).

The C# implementation requires no extra effort to setup, simply open the Grasshopper script `Geodesic_Reuse_v2.gh` with the Rhino file `sample house_r6_3.3dm`, and it works out of the box!

To use the julia backend, however, we need some extra setup, but it's worth the effort - we've reported at least 10 times speedup with the julia backend compared to the C# one!

The instructions below walks you through setting up the julia backend.

## Installation

### Prerequisites

0. Operating System: **Windows 10**

1. [Rhinoceros 3D >=6.0](https://www.rhino3d.com/):

    We will use Rhino / Grasshopper as a frontend for inputting
    geometric and numeric paramters, and use various C#/julia packages as the computing backends.

2. [Miniconda](https://docs.conda.io/en/latest/miniconda.html)

    We will install all the required python packages using 
    `Miniconda` (a light version of Anaconda). Miniconda uses 
    **environments** to create isolated spaces for projects' 
    depedencies.

3. [Julia>=1.6](https://julialang.org/downloads/).

    Please download installer from the stable release `v1.6.0`.

4. [GHPythonRemote](https://github.com/pilcru/ghpythonremote).

    Main package that allows us to call external python packages within the GHPython environment.

5. [pyjulia](https://github.com/JuliaPy/pyjulia):

    Main package that allows us to call Julia from python.

Now, please click on the links above to install `1-3` (`Rhino`, `Miniconda`, and `Julia`).
The following sections walk you through installing `4` and `5` step-by-step.

### Creating a conda environment

Unfortunately, [GHPythonRemote](https://github.com/pilcru/ghpythonremote) requires a Python 2.7 installation, 
and it's not compatible with Python 3.
It is recommended to set up a conda environment to create a clean, isolated space for
installing the required python packages.

Type in the following commands in your Anaconda terminal 
(search for ``Anaconda Prompt`` in the Windows search bar):

```
    conda create --name py27 python=2.7 numpy scipy
```

Wait for the building process to finish, the command above will
fetch and build all the required packages, which will take some time
(1~2 mins).

Then, activate the newly created conda environment (with all the needed packages installed):

```
    conda activate py27
```

### Install `GHPythonRemote`

In the anaconda terminal from the last section, issue the following to install `ghpythonremote`:

```
pip install gh-python-remote --upgrade
python -m ghpythonremote._configure_ironpython_installation 6
```

### `pyjulia` installation 

Keep using the anaconda terminal, issue the following to install
`pyjulia`:

```
pip install julia
```

Verify that your installation is successful:

```
$ python
>>> import julia
>>> julia.install()               # install PyCall.jl etc.
>>> from julia import Base        # short demo
>>> Base.sind(90)
1.0
```

Now you are done! Open the Grasshopper script `Geodesic_Reuse_v2.gh` with the Rhino file `sample house_r6_3.3dm`, and the julia backend should be working now!

## Solving Mixed-Integer Programming with `JuMP` and `Gurobi`

With the help of [JuMP.jl](https://github.com/jump-dev/JuMP.jl), we can easily replicate the MILP formulation using use the Gurobi optimizer, as proposed in [[Brütting et al. 2020]](https://www.frontiersin.org/articles/10.3389/fbuil.2020.00057/full#B6). 

Gurobi is a fairly expensive commerical optimization software, but we can obtain free academic licenses [here](https://www.gurobi.com/academia/academic-program-and-licenses/).

To do this, We need to install a few more julia packages:

```julia
# type in "]"
julia>]
(@v1.6) pkg> add LinearAlgebra JuMP Gurobi
...
```

Wait for the installation to finish, and we should be able to use their power in Grasshopper!

## Citation

TODO