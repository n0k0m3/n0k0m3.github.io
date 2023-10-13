---
title: MLOps/Data Science DevOps Projects
excerpt: "Attempts to dip my toes into DevOps, while trying to automate my data science environment deployments"
---

### [Jupyter Notebook Docker with Spark and DeltaLake support](https://github.com/n0k0m3/pyspark-notebook-deltalake-docker)

- Attempts to replicate `Databricks Runtime`, plus features from feature-rich jupyter/docker-stacks.
- Based image on NVIDIA's `rapidsai/rapidsai` image.
- Support for [Spark](https://spark.apache.org/downloads.html)/[PySpark](https://spark.apache.org/docs/latest/api/python/) 3.2.x and [Delta Lake](https://delta.io/) 1.1.0.
- Monthly cronjob to update the image with latest features from upstream `jupyter/docker-stacks`
- CD/CI automate building of image and pushing to `DockerHub` and `ghcr.io`

### [Docker container for Data Science](https://github.com/n0k0m3/datascience-notebook-docker):

- Based on Jupyter docker-stack `jupyter/datascience-notebook`
