import random

import pytest

from dssm.bayesian_model import BayesianModel
from dssm.dssm_model import DSSM


@pytest.fixture
def initial_belief():
    return 5


@pytest.fixture
def kappa():
    return 4


@pytest.fixture
def bayesian_model(initial_belief):
    return BayesianModel(initial_belief)


@pytest.fixture
def model(bayesian_model, kappa):
    return DSSM(bayesian_model, kappa)


@pytest.fixture
def model_w2(bayesian_model, kappa):
    return DSSM(bayesian_model, kappa, window=2)


def test_dssm_initial_belief(model, initial_belief):
    assert model.belief == initial_belief


def train_to(model, new_belief, num_steps=100000):
    for _ in range(num_steps):
        model.update(random.gauss(mu=new_belief, sigma=0.1))


def test_dssm_following_bayesian_observer_when_no_change_occurs(model, initial_belief):
    belief = initial_belief + 1
    train_to(model, belief)
    assert belief - 0.1 < model.belief < belief + 0.1


def test_dssm_detects_change_point_when_signal_exceeds_kappa(model, initial_belief, kappa):
    train_to(model, initial_belief, num_steps=1000)
    model.update(initial_belief - 2 * kappa)
    assert model.change_points == [1000]
    model.update(initial_belief + 2 * kappa)
    assert model.change_points == [1000, 1001]


def test_dssm_resets_model_on_change_point(model, initial_belief, kappa):
    train_to(model, initial_belief)
    new_mu = initial_belief + 2 * kappa
    model.update(new_mu)
    assert model.belief == new_mu


def test_dssm_does_reset_model_when_window_distance_is_sufficient(model_w2, initial_belief, kappa):
    train_to(model_w2, initial_belief, num_steps=1000)
    model_w2.update(initial_belief + 0.8 * kappa)
    assert model_w2.change_points == []
    model_w2.update(initial_belief + 0.8 * kappa)
    assert model_w2.change_points == [1001]


def test_dssm_does_not_reset_model_when_window_distance_is_not_sufficient(model_w2, initial_belief, kappa):
    train_to(model_w2, initial_belief, num_steps=1000)
    model_w2.update(initial_belief + 0.8 * kappa)
    assert model_w2.change_points == []
    model_w2.update(initial_belief)
    assert model_w2.change_points == []


def test_dssm_window_calculates_with_minimum_received_signals(model_w2, initial_belief, kappa):
    model_w2.update(initial_belief + 3 * kappa)
    assert model_w2.change_points == [0]
