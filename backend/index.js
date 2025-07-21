const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const { PythonShell } = require("python-shell");
const path = require("path");
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json"); // <-- User must provide this file

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(bodyParser.json());

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://fypwater-92595-default-rtdb.firebaseio.com",
});

const db = admin.database();

let latestSensorData = null;
let debounceTimer = null;
const DEBOUNCE_INTERVAL = 2000; // 2 seconds (reduced from 5 seconds)

// Listen for changes in sensor data
const sensorsRef = db.ref("sensors");
sensorsRef.on("value", (snapshot) => {
  latestSensorData = snapshot.val();
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(processLatestSensorData, DEBOUNCE_INTERVAL);
});

async function processLatestSensorData() {
  if (!latestSensorData) return;
  const data = latestSensorData;

  // Validate sensor values
  const turbidity = parseFloat(data.turbidity);
  const temperature = parseFloat(data.temperature);
  const tds = parseFloat(data.tds);

  // Skip processing if values are invalid
  if (isNaN(turbidity) || isNaN(temperature) || isNaN(tds) || turbidity < 0) {
    return;
  }

  // Prepare input for model
  const input = {
    Turbidity_NTU: turbidity,
    Temp_C: temperature,
    TDS_mgL: tds,
    Hardness_mgL: tds * 0.3,
    Conductivity_uS_cm: tds * 0.64,
    DO_mgL: calculateDO(temperature, tds, turbidity),
  };

  // Call contamination model
  let contamResult = await runPythonModel("predict_contamination.py", input);

  let diseaseResult = { diseases: [] };
  if (contamResult && contamResult.is_contaminated === true) {
    diseaseResult = await runPythonModel("predict_disease.py", input);
  }

  // Write output to Firebase
  db.ref("model_output").set(
    {
      contaminated: contamResult ? contamResult.is_contaminated : false,
      diseases: Array.isArray(diseaseResult.diseases)
        ? diseaseResult.diseases
        : diseaseResult.diseases || [],
      timestamp: new Date().toISOString(),
    },
    (err) => {
      if (err) {
        console.error("[Backend] Error writing model_output:", err);
      }
    }
  );
}

// Helper to call Python model
function runPythonModel(script, input) {
  return new Promise((resolve, reject) => {
    let options = {
      mode: "json",
      pythonOptions: ["-u"],
      scriptPath: path.join(__dirname, "scripts"),
      args: [JSON.stringify(input)],
    };
    const pyshell = new PythonShell(script, options);
    let result = null;
    pyshell.on("message", (message) => {
      result = message;
    });
    pyshell.on("stderr", (stderr) => {
      console.error(`[Backend] [${script}] stderr:`, stderr);
    });
    pyshell.end((err, code, signal) => {
      if (err) {
        console.error(`[Backend] Error running ${script}:`, err);
        return resolve(null);
      }
      if (!result) {
        console.error(
          `[Backend] No results from ${script}. Exit code: ${code}, signal: ${signal}`
        );
        return resolve(null);
      }
      resolve(result);
    });
  });
}

// Helper to calculate DO (same as in app)
function calculateDO(tempC, tdsMgL, turbidityNTU) {
  const tempK = tempC + 273.15;
  const lnDoSat =
    -139.34411 +
    1.575701e5 / tempK -
    6.642308e7 / Math.pow(tempK, 2) +
    1.2438e10 / Math.pow(tempK, 3) -
    8.621949e11 / Math.pow(tempK, 4);
  const doSat = Math.exp(lnDoSat);
  const doTdsCorrected = doSat * (1 - tdsMgL / 1e6);
  const kTurbidity = 0.005;
  const doFinal = doTdsCorrected * (1 - kTurbidity * turbidityNTU);
  return doFinal;
}

// Endpoint for contamination prediction
app.post("/predict/contamination", (req, res) => {
  const inputData = req.body;
  let options = {
    mode: "json",
    pythonOptions: ["-u"],
    scriptPath: path.join(__dirname, "scripts"),
    args: [JSON.stringify(inputData)],
  };
  PythonShell.run("predict_contamination.py", options, (err, results) => {
    if (err) return res.status(500).json({ error: err.toString() });
    res.json(results[0]);
  });
});

// Endpoint for disease prediction
app.post("/predict/disease", (req, res) => {
  const inputData = req.body;
  let options = {
    mode: "json",
    pythonOptions: ["-u"],
    scriptPath: path.join(__dirname, "scripts"),
    args: [JSON.stringify(inputData)],
  };
  PythonShell.run("predict_disease.py", options, (err, results) => {
    if (err) return res.status(500).json({ error: err.toString() });
    res.json(results[0]);
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
