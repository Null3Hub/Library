const fs = require("fs");
const path = require("path");

const ROOT_DIR = "src";
const OUT_FILE = path.join("dist", "ApexLibrary.lua");
const HEADER_FILE = path.join("build", "header.lua");

function toPosix(filePath) {
  return filePath.split(path.sep).join("/");
}

function luaLongString(value) {
  let equals = "";
  while (value.includes(`]${equals}]`)) {
    equals += "=";
  }
  return `[${equals}[${value}]${equals}]`;
}

function listEntries(dir) {
  return fs.readdirSync(dir, { withFileTypes: true })
    .filter((entry) => !entry.name.startsWith("."))
    .sort((a, b) => a.name.localeCompare(b.name));
}

function moduleNameFromFile(fileName) {
  return path.basename(fileName, path.extname(fileName));
}

function buildNode(dir, name, parentPath) {
  const initFile = path.join(dir, "init.lua");
  const hasInit = fs.existsSync(initFile);
  const sourcePath = hasInit ? toPosix(initFile) : null;
  const nodePath = parentPath ? `${parentPath}.${name}` : name;
  const children = [];

  for (const entry of listEntries(dir)) {
    const entryPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      children.push(buildNode(entryPath, entry.name, nodePath));
      continue;
    }

    if (!entry.isFile() || path.extname(entry.name) !== ".lua" || entry.name === "init.lua") {
      continue;
    }

    children.push({
      name: moduleNameFromFile(entry.name),
      className: "ModuleScript",
      sourcePath: toPosix(entryPath),
      nodePath: `${nodePath}.${moduleNameFromFile(entry.name)}`,
      children: [],
    });
  }

  return {
    name,
    className: hasInit ? "ModuleScript" : "Folder",
    sourcePath,
    nodePath,
    children,
  };
}

function collectSources(node, sources) {
  if (node.sourcePath) {
    sources[node.sourcePath] = fs.readFileSync(node.sourcePath, "utf8");
  }

  for (const child of node.children) {
    collectSources(child, sources);
  }
}

function emitNode(node, indent = "") {
  const nextIndent = `${indent}    `;
  const children = node.children.map((child) => emitNode(child, nextIndent)).join(",\n");

  return `${indent}{\n` +
    `${nextIndent}Name = ${JSON.stringify(node.name)},\n` +
    `${nextIndent}ClassName = ${JSON.stringify(node.className)},\n` +
    `${nextIndent}Source = ${node.sourcePath ? JSON.stringify(node.sourcePath) : "nil"},\n` +
    `${nextIndent}Children = {${children ? `\n${children}\n${nextIndent}` : ""}},\n` +
    `${indent}}`;
}

function emitSources(sources) {
  return Object.keys(sources).sort().map((sourcePath) => {
    return `    [${JSON.stringify(sourcePath)}] = ${luaLongString(sources[sourcePath])},`;
  }).join("\n");
}

function main() {
  if (!fs.existsSync(ROOT_DIR)) {
    throw new Error(`Missing ${ROOT_DIR}/ directory`);
  }

  const root = buildNode(ROOT_DIR, "ApexLibrary", "");
  if (root.className !== "ModuleScript") {
    throw new Error("src/init.lua is required for bundling");
  }

  const sources = {};
  collectSources(root, sources);
  fs.mkdirSync(path.dirname(OUT_FILE), { recursive: true });

  const header = fs.existsSync(HEADER_FILE) ? fs.readFileSync(HEADER_FILE, "utf8") : "";
  const output = `${header.trim()}\n\n` +
`local __apex_sources = {\n${emitSources(sources)}\n}\n\n` +
`local __apex_tree = ${emitNode(root)}\n\n` +
`local __apex_cache = {}\n` +
`local __apex_require = require\n` +
`local __apex_unpack = unpack or table.unpack\n\n` +
`local function __apex_attach(node, parent)\n` +
`    node.Parent = parent\n` +
`    node.__apex_virtual = true\n` +
`    node.__apex_child_map = {}\n\n` +
`    for _, child in ipairs(node.Children or {}) do\n` +
`        node.__apex_child_map[child.Name] = child\n` +
`        __apex_attach(child, node)\n` +
`    end\n\n` +
`    return setmetatable(node, {\n` +
`        __index = function(self, key)\n` +
`            if key == "GetChildren" then\n` +
`                return function() return self.Children or {} end\n` +
`            elseif key == "FindFirstChild" then\n` +
`                return function(_, name) return self.__apex_child_map[name] end\n` +
`            end\n` +
`            return self.__apex_child_map[key]\n` +
`        end,\n` +
`        __tostring = function(self) return self.Name end,\n` +
`    })\n` +
`end\n\n` +
`local function __apex_load(module)\n` +
`    if type(module) ~= "table" or module.__apex_virtual ~= true then\n` +
`        return __apex_require(module)\n` +
`    end\n\n` +
`    if module.ClassName ~= "ModuleScript" then\n` +
`        error("Attempted to require a virtual " .. tostring(module.ClassName), 2)\n` +
`    end\n\n` +
`    if __apex_cache[module] then\n` +
`        return __apex_unpack(__apex_cache[module])\n` +
`    end\n\n` +
`    local source = __apex_sources[module.Source]\n` +
`    if type(source) ~= "string" then\n` +
`        error("Missing bundled source for " .. tostring(module.Source), 2)\n` +
`    end\n\n` +
`    local loader, compileError = loadstring(source, "@" .. tostring(module.Source))\n` +
`    if not loader then\n` +
`        error(compileError, 2)\n` +
`    end\n\n` +
`    local env = setmetatable({\n` +
`        script = module,\n` +
`        require = __apex_load,\n` +
`    }, { __index = getfenv(0) })\n\n` +
`    setfenv(loader, env)\n` +
`    local result = { loader() }\n` +
`    __apex_cache[module] = result\n` +
`    return __apex_unpack(result)\n` +
`end\n\n` +
`__apex_attach(__apex_tree, nil)\n` +
`return __apex_load(__apex_tree)\n`;

  fs.writeFileSync(OUT_FILE, output, "utf8");
  console.log(`Wrote ${OUT_FILE}`);
}

main();
