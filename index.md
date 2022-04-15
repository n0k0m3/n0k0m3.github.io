# n0k0m3's Portfolio

## [Resume](https://raw.githubusercontent.com/n0k0m3/resume/main/resume.pdf)

## Projects

### Deep Learning

- [Sentiment Analysis on MyAnimeList User Ratings](https://github.com/n0k0m3/rnn-mal-sentiment)
  - MyAnimeList is a popular anime rating website.
  - Predict user rating based on review using Recurrent Neural Network (RNN)
  - Setup a data-mining pipeline utilizing self-hosted REST API with a Redis server for caching inside dockerized container
  - Used different models (RNN with LSTM, CNN, CNN with Word2Vec embedding layers) for training and stacking model for ensemble.
  - Achieved 94% validation accuracy with ensemble model
- [Classification of Extended MNIST using Persistent Homology](https://colab.research.google.com/drive/18z161k3diYO6sNVBfiKH8uGqbrekxMPN?usp=sharing#scrollTo=0Y6rquBvdjEG):
  - EMNIST dataset is MNIST (handwritten digit) dataset with handwritten **characters**
  - Applied Persistent Homology and Principal Component Analysis to reduce the dimensionality of dataset. Reduced feature size from 784 (28x28) to 35 while retaining 99% variance
  - Utilized libraries `giotto-ai` along-side standard deep learning libraries `sklearn`, `NumPy`, `Tensorflow/Keras`
  - Achieved 97%-91% training-testing accuracy with a shallow neural network with only 3 hidden layers
- [Utilization of CNN in speech recognition](https://colab.research.google.com/drive/1KCJjwgW6VDlANLmXYTotatk2xux3nw0N?usp=sharing):
  - Classify Google Speech Command using Convolutional Neural Network (CNN) on audio data
  - Created pipelines to process audio data to image features
  - Audio data augmentation with respect to image features
  - Used multiple CNN architectures (LeNet, MiniGoogleNet, AlexNet) for training and stacking model for ensemble.
  - Achieved 91% validation accuracy with ensemble model.

### Data Analysis

- [Analysis of ProtonDB Linux Distribution](https://n0k0m3.github.io/Personal-Setup/ProtonDB_Analysis/analysis.html)
  - Analyze trends of distributions market share in Gaming segment, based on ProtonDB user reports.
  - Visuals to demonstrate the impact of Steam Deck release on Linux distribution market share.
- [Spotify API Audio Feature Analysis](https://github.com/n0k0m3/Spotify-API-Audio-Feature-Analysis)
  - From **audio data** predict track's attribute, reverse engineer/analyze audio features of Spotify API.
  - A (close to) comprehensive analysis of Spotify API Audio Features.
  - Using datamined **audio samples**, convert to image representation of audio data.
  - Use image representation to predict Spotify audio features.

### MLOps/Data Science DevOps

- [Jupyter Notebook Docker with Spark and DeltaLake support](https://github.com/n0k0m3/pyspark-notebook-deltalake-docker)
  - Attempts to replicate `Databricks Runtime`, plus features from feature-rich jupyter/docker-stacks.
  - Based image on NVIDIA's `rapidsai/rapidsai` image.
  - Support for [Spark](https://spark.apache.org/downloads.html)/[PySpark](https://spark.apache.org/docs/latest/api/python/) 3.2.x and [Delta Lake](https://delta.io/) 1.1.0.
  - Monthly cronjob to update the image with latest features from upstream `jupyter/docker-stacks`
  - CD/CI automate building of image and pushing to `DockerHub` and `ghcr.io`
- [Docker container for Data Science](https://github.com/n0k0m3/datascience-notebook-docker):
  - Based on Jupyter docker-stack `jupyter/datascience-notebook`

### Games Reverse Engineering and Data Mining

- Date A Live: Spirit Pledge Game Analysis:
  - [Assets Decryption Tool](https://github.com/n0k0m3/DALSP-Assets-Decryption-tool):
    - Reverse Engineer mobile game Date A Live: Spirit Pledge using Static analysis tool from NSA ghidra and dynamic analysis tool frida.
    - Re-implement decryption functions using Python, implement methods to convert PowerVR, Ericsson Texture Compression format to digital images format (JPEG/PNG)
  - [Assets Mining CD/CI](https://github.com/n0k0m3/DateALiveData): - Data-mined source logics to find insecure API/server that allows easy download/extraction of new game contents. - Datamining repository above developed decryption tool. Using cronjob
    and Github Action to automate fetch, decrypt and datamine new contents.
  - Usable mined data examples:
    - Extract Live2D assets compatible with Live2DViewerEX: [Link](https://github.com/n0k0m3/DALSP-Live2D)
    - Dating Route and Favorites: [Link](https://github.com/n0k0m3/DALSP-Dating-Routes-Dump)
- Other games reverse engineering/analysis:
  - [Azur Lane (Autopatcher)](https://github.com/n0k0m3/Azur-Lane-Scripts-Autopatcher)
  - [Arknights Assets Decryption](https://github.com/n0k0m3/Arknights-Lua-Decrypter)
  - [D4DJ Assets Decryption](https://github.com/n0k0m3/D4DJ)

## Other Personal Projects

These repos contains all of my personal codes and guides for personal setups. Most scripts work with all common consumer-based distros (Debian/Ubuntu, Arch, maybe RHEL-based, Fedora for some)

- [Library Genesis Torrent Scrapper](https://github.com/n0k0m3/Personal-Setup/blob/main/Libgen_torrent_scrape/scraping.py): Scrapes torrents that needs seeding for Library Genesis Project for preservation. Not intended for piracy
- [pwned password checker](https://github.com/n0k0m3/bitwarden-haveibeenpwned): Check BitWarden passwords against haveibeenpwned.com API.
- [Personal Setup](https://n0k0m3.github.io/Personal-Setup/): A collection of scripts and guides for Arch Setup