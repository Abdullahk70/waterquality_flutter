# Water Quality Backend

This is the Node.js backend for the Water Quality Monitoring project. It exposes endpoints to run trained machine learning models for contamination detection and disease prediction.

## Setup

1. Install dependencies:

   ```
   npm install
   ```

2. Make sure you have Python 3 and the following Python packages installed:

   - joblib
   - numpy
   - scikit-learn
   - pandas
   - imbalanced-learn

3. The trained models are located in `backend/models/`.

## Running the Backend

```
node index.js
```

The server will start on port 5000 by default.

## API Endpoints

### POST `/predict/contamination`

- **Description:** Predicts if the water is contaminated based on sensor data.
- **Body:** JSON object with feature values (same order as used in training).
- **Response:** `{ "contaminated": 0 or 1 }`

### POST `/predict/disease`

- **Description:** Predicts possible diseases if water is contaminated.
- **Body:** JSON object with feature values (same order as used in training).
- **Response:** `{ "diseases": ["Disease1", "Disease2", ...] }`

## Model Scripts

- `scripts/predict_contamination.py`: Runs the contamination model.
- `scripts/predict_disease.py`: Runs the disease model.

Both scripts expect a single JSON string argument with the feature values.
