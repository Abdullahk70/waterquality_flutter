import sys
import json
import joblib
import numpy as np
import pandas as pd

def predict_disease(input_data):
    try:
        # Load model, label binarizer, and feature names
        model, mlb = joblib.load('models/disease_model.pkl')
        feature_names = joblib.load('models/disease_feature_names.pkl')
        
        # Convert input to DataFrame with correct feature names
        if isinstance(input_data, str):
            try:
                # Try parsing as JSON first
                data = json.loads(input_data)
            except json.JSONDecodeError:
                # If not JSON, try parsing as Python dict string
                data = eval(input_data)
        else:
            data = input_data
            
        # Create DataFrame with correct feature order
        df = pd.DataFrame([data], columns=feature_names)
        
        # Make prediction
        predictions = model.predict(df)[0]
        probabilities = model.predict_proba(df)[0]
        
        # Get predicted diseases and their probabilities
        predicted_diseases = []
        for i, (disease, pred, prob) in enumerate(zip(mlb.classes_, predictions, probabilities)):
            if pred:
                predicted_diseases.append({
                    'name': disease,
                    'probability': float(prob)
                })
        
        return {
            'diseases': predicted_diseases
        }
        
    except Exception as e:
        print(f"Error in predict_disease: {str(e)}", file=sys.stderr)
        return None

if __name__ == "__main__":
    if len(sys.argv) > 1:
        input_data = sys.argv[1]
        result = predict_disease(input_data)
        if result:
            print(json.dumps(result))
        else:
            print(json.dumps({"error": "Failed to make prediction"})) 