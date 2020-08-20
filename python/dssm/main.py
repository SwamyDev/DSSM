from pathlib import Path

import bocd
import click
import numpy as np
import plotly.graph_objects as go

from dssm.bayesian_model import BayesianModel
from dssm.dssm_model import DSSM
from dssm.ffm_model import FFM
from dssm.measure import measure_performance
from dssm.mse import mean_squared_error

mu = 20
average_interval = 50
window = 5
kappa = 0.7933598  # retrieved from optimizer - could be coupled to variance estimate
std = 0.2  # fixed standard deviation used to generate test data - see R code for implementation
ffm_window = 8  # working memory used as described in "Prediction and Change Detection"
C = 6  # distance threshold between observation and prediction as described in "Prediction and Change Detection"


def run_basic_bayesian_observer(signals, _):
    model = BayesianModel(mu)
    beliefs = []
    for s in signals:
        model.update(s)
        beliefs.append(model.belief)

    return beliefs, []


def run_bocd(signals, _):
    model = BayesianModel(mu)
    bc = bocd.BayesianOnlineChangePointDetection(bocd.ConstantHazard(average_interval),
                                                 # determined after some "empirical" parameter tuning
                                                 bocd.StudentT(mu=mu, kappa=0.1, alpha=10, beta=10))
    # Online estimation and get the maximum likelihood r_t at each time point
    change_points = []
    beliefs = []

    prev_rt = 0
    for i, signal in enumerate(signals):
        beliefs.append(model.belief)

        bc.update(signal)
        rt = bc.rt[0]
        if rt - prev_rt < 0:  # change point detected
            change_points.append(i)
            model.reset(signal)
        else:
            model.update(signal)

        prev_rt = rt

    return beliefs, change_points


def run_dssm(signals, config):
    model = DSSM(BayesianModel(mu), config.get('kappa', kappa), config.get('window', window))
    beliefs = []
    for s in signals:
        beliefs.append(model.belief)
        model.update(s)

    return beliefs, model.change_points


def run_ffm(signals, _):
    model = FFM(memory=ffm_window, c=C, initial_mu=mu, std=std)
    beliefs = []
    for s in signals:
        beliefs.append(model.belief)
        model.update(s)

    return beliefs, model.change_points


model_runners = dict(
    bayesian=run_basic_bayesian_observer,
    bocd=run_bocd,
    dssm=run_dssm,
    ffm=run_ffm,
)


@click.command()
@click.argument('input', type=click.File('r'))
@click.option('--num-trials', '-n', default=1e4, type=click.INT, help="Number of trial data points used. (default=1e4)")
@click.option('--plot-range', default="0,200", type=click.STRING, help="Range of trials to be plotted. (default=0,200)")
@click.option('--models', default="all", type=click.STRING,
              help="Comma separated list of models (bayesian,bocd,dssm,ffm) to compare. (default=all)")
@click.option('--plot-datums', multiple=True, type=click.Path(exists=True, file_okay=True, dir_okay=False),
              help="Files containing additional datums to plot")
@click.option('--plot/--no-plot', default=True,
              help="Produce a plot of the trial data and model predictions. (default=--plot)")
def cli(input, num_trials, plot_range, models, plot_datums, plot):
    """
    Run the FAM algorithm to produce graphs from the given signal data and report mean squared error for the different
    models (basic bayesian observer, bayesian online change point detection, and FAM)
    """
    selected_models = list(model_runners.keys()) if models == "all" else models.split(',')

    input_data = [float(line) for line in input]
    num_trials = min(num_trials, len(input_data))
    signals = np.array(input_data)[:num_trials]

    additional_datums = []
    for p in plot_datums:
        file = Path(p)
        with file.open(mode='r') as f:
            values = [float(line) for line in f][:num_trials]
            additional_datums.append((file.name, values))

    p_start, p_stop = (int(v) for v in plot_range.split(','))
    p_stop = min(p_stop, len(input_data))
    plotting_range = slice(p_start, p_stop)
    fig = go.Figure()
    fig.add_trace(go.Scatter(x0=p_start, dx=1, y=signals[plotting_range], mode='markers', name="observations"))

    for model in selected_models:
        with measure_performance(f"[{model.upper()}]"):
            beliefs, _ = model_runners[model](signals, {})

        prefix = f"[{model.upper()}] MSE: "
        print(f"{prefix:<20}{mean_squared_error(beliefs, signals):>8.4f}")
        fig.add_trace(go.Scatter(x0=p_start, dx=1, y=beliefs[plotting_range], mode='lines', name=model.upper()))

    for name, datums in additional_datums:
        fig.add_trace(go.Scatter(x0=p_start, dx=1, y=datums[plotting_range], mode='lines', name=name.upper()))

    if plot:
        fig.show(renderer="browser")

if __name__ == '__main__':
    cli()
