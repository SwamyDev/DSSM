from math import sqrt


def mean_squared_error(lhs, rhs):
    if len(lhs) != len(rhs):
        raise InvalidComparisonError(f"Input sequence lengths do not match: {len(lhs)} != {len(rhs)}")

    return sqrt(sum([(r - l) ** 2 for r, l in zip(rhs, lhs)]))


class InvalidComparisonError(RuntimeError):
    pass
