from collections import deque
from math import sqrt


class DSSM:
    def __init__(self, model, kappa, window=1):
        self._model = model
        self._kappa = kappa
        self._change_points = []
        self._time_step = 0
        self._window = deque(maxlen=window)

    @property
    def belief(self):
        return self._model.belief

    @property
    def change_points(self):
        return self._change_points

    def update(self, signal):
        self._model.update(signal)
        self._window.append(signal)

        sqr_diffs = [(self._model.belief - s)**2 for s in self._window]
        if sqrt(sum(sqr_diffs)) > self._kappa:
            self._change_points.append(self._time_step)
            self._model.reset(signal)

        self._time_step += 1

    def __repr__(self):
        return f"FAM(model={self._model}, kappa={self._kappa})"