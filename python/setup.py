"""
Setup module for the django-docker package.
"""

from setuptools import setup, find_packages
from codecs import open
from os import path


here = path.abspath(path.dirname(__file__))

# Get the long description from the README file
with open(path.join(here, 'README.md'), encoding = 'utf-8') as f:
    long_description = f.read()

setup(
    name = 'django-docker',
    version = '0.1.0',
    description = 'Python utilities for running Django applications using Docker.',
    long_description = long_description,
    url = 'https://github.com',
    author = 'Matt Pryor',
    license = 'MIT',
    classifiers = [
        #   3 - Alpha
        #   4 - Beta
        #   5 - Production/Stable
        'Development Status :: 3 - Alpha',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.5',
    ],
    keywords='django docker',
    packages = find_packages(),
    requires = [
        'slack-logging-handler',
        'dj-database-url',
    ]
)
