class BayesianModel:
    def __init__(self, initial_mu):
        self._initial_mu = initial_mu
        self._belief = initial_mu
        self._t = 0

    @property
    def belief(self):
        return self._belief

    def update(self, signal):
        self._t += 1
        self._belief = (self._t / (self._t + 1)) * self._belief + (1 / (self._t + 1)) * signal

    def reset(self, new_belief):
        self._belief = new_belief
        self._t = 0

    def __repr__(self):
        return f"BayesianModel(initial_mu={self._initial_mu})"
