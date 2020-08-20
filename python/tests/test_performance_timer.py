from io import StringIO
from time import sleep

from dssm.measure import measure_performance


def test_measure_performance():
    ss = StringIO()
    with measure_performance(reporter=ss):
        sleep(0.01)

    assert "0.01" in ss.getvalue()


def test_with_prefix():
    ss = StringIO()
    with measure_performance(prefix="[TEST]", reporter=ss):
        sleep(0.01)

    assert "[TEST]" in ss.getvalue()
