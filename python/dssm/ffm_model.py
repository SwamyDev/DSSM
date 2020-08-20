from collections import deque
from math import log, pi


class FFM:
    def __init__(self, memory, c, initial_mu, std):
        self._memory = deque(maxlen=memory)
        self._memory.append(initial_mu)
        self._c = c
        self._std = std
        self._belief = initial_mu
        self._change_points = []
        self._time_step = 0

    @property
    def belief(self):
        return self._belief

    @property
    def change_points(self):
        return self._change_points

    def update(self, signal):
        d = self._prediction_observation_dist(signal)
        if self._time_step > 0 and d > self._c:
            self._change_points.append(self._time_step)
            self._memory.clear()

        self._memory.append(signal)
        self._belief = sum(self._memory) / len(self._memory)
        self._time_step += 1

    def _prediction_observation_dist(self, signal):
        """
        In the paper "Prediction and Change Detection@ by Steyvers M. and Scott B. this is defined as the function d.
        The function d calculates distance between observation and prediction using log likelihood. In our case since we
        use gaussian distributions in our test data we use the gaussian density functions instead of the binomial one.
        """
        return self._norm_log_likelihood(signal, signal) - self._norm_log_likelihood(self._belief, signal)

    def _norm_log_likelihood(self, mu, signal):
        return -0.5 * log(2 * pi * (self._std ** 2)) - (1 / (2 * (self._std ** 2))) * ((signal - mu) ** 2)