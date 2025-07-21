import joblib
import numpy as np
import pandas as pd

# Load model and feature names
model = joblib.load('models/contamination_model.pkl')
feature_names = joblib.load('models/contamination_feature_names.pkl')

print("Feature names:", feature_names)

# Test with some sample data
test_data = {
    'Turbidity_NTU': 3000,  # High turbidity
    'Temp_C': 35,  # High temperature
    'TDS_mgL': 800,  # High TDS
    'Hardness_mgL': 240,  # High hardness
    'Conductivity_uS_cm': 512,  # High conductivity
    'DO_mgL': 4  # Low DO
}

# Create DataFrame
df = pd.DataFrame([test_data], columns=feature_names)
print("\nTest data:")
print(df)

# Make prediction
prediction = model.predict(df)[0]
probability = model.predict_proba(df)[0][1]

print("\nPrediction:", prediction)
print("Probability:", probability) 