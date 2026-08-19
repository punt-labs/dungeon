import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { readFile, writeFile, unlink, readdir } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

// Resolve paths relative to the plugin root (one level up from mcp/), which is
// ${CLAUDE_PLUGIN_ROOT} — the plugin/ directory a marketplace install checks
// out. Everything read below is inside it by construction (DES-023).
const pluginRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const scriptsDir = join(pluginRoot, "scripts");
const assetsDir = join(pluginRoot, "assets");
const manifestFile = join(pluginRoot, ".claude-plugin", "plugin.json");

// State file lives in the project root (wherever Claude Code is running)
const stateFile = join(process.cwd(), ".claude", "dungeon.local.md");

// Read the version from the manifest instead of restating it. Hardcoded, it
// drifted: this file announced 0.1.2 to every client while the plugin shipped
// as 0.1.6. The manifest is the one place a release bumps.
let version = "0.0.0";
try {
  version = JSON.parse(await readFile(manifestFile, "utf-8")).version ?? version;
} catch (err) {
  process.stderr.write(`dungeon: cannot read version from ${manifestFile}: ${err.message}\n`);
}

const server = new McpServer(
  { name: "dungeon", version },
  { instructions: "Dungeon game state tools. Use these instead of Read/Write for all dungeon game I/O." }
);

// ── recall ──────────────────────────────────────────────────────────────────
server.registerTool("recall", {
  description: "Load the current game state. Returns file content or NO_SAVE_FILE if no game in progress.",
}, async () => {
  try {
    const content = await readFile(stateFile, "utf-8");
    return { content: [{ type: "text", text: content }] };
  } catch (err) {
    if (err.code === "ENOENT") {
      return { content: [{ type: "text", text: "NO_SAVE_FILE" }] };
    }
    throw err;
  }
});

// ── inscribe ────────────────────────────────────────────────────────────────
server.registerTool("inscribe", {
  description: "Save game state. Pass the full file content (YAML frontmatter + adventure log).",
  inputSchema: {
    content: z.string().describe("Full game state file content"),
  },
}, async ({ content }) => {
  await writeFile(stateFile, content, "utf-8");
  return { content: [{ type: "text", text: "OK" }] };
});

// ── obliterate ──────────────────────────────────────────────────────────────
server.registerTool("obliterate", {
  description: "Delete the save file (for starting a new game).",
}, async () => {
  try {
    await unlink(stateFile);
    return { content: [{ type: "text", text: "OK" }] };
  } catch (err) {
    if (err.code === "ENOENT") {
      return { content: [{ type: "text", text: "NO_SAVE_FILE" }] };
    }
    throw err;
  }
});

// ── unfurl_scroll ───────────────────────────────────────────────────────────
server.registerTool("unfurl_scroll", {
  description: "Read an adventure script by name (without .md extension).",
  inputSchema: {
    name: z.string().describe("Script name, e.g. 'classic-fantasy-dungeon'"),
  },
}, async ({ name }) => {
  const safeName = name.replace(/[^a-zA-Z0-9_-]/g, "");
  const content = await readFile(join(scriptsDir, `${safeName}.md`), "utf-8");
  return { content: [{ type: "text", text: content }] };
});

// ── quest_board ─────────────────────────────────────────────────────────────
server.registerTool("quest_board", {
  description: "List available adventure scripts with titles and descriptions.",
}, async () => {
  const files = (await readdir(scriptsDir)).filter(f => f.endsWith(".md")).sort();
  const scripts = [];
  for (const file of files) {
    const text = await readFile(join(scriptsDir, file), "utf-8");
    const fm = text.match(/^---\n([\s\S]*?)\n---/);
    let title = file.replace(".md", "");
    let description = "";
    if (fm) {
      const titleMatch = fm[1].match(/^title:\s*"?(.+?)"?\s*$/m);
      const descMatch = fm[1].match(/^description:\s*"?(.+?)"?\s*$/m);
      if (titleMatch) title = titleMatch[1];
      if (descMatch) description = descMatch[1];
    }
    scripts.push(`${file.replace(".md", "")}: ${title} — ${description}`);
  }
  return { content: [{ type: "text", text: scripts.join("\n") }] };
});

// ── scry ────────────────────────────────────────────────────────────────────
server.registerTool("scry", {
  description: "Read the shared ASCII art assets file.",
}, async () => {
  const content = await readFile(join(assetsDir, "ascii-art.md"), "utf-8");
  return { content: [{ type: "text", text: content }] };
});

// ── Start ─────────────────────────────────────────────────────────────────────
const transport = new StdioServerTransport();
await server.connect(transport);
