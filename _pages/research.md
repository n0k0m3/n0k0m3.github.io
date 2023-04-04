---
layout: single
title: Researches
permalink: /research/
---

## Privacy‑focused, longitudinal (temporal) generation of synthetic Electronics Health Records with Differential Privacy

Electronic health records (EHRs) contain valuable information for medical research and analysis, but they also pose privacy risks for patients and providers. To address this challenge, this work aims to generate synthetic EHRs that preserve the features and patterns of real EHRs, including temporal features, while protecting the privacy of individuals.

The project involves four main steps:
1. Developing a 3D representation of EHRs that captures the temporal and longitudinal aspects of patient data
2. Using generative adversarial networks (GANs) with a privacy-preserving optimizer (using Differential Privacy) to generate realistic and diverse synthetic EHRs from the 3D representation
3. Building a scalable pipeline to transform the synthetic EHRs into synthetic patient records that can be used for research and analysis
4. Measuring the quality and utility of the synthetic data using various metrics, and assessing the privacy of the synthetic data using different privacy attack scenarios.

**Proposal/White Paper**

<embed src="/_pages/ehr.pdf" type="application/pdf" width="100%" height="100%"/>

[Download PDF](/_pages/ehr.pdf){: .btn .btn--info}

**Keywords:** electronic health records, synthetic data, generative adversarial networks, differential privacy, temporal features.

## 3D Modeling of Resident Space Objects using Neural Radiance Fields
Resident space objects (RSOs) are non-cooperative objects in orbit that pose challenges for space debris removal, on-orbit servicing (OOS), and functionality identification. This work presents a novel application of neural radiance fields (NeRFs) to the problem of 3D reconstruction of RSOs from a set of 2D images. NeRFs are a deep learning technique that can learn high-fidelity 3D models from unstructured images by modeling the scene as a continuous function that maps 3D coordinates and viewing directions to colors and densities. 

We adapt two variants of NeRF, Instant NeRF and D-NeRF, to the RSO domain and evaluate their performance on datasets of images of a spacecraft mock-up captured under different lighting and motion conditions at the Orbital Robotic Interaction, On-Orbit Servicing and Navigation (ORION) Laboratory at Florida Institute of Technology. We show that Instant NeRF can produce realistic and detailed 3D models of RSOs with low computational cost, while D-NeRF can handle dynamic lighting changes and occlusions. We also discuss the potential applications of our approach for functionality identification and OOS assistance.

**Paper**

[3D Reconstruction of Non-cooperative Resident Space Objects using Instant NGP-accelerated NeRF and D-NeRF](https://arxiv.org/abs/2301.09060)

[Download PDF](https://arxiv.org/pdf/2301.09060.pdf){: .btn .btn--info}

**Keywords:** resident space objects, neural radiance fields, 3D reconstruction, functionality identification, on-orbit servicing.

## Determination of Mutation Rates using Double Stochastic Process.

Mutation rate is a key parameter in evolutionary biology and genetics, but it is difficult to estimate accurately. The most widely used method, Luria–Delbrück method, relies on a simplifying assumption that the number of new mutations in each time step depends only on the total population of bacteria in the previous time step. However, this assumption can lead to errors and biases, due to the inclusion of existing mutants and new mutants from previous time steps. While some can argue that the number of existing mutants and new mutants from previous time frame is negligible, we showed that this number can converge to infinity even with very small mutation rate.

In this paper, we proposed a stochastic estimator that cover these issues of Luria–Delbrück's method, while also rigorously proved the convergence of the estimator in both probability and in L2-space, and validate the model empirically with experiments. Also, we expanded our estimator for the assumption that a microorganism can mutate or turn to 2 variants (which is a precursor to future research of an estimator for any finite n-variants), and showed that the estimator is also converge in probability, L2, and unbiased.

**Paper**

[Determination of Mutation Rates with Two Symmetric and Asymmetric Mutation Types](https://www.mdpi.com/2073-8994/14/8/1701)

[Download PDF](https://mdpi-res.com/d_attachment/symmetry/symmetry-14-01701/article_deploy/symmetry-14-01701.pdf){: .btn .btn--info}

**Keywords:** mutation rate, Luria–Delbrück method, stochastic estimator, convergence analysis, empirical validation.