const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

const args = ["src", "Example.client.lua"];
const candidates = process.platform === "win32"
  ? [path.join(os.homedir(), ".rokit", "bin", "selene.exe"), "selene.exe", "selene"]
  : ["selene", path.join(os.homedir(), ".rokit", "bin", "selene")];

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

console.error("Could not find selene. Run `rokit install` first.");
process.exit(1);
