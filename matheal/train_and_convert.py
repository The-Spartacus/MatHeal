import pandas as pd
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
import numpy as np

# --- 1. Load and Preprocess the Data ---

print("Loading data.csv...")
# Load the dataset using pandas
data = pd.read_csv('data/data.csv')

# Define the input features and the target variable to be predicted
features = ['Age', 'SystolicBP', 'DiastolicBP', 'BS', 'BodyTemp', 'HeartRate']
target = 'RiskLevel'

X = data[features].values
y = data[target]

# --- 2. Encode Labels and Scale Features ---

# Use scikit-learn's LabelEncoder to convert the text labels 
# (e.g., 'low risk', 'mid risk') into numbers (0, 1, 2)
print("Encoding labels...")
label_encoder = LabelEncoder()
y_encoded = label_encoder.fit_transform(y)
# One-hot encode the numerical labels for the neural network's output layer
y_categorical = tf.keras.utils.to_categorical(y_encoded)

# Use scikit-learn's StandardScaler to normalize the feature data.
# This is a critical step for neural networks to perform well.
print("Scaling features...")
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Split the data into a training set (80%) and a testing set (20%)
X_train, X_test, y_train, y_test = train_test_split(X_scaled, y_categorical, test_size=0.2, random_state=42)

print(f"Data prepared: {len(X_train)} training samples, {len(X_test)} testing samples.")

# --- 3. Build and Train the TensorFlow Model ---

print("Building the TensorFlow model...")
# Create a simple sequential neural network using TensorFlow/Keras
model = tf.keras.Sequential([
    # Input layer expects a shape matching the number of features
    tf.keras.layers.Input(shape=(len(features),)),
    # Hidden layers with ReLU activation
    tf.keras.layers.Dense(32, activation='relu'),
    tf.keras.layers.Dense(16, activation='relu'),
    # Output layer with a softmax activation for multi-class classification
    # The number of units must match the number of risk categories (low, mid, high)
    tf.keras.layers.Dense(y_categorical.shape[1], activation='softmax')
])

# Compile the model with an optimizer, loss function, and metrics
model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

print("Training the model...")
# Train the model on the training data
model.fit(X_train, y_train, epochs=50, batch_size=10, validation_split=0.2, verbose=2)

print("\nModel training complete.")

# --- 4. Convert and Save the Model to TensorFlow Lite format ---

print("Converting model to TensorFlow Lite format...")
# Create a TFLite converter from the trained Keras model
converter = tf.lite.TFLiteConverter.from_keras_model(model)
# Apply default optimizations to reduce the model size
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Save the converted model to a file
with open('model.tflite', 'wb') as f:
    f.write(tflite_model)

print("✅ Model successfully converted and saved as model.tflite")
print("You can now add this file to your Flutter project's assets.")