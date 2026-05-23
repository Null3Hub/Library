const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

const mode = process.argv[2] === "sourcemap" ? "sourcemap" : "build";
const output = path.join("dist", "ApexLibrary.rbxm");
const args = mode === "sourcemap"
  ? ["sourcemap", "default.project.json", "--output", "sourcemap.json"]
  : ["build", "default.project.json", "-o", output];
const candidates = process.platform === "win32"
  ? [path.join(os.homedir(), ".rokit", "bin", "rojo.exe"), path.join("tools", "rojo.exe"), "rojo.exe", "rojo"]
  : ["rojo", path.join(os.homedir(), ".rokit", "bin", "rojo")];

if (mode === "build") {
  fs.mkdirSync("dist", { recursive: true });
}

for (const candidate of candidates) {
  if (candidate.includes(path.sep) && !fs.existsSync(candidate)) {
    continue;
  }

  const result = spawnSync(candidate, args, {
    stdio: "inherit",
  });

  if (result.error && result.error.code === "ENOENT") {
    continue;
  }

  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }

  process.exit(result.status || 0);
}

console.error("Could not find rojo. Run `rokit install` or provide tools/rojo.exe.");
process.exit(1);
