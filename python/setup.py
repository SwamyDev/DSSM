from setuptools import setup, find_packages

setup(
    name='dssm',
    packages=find_packages(include=['dssm', 'dssm.*']),
    install_requires=['bocd', 'click', 'plotly', 'numpy'],
    extras_require={"test": ['pytest', 'pytest-cov']},
    include_package_data=True,
    zip_safe=False,
    python_requires='>=3.6,<3.8',
    entry_points={
        'console_scripts': ['ocpd = dssm:cli']
    }
)
