import pytest

from dssm.mse import mean_squared_error, InvalidComparisonError


def test_mse_of_empty_lists():
    assert mean_squared_error([], []) == 0


def test_mse_with_different_list_length_raises_error():
    with pytest.raises(InvalidComparisonError):
        mean_squared_error([0], [0, 1])


@pytest.mark.parametrize('lhs,rhs,error', [(5, 2, 3), (-8, -4, 4)])
def test_mse_of_a_single_value(lhs, rhs, error):
    assert mean_squared_error([lhs], [rhs]) == error


def test_mse_of_multiple_values():
    assert mean_squared_error([5, -8], [2, -4]) == 5
