import sys
import json
import joblib
import numpy as np
import pandas as pd
import os

def predict_contamination(input_data):
    try:
        # Get the script's directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        # Load model and feature names from the correct path
        model_path = os.path.join(script_dir, '..', 'models', 'contamination_model.pkl')
        feature_names_path = os.path.join(script_dir, '..', 'models', 'contamination_feature_names.pkl')
        
        model = joblib.load(model_path)
        feature_names = joblib.load(feature_names_path)
        
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
        prediction = model.predict(df)[0]
        probability = model.predict_proba(df)[0][1]  # Probability of contamination
        
        result = {
            'is_contaminated': bool(prediction),
            'probability': float(probability)
        }
       
        return result
        
    except Exception as e:
        print(f"Error in predict_contamination: {str(e)}", file=sys.stderr)
        return None

if __name__ == "__main__":
    if len(sys.argv) > 1:
        input_data = sys.argv[1]
        result = predict_contamination(input_data)
        if result:
            print(json.dumps(result))
        else:
            print(json.dumps({"error": "Failed to make prediction"})) 