---
layout: single
title: Researches
permalink: /research/
---

## Learning Representations of Electronic Health Records for Synthetic Data Generation

The goal of this project is to develop a learnable representations (embeddings) of electronic health records (EHRs), use the embeddings to generate synthetic embeddings with GANs, and develop a scalable Synthetic Patient Records pipeline from generated embeddings.

### Proposal/White Paper

[Download PDF](/_pages/ehr.pdf){: .btn .btn--info}
<embed src="/_pages/ehr.pdf" type="application/pdf" width="100%" height="100%"/>

## Determination of Mutation Rates using Double Stochastic Process.

Paper link: [Determination of Mutation Rates with Two Symmetric and Asymmetric Mutation Types](https://www.mdpi.com/2073-8994/14/8/1701)

[Download PDF](https://mdpi-res.com/d_attachment/symmetry/symmetry-14-01701/article_deploy/symmetry-14-01701.pdf){: .btn .btn--info}

We researched on a more rigorous approach to estimate mutation rate using branching process. Currently, Luria–Delbrück method is widely used to estimate bacteria mutation rate. However, this method assumes that new number of mutations in current time is based off the total population of bacteria in previous time frame, which includes already mutated at previous time frame, and already existing mutants in the population. While some can argue that the number of existing mutants and new mutats from previous time frame is negligible, we showed that this number can converge to infinity even with very small mutation rate.

We proposed a stochastic estimator that cover these issues of Luria–Delbrück's method, while also rigorously proved the convergence of the estimator in both probability and in L2-space, and validate the model empirically with experiments. Also, we expanded our estimator for the assumumption that a microorganism can mutate or turn to 2 variants (which is a precursor to future research of an estimator for any finite n-variants), and showed that the estimator is also converge in probability, L2, and unbiased.