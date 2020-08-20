import random

import pytest

from dssm.bayesian_model import BayesianModel


@pytest.fixture
def initial_belief():
    return 5


@pytest.fixture
def model(initial_belief):
    return BayesianModel(initial_belief)


def test_initial_belief(model, initial_belief):
    assert model.belief == initial_belief


def test_update_model_with_signals(model):
    model.update(10)
    assert model.belief == 7.5
    model.update(3)
    assert model.belief == 6


def train_to(model, new_belief):
    for _ in range(100000):
        model.update(random.gauss(mu=new_belief, sigma=1))


def test_model_converges_to_new_mean(model, initial_belief):
    new_mu = initial_belief - 5
    train_to(model, new_mu)
    assert (new_mu - 0.01) < model.belief < (new_mu + 0.01)


def test_model_reset(model, initial_belief):
    train_to(model, initial_belief)

    model.reset(-5)
    assert model.belief == -5
    model.update(-10)
    assert model.belief == -7.5
