import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import (
    hamming_loss, jaccard_score, classification_report,
    confusion_matrix, ConfusionMatrixDisplay
)
from sklearn.metrics import roc_curve, auc
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from imblearn.over_sampling import SMOTE
from sklearn.multiclass import OneVsRestClassifier
from sklearn.preprocessing import MultiLabelBinarizer
import joblib
import os

# Ensure models directory exists
os.makedirs('models', exist_ok=True)

# Load data
df = pd.read_csv('New1_Updated_water_quality_dataset.csv')

### === STAGE 1: CONTAMINATION DETECTION === ###
# Use only features that match frontend logic
X_contam = df[['Turbidity_NTU', 'Temp_C', 'TDS_mgL', 'Hardness_mgL', 'Conductivity_uS_cm', 'DO_mgL']]
y_contam = df['Contaminated'].astype(int)

if len(y_contam.unique()) < 2:
    raise ValueError("Only one contamination class detected. Regenerate dataset with more variety.")

# Apply SMOTE to handle class imbalance
smote = SMOTE(random_state=42)
X_res, y_res = smote.fit_resample(X_contam, y_contam)

# Train/test split
X_train_c, X_test_c, y_train_c, y_test_c = train_test_split(
    X_res, y_res, test_size=0.3, random_state=42)

# Train contamination model
contam_model = RandomForestClassifier(
    n_estimators=200,
    max_depth=10,  # Limit depth to prevent overfitting
    min_samples_split=5,  # Require more samples to split
    class_weight='balanced',
    random_state=42
)
contam_model.fit(X_train_c, y_train_c)

# Evaluate contamination model
preds = contam_model.predict(X_test_c)
print("\n=== STAGE 1: CONTAMINATION DETECTION ===")
print(classification_report(y_test_c, preds))

# Save feature names for prediction
feature_names = X_contam.columns.tolist()
joblib.dump(feature_names, 'models/contamination_feature_names.pkl')

# Save contamination model
joblib.dump(contam_model, 'models/contamination_model.pkl')

### === STAGE 2: DISEASE PREDICTION === ###
# Only predict diseases for contaminated samples
contam_df = df[df['Contaminated'] == 1].copy()

# Convert disease lists to binary format
mlb = MultiLabelBinarizer()
y_disease = mlb.fit_transform(contam_df['Diseases'].apply(eval))
X_disease = contam_df[['Turbidity_NTU', 'Temp_C', 'TDS_mgL', 'Hardness_mgL', 'Conductivity_uS_cm', 'DO_mgL']]

# Train/test split
X_train_d, X_test_d, y_train_d, y_test_d = train_test_split(
    X_disease, y_disease, test_size=0.2, random_state=42)

# Train disease model
disease_model = OneVsRestClassifier(
    RandomForestClassifier(
        n_estimators=200,
        max_depth=10,  # Limit depth to prevent overfitting
        min_samples_split=5,  # Require more samples to split
        class_weight='balanced',
        random_state=42
    )
)
disease_model.fit(X_train_d, y_train_d)

# Evaluate disease model
preds_d = disease_model.predict(X_test_d)

print("\n=== STAGE 2: DISEASE PREDICTION ===")
print("Exact Match Ratio:", np.mean(np.all(y_test_d == preds_d, axis=1)))
print(classification_report(y_test_d, preds_d, target_names=mlb.classes_))
print("✅ Hamming Loss:", hamming_loss(y_test_d, preds_d))
print("✅ Jaccard Score (Micro):", jaccard_score(y_test_d, preds_d, average='micro'))
print("✅ Jaccard Score (Macro):", jaccard_score(y_test_d, preds_d, average='macro'))

# Save disease model and label binarizer
joblib.dump((disease_model, mlb), 'models/disease_model.pkl')

# Save feature names for prediction
joblib.dump(X_disease.columns.tolist(), 'models/disease_feature_names.pkl')

print("\n✅ Models saved in 'models' directory:")
print("- contamination_model.pkl")
print("- disease_model.pkl")
print("- contamination_feature_names.pkl")
print("- disease_feature_names.pkl")

# 📊 Confusion matrix
cm = confusion_matrix(y_test_c, preds)
disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=['Clean', 'Contaminated'])
disp.plot(cmap=plt.cm.Blues)
plt.title("Confusion Matrix - Contamination Detection")
plt.tight_layout()
plt.show()

# 📊 Confusion Matrix for Each Disease Label
for i, disease in enumerate(mlb.classes_):
    y_true = y_test_d[:, i]
    y_pred = preds_d[:, i]

    # Only plot if both classes (0 and 1) are present
    if len(np.unique(y_true)) < 2:
        print(f"Skipping confusion matrix for {disease} — only one class present.")
        continue

    cm_disease = confusion_matrix(y_true, y_pred)
    disp_disease = ConfusionMatrixDisplay(confusion_matrix=cm_disease, display_labels=["No", "Yes"])
    disp_disease.plot(cmap=plt.cm.Purples)
    plt.title(f"Confusion Matrix - {disease}")
    plt.tight_layout()
    plt.show()

# === ROC Curves for each Disease Class ===
from itertools import cycle
colors = cycle(plt.cm.tab10.colors)  # Use a color cycle for better variety

for i, disease in enumerate(mlb.classes_):
    y_true = y_test_d[:, i]
    y_score = disease_model.predict_proba(X_test_d)[:, i]  # Probabilities

    # Ensure ROC curve is meaningful
    if len(np.unique(y_true)) < 2:
        print(f"Skipping ROC for {disease} — only one class present.")
        continue

    fpr, tpr, _ = roc_curve(y_true, y_score)
    roc_auc = auc(fpr, tpr)

    plt.figure()
    plt.plot(fpr, tpr, color=next(colors), lw=2,
             label=f'AUC = {roc_auc:.2f}')
    plt.plot([0, 1], [0, 1], color='gray', linestyle='--')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title(f'ROC Curve - {disease}')
    plt.legend(loc="lower right")
    plt.tight_layout()
    plt.show()

# === ROC Curves (All Diseases in One Plot) ===
from itertools import cycle
colors = cycle(plt.cm.tab10.colors)  # Rotate through color palette

plt.figure(figsize=(10, 8))

for i, disease in enumerate(mlb.classes_):
    y_true = y_test_d[:, i]
    y_score = disease_model.predict_proba(X_test_d)[:, i]  # Probabilities

    # Skip diseases with only one class in test set
    if len(np.unique(y_true)) < 2:
        print(f"Skipping ROC for {disease} — only one class present.")
        continue

    fpr, tpr, _ = roc_curve(y_true, y_score)
    roc_auc = auc(fpr, tpr)

    plt.plot(fpr, tpr, lw=2, color=next(colors),
             label=f"{disease} (AUC = {roc_auc:.2f})")

# Plot the reference line (random guess)
plt.plot([0, 1], [0, 1], color='gray', linestyle='--', lw=1)

plt.xlim([0.0, 1.0])
plt.ylim([0.0, 1.05])
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('Multi-Class ROC Curve - Disease Prediction')
plt.legend(loc="lower right", fontsize='small')
plt.grid(True)
plt.tight_layout()
plt.show()