import pytest

from dssm.ffm_model import FFM


@pytest.fixture
def initial_mu():
    return 3


@pytest.fixture
def memory():
    return 3


@pytest.fixture
def model(memory, initial_mu):
    return FFM(memory=memory, c=100.0, initial_mu=initial_mu, std=0.1)


@pytest.fixture
def train_to_memory(model, memory):
    def f(signal):
        for _ in range(memory):
            model.update(signal)

    return f


def test_ff_initial_belief(model, initial_mu):
    assert model.belief == initial_mu


def test_ff_belief_is_accumulated_mean_when_no_change_occurs(model, initial_mu):
    model.update(2)
    assert model.belief == (initial_mu + 2) / 2
    model.update(3)
    assert model.belief == (initial_mu + 2 + 3) / 3
    model.update(2)
    assert model.belief == (2 + 3 + 2) / 3


def test_ff_change_point_is_detected_when_log_likelihood_exceeds_threshold(model, train_to_memory, memory):
    train_to_memory(4)
    model.update(10)
    assert model.change_points == [memory]
    model.update(-10)
    assert model.change_points == [memory, memory + 1]


def test_ff_resets_memory_once_a_change_point_has_been_detected_and_learns_anew(model, train_to_memory):
    train_to_memory(4)
    assert model.belief == 4
    model.update(10)
    assert model.belief == 10
