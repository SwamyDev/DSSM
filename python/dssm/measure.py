import time
from contextlib import contextmanager


@contextmanager
def measure_performance(prefix=None, reporter=None):
    try:
        start = time.time()
        yield
        elapsed = time.time() - start
        prefix = prefix or "It"
        print(f"{prefix:<20} took: {elapsed:>8.4f}s", file=reporter, flush=True)
    finally:
        pass
