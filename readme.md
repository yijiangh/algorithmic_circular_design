# algorithmic circular design

![License MIT](https://img.shields.io/badge/License-MIT-blue.svg)

<!-- *compas_rpc_example*: example scripts for calling cpython functions from 
Grasshopper/Rhino via `compas_rpc <https://compas-dev.github.io/main/api/compas.rpc.html>`_
and `compas_xfunc <https://compas-dev.github.io/main/api/generated/compas.utilities.XFunc.html#compas.utilities.XFunc>`_. -->

This repo contains two different implementations to use the [Hungarian algorithm](https://en.wikipedia.org/wiki/Hungarian_algorithm): one using C#, the other one using a backend written in the [Julia programming language](https://github.com/JuliaLang/julia).

The C# implementation requires no extra effort to setup, simply open the Grasshopper script `Geodesic_Reuse_v2.gh` with the Rhino file `sample house_r6_3.3dm`, and it works out of the box!

To use the julia backend, however, we need some extra setup, but it's worth the effort - we've reported at least 10 times speedup with the julia backend compared to the C# one!

The instructions for setting up the GH-Julia workflow is [here](./gh_julia_instructions.md).

## Citation

TODO