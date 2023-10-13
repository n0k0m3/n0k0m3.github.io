#!/bin/bash

git clone https://github.com/bdefore/protondb-data --depth=1
cd protondb-data
git pull
cd ..
conda run python update_protonhdf.py
conda run python update_analysis.py