# DSSM

Implementation and LATEX code of the DSSM paper.

## Python Models
This section describes how to install and run the python models described in the DSSM paper. The DSSM model is our own creation, whereas we compare it against other models such as Bayesian Online Change Point Detection based on the paper by Adams, Ryan Prescott, and David JC MacKay "Bayesian online changepoint detection". Specifically for the python comparison we use this implementation:
 https://github.com/y-bar/bocd
 
 ### Installation
 To install the `dssm` module simply run from the root of this repository:
 ```bash
make setup-python
 ```

This will create a virtual-env environment in `code/python/venv` and install the `dssm` module in it.

#### Dependencies
You need virtual-env for this installation process. In case you don't have it you can install it on Debian systems via:
```bash
sudo apt install python3-venv
```

### Running the models
To run and compare the modules simply start the python script from the root of the repository with this `make` command:
```bash
make run-python
```
This will produce a plot of the first 200 datums and print some measurements to standard out similar to this:
```bash
[BAYESIAN]           took:   0.0071s
[BAYESIAN] MSE:     169.9429
[BOCD]               took:   9.2599s
[BOCD] MSE:          43.5655
[DSSM]               took:   0.0445s
[DSSM] MSE:          41.6047
[FFM]                took:   0.0382s
[FFM] MSE:           41.5738
Opening in existing browser session.
```

Running this make command is actually the same as activating the `dssm` virtual-env...

```bash
source code/python/venv/activate
```
... and running the online change point detection script with `resources/observations.txt` and default parameters
```bash
ocpd resources/observations.txt
```

When running ocpd directly you can specify various parameters such as the number of trials (`--num-trials`) or the range of data-points that should be plotted (`--plot-range`). Simply run...
```bash
ocpd --help
```
... for details.