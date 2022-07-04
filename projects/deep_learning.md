---
layout: default
title: Deep Learning
parent: Projects
nav_order: 2
---

## Deep Learning Projects

### [Deep Transformer Soft Actor-Critic Network for Reinforcement Learning](https://github.com/sesem738/Frankenstein)
- Utilize Transformer as memory module for both Actor and Policy networks
- Hyperparameter tuning for SAC performance

### [Sentiment Analysis on MyAnimeList User Ratings](https://github.com/n0k0m3/rnn-mal-sentiment)

- MyAnimeList is a popular anime rating website.
- Predict user rating based on review using Recurrent Neural Network (RNN)
- Setup a data-mining pipeline utilizing self-hosted REST API with a Redis server for caching inside dockerized container
- Used different models (RNN with LSTM, CNN, CNN with Word2Vec embedding layers) for training and stacking model for ensemble.
- Achieved 94% validation accuracy with ensemble model

### [Classification of Extended MNIST using Persistent Homology](https://colab.research.google.com/drive/18z161k3diYO6sNVBfiKH8uGqbrekxMPN?usp=sharing#scrollTo=0Y6rquBvdjEG)

- EMNIST dataset is MNIST (handwritten digit) dataset with handwritten **characters**
- Applied Persistent Homology and Principal Component Analysis to reduce the dimensionality of dataset. Reduced feature size from 784 (28x28) to 35 while retaining 99% variance
- Utilized libraries `giotto-ai` along-side standard deep learning libraries `sklearn`, `NumPy`, `Tensorflow/Keras`
- Achieved 97%-91% training-testing accuracy with a shallow neural network with only 3 hidden layers

### [Utilization of CNN in speech recognition](https://colab.research.google.com/drive/1KCJjwgW6VDlANLmXYTotatk2xux3nw0N?usp=sharing)

- Classify Google Speech Command using Convolutional Neural Network (CNN) on audio data
- Created pipelines to process audio data to image features
- Audio data augmentation with respect to image features
- Used multiple CNN architectures (LeNet, MiniGoogleNet, AlexNet) for training and stacking model for ensemble.
- Achieved 91% validation accuracy with ensemble model.
