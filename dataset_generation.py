import pandas as pd
import numpy as np
from math import exp, pow

np.random.seed(42)
N = 10000  # Number of samples

def generate_water_data(n_samples):
    # Increase contaminated samples to 60%
    n_clean = int(n_samples * 0.4)
    n_contaminated = n_samples - n_clean

    def noise(): return np.random.normal(1, 0.03)

    # Make clean water ranges more balanced
    clean = {
        'Turbidity_NTU': np.random.uniform(1800, 2500, n_clean),  # Wider range
        'Temp_C': np.random.uniform(12, 25, n_clean),  # Wider range
        'TDS_mgL': np.random.uniform(20, 500, n_clean)  # Wider range
    }

    # Make contaminated water ranges more extreme but not too extreme
    contaminated = {
        'Turbidity_NTU': np.concatenate([
            np.random.uniform(500, 1799, n_contaminated // 2),  # Below safe range
            np.random.uniform(2501, 3500, n_contaminated - (n_contaminated // 2))  # Above safe range
        ]),
        'Temp_C': np.concatenate([
            np.random.uniform(0, 11, n_contaminated // 2),  # Below safe range
            np.random.uniform(26, 38, n_contaminated - (n_contaminated // 2))  # Above safe range
        ]),
        'TDS_mgL': np.concatenate([
            np.random.uniform(1, 19, n_contaminated // 2),  # Below safe range
            np.random.uniform(501, 2000, n_contaminated - (n_contaminated // 2))  # Above safe range
        ])
    }

    data = {key: np.concatenate([clean[key], contaminated[key]]) for key in clean}
    clean_mask = np.array([True] * n_clean + [False] * n_contaminated)

    hardness, conductivity, do = [], [], []
    turb, temp, tds = data['Turbidity_NTU'], data['Temp_C'], data['TDS_mgL']

    def calculate_do(tempC, tdsMgL, turbidityNTU):
        tempK = tempC + 273.15
        lnDoSat = -139.34411 + (1.575701e5 / tempK) - (6.642308e7 / pow(tempK, 2)) + \
                  (1.243800e10 / pow(tempK, 3)) - (8.621949e11 / pow(tempK, 4))
        doSat = exp(lnDoSat)
        doTdsCorrected = doSat * (1 - tdsMgL / 1e6)
        kTurbidity = 0.005  # Match backend value
        doFinal = doTdsCorrected * (1 - kTurbidity * turbidityNTU)
        return max(0, doFinal)

    for i in range(n_samples):
        # Match backend calculations
        h = tds[i] * 0.3  # Match backend and frontend
        c = tds[i] * 0.64
        d = calculate_do(temp[i], tds[i], turb[i])

        if clean_mask[i]:
            h, c, d = np.clip(h, 80, 100), np.clip(c, 100, 500), np.clip(d, 6, 10)
        else:
            h, c, d = np.clip(h, 50, 150), np.clip(c, 50, 1000), np.clip(d, 0, 12)

        hardness.append(h)
        conductivity.append(c)
        do.append(d)

    data['Hardness_mgL'] = hardness
    data['Conductivity_uS_cm'] = conductivity
    data['DO_mgL'] = do

    return pd.DataFrame(data)

def is_contaminated(row):
    # Make contamination detection more sensitive but not too strict
    # Check turbidity first
    if row['Turbidity_NTU'] < 1800 or row['Turbidity_NTU'] > 2500:
        return True
    
    # More balanced checks for other parameters
    return (
        (row['Temp_C'] < 12 or row['Temp_C'] > 25) or  # Wider temperature range
        (row['TDS_mgL'] < 20 or row['TDS_mgL'] > 500) or  # Wider TDS range
        (row['Hardness_mgL'] < 80 or row['Hardness_mgL'] > 100) or  # Wider hardness range
        (row['Conductivity_uS_cm'] > 500) or  # Standard conductivity threshold
        (row['DO_mgL'] < 6 or row['DO_mgL'] > 10)  # Standard DO range
    )

def get_diseases(row):
    if not row['Contaminated']:
        return []

    diseases = []

    # Keep high disease probabilities
    probs = {
        'Cholera': 0.90,
        'Diarrhea': 0.95,
        'Dysentery': 0.85,
        'Electrolyte_Imbalance': 0.80,
        'Hypertension': 0.75,
        'Hypothermia_Risk': 0.90,
        'Hypoxia': 0.85,
        'Kidney_Stones': 0.70,
        'Mineral_Deficiency': 0.80
    }

    def rand(p): return np.random.rand() < p

    # More sensitive disease triggers but with balanced thresholds
    if row['Turbidity_NTU'] > 2500:  # Standard threshold
        if rand(probs['Cholera']):
            diseases.append('Cholera')
        if rand(probs['Dysentery']):
            diseases.append('Dysentery')
    elif row['Turbidity_NTU'] < 1800 and rand(probs['Mineral_Deficiency']):  # Standard threshold
        diseases.append('Mineral_Deficiency')

    # More sensitive temperature checks
    if row['Temp_C'] > 25 and rand(probs['Diarrhea']):  # Standard threshold
        diseases.append('Diarrhea')
    elif row['Temp_C'] < 12 and rand(probs['Hypothermia_Risk']):  # Standard threshold
        diseases.append('Hypothermia_Risk')

    # More sensitive TDS checks
    if row['TDS_mgL'] > 500:  # Standard threshold
        if rand(probs['Hypertension']):
            diseases.append('Hypertension')
        if rand(probs['Kidney_Stones']):
            diseases.append('Kidney_Stones')
    elif row['TDS_mgL'] < 20 and rand(probs['Mineral_Deficiency']):  # Standard threshold
        diseases.append('Mineral_Deficiency')

    # More sensitive hardness checks
    if row['Hardness_mgL'] > 100 and rand(probs['Kidney_Stones']):  # Standard threshold
        diseases.append('Kidney_Stones')
    elif row['Hardness_mgL'] < 80:  # Standard threshold
        diseases.append('Cardiovascular_Risk')

    # More sensitive conductivity check
    if row['Conductivity_uS_cm'] > 500 and rand(probs['Electrolyte_Imbalance']):  # Standard threshold
        diseases.append('Electrolyte_Imbalance')

    # More sensitive DO check
    if row['DO_mgL'] < 6 and rand(probs['Hypoxia']):  # Standard threshold
        diseases.append('Hypoxia')

    return list(set(diseases))  # Unique diseases only

if __name__ == "__main__":
    df = generate_water_data(N)
    df['Contaminated'] = df.apply(is_contaminated, axis=1)
    df['Diseases'] = df.apply(get_diseases, axis=1)

    print("\nDataset Statistics:")
    print("Total samples:", len(df))
    print("\nContamination Distribution:")
    print(df['Contaminated'].value_counts())
    print("\nDisease Distribution:")
    disease_counts = df['Diseases'].explode().value_counts()
    print(disease_counts)
    
    df.to_csv('New1_Updated_water_quality_dataset.csv', index=False)
    print("\n✅ Dataset saved as 'New1_Updated_water_quality_dataset.csv'")