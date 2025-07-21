const { PythonShell } = require("python-shell");
const path = require("path");

module.exports = (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed" });
    return;
  }
  const inputData = req.body;
  let options = {
    mode: "json",
    pythonOptions: ["-u"],
    scriptPath: path.join(__dirname, "../../scripts"),
    args: [JSON.stringify(inputData)],
  };
  PythonShell.run("predict_disease.py", options, (err, results) => {
    if (err) return res.status(500).json({ error: err.toString() });
    res.json(results[0]);
  });
};
