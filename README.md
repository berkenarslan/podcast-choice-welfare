# Podcast Attention and Welfare  
**Code and Data for MSc Dissertation (University of Nottingham, 2025)**  
This repository contains the SQL and Python scripts, as well as supporting data samples, used in the MSc dissertation:  
**“Podcast Attention and Welfare – A Multinomial Logit Estimation of Consumer Choice.”**

## Overview
The project investigates podcast consumption choices and their welfare implications using a discrete choice modelling framework.  
Key research questions include:  
1. **Baseline drivers:** To what extent do content quality, time cost, and sponsorship shape podcast consumption?  
2. **Heterogeneity:** How do demographic factors (age, gender, education, income, frequency) moderate these sensitivities?  
3. **Welfare:** How does sponsorship affect consumer surplus, on average and across groups?  

## Methods
- **Data construction:**  
  - Pew Research Center survey (simulated listener profiles).  
  - ListenNotes podcast metadata (mapped to Pew 12-category taxonomy via *Primary Bucket* approach).  
- **Cleaning & transformation:** SQL pipelines in BigQuery (`sql/` folder).  
- **Estimation:** Multinomial Logit (MNL) with weighted maximum likelihood.  
- **Heterogeneity:** Interaction terms between podcast attributes and demographics.  
- **Welfare analysis:** Log-sum-exp consumer surplus; counterfactual scenarios (Sponsor=0; sponsorship intensity scaling).  


##  Repository Structure

| Folder / File      | Description                                      |
|--------------------|--------------------------------------------------|
| 📁 `sql/`          | BigQuery scripts for data cleaning & panel setup |
| 📁 `python/`       | Estimation & welfare analysis scripts            |
| 📁 `data/`         | Sample anonymised / simulated datasets           |
| 📁 `results/`      | Model summaries, figures & tables                |
| 📄 `README.md`     | Project documentation                            |
| 📄 `requirements.txt` | Python dependencies                          |


## Reproducibility  
- **SQL**: Scripts designed for Google BigQuery.  
- **Python**: Requires Python 3.9+; see `requirements.txt` for full list.  
- **Data**: Only sample datasets are included here. Full metadata available via ListenNotes API; full Pew demographic distributions publicly available.  


## Limitations  
- Analysis relies on **simulated choices**, not directly observed selections.  
- MNL entails the **IIA assumption**, which may be restrictive given similar podcasts.  
- Sponsorship treated as binary; no differentiation by ad type, length, or intensity.  
- No explicit outside option modelled, so the focus is on **ΔCS** rather than absolute CS values.  


## Citation  
If using this work, please cite:  

**Arslan, B. (2025).** *Podcast Attention and Welfare – A Multinomial Logit Estimation of Consumer Choice.* MSc Dissertation, University of Nottingham.  


