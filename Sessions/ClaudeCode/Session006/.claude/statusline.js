#!/usr/bin/env node
// Claude Code status line: reads session JSON on stdin, prints a 4-row dashboard.

const fs = require('fs');
const path = require('path');
const os = require('os');

const RESET = '\x1b[0m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const RED = '\x1b[31m';
const DIM = '\x1b[2m';

function readStdin() {
  try {
    return fs.readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function colorForPct(pct) {
  if (pct >= 80) return RED;
  if (pct >= 50) return YELLOW;
  return GREEN;
}

function fmtPct(pct) {
  const c = colorForPct(pct);
  return `${c}${Math.round(pct)}%${RESET}`;
}

function fmtNumber(n) {
  if (n == null) return '0';
  if (n >= 10000) {
    const k = n / 1000;
    return `${k.toFixed(1)}k`;
  }
  return n.toLocaleString('en-US');
}

function fmtDelta(n) {
  return `+${fmtNumber(n)}`;
}

function fmtResetTime(epochSeconds) {
  if (!epochSeconds) return '';
  const now = new Date();
  const reset = new Date(epochSeconds * 1000);
  const sameDay =
    now.getFullYear() === reset.getFullYear() &&
    now.getMonth() === reset.getMonth() &&
    now.getDate() === reset.getDate();

  let hours = reset.getHours();
  const minutes = reset.getMinutes();
  const ampm = hours >= 12 ? 'p' : 'a';
  hours = hours % 12;
  if (hours === 0) hours = 12;
  const timeStr = `${hours}:${String(minutes).padStart(2, '0')}${ampm}`;

  if (sameDay) return timeStr;

  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return `${dayNames[reset.getDay()]} ${timeStr}`;
}

function fmtDuration(ms) {
  if (!ms || ms <= 0) return '';
  const totalSeconds = Math.floor(ms / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  if (hours > 0) return `${hours}h${minutes}m`;
  if (minutes > 0) return `${minutes}m`;
  return `${seconds}s`;
}

function homeRelative(p) {
  if (!p) return p;
  const home = os.homedir();
  if (p.toLowerCase().startsWith(home.toLowerCase())) {
    return '~' + p.slice(home.length).replace(/\\/g, '/');
  }
  return p.replace(/\\/g, '/');
}

function findUp(startDir, relPath) {
  let dir = startDir;
  while (true) {
    const candidate = path.join(dir, relPath);
    if (fs.existsSync(candidate)) return candidate;
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function readJsonSafe(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return null;
  }
}

function getEffortLevel(cwd) {
  const candidates = [
    path.join(cwd, '.claude', 'settings.local.json'),
    path.join(cwd, '.claude', 'settings.json'),
    path.join(os.homedir(), '.claude', 'settings.json'),
  ];
  for (const c of candidates) {
    const json = readJsonSafe(c);
    if (json && typeof json.effortLevel === 'string' && json.effortLevel.length > 0) {
      return json.effortLevel;
    }
  }
  return null;
}

function getGitBranch(cwd) {
  const headPath = findUp(cwd, '.git/HEAD');
  if (!headPath) return null;
  try {
    const content = fs.readFileSync(headPath, 'utf8').trim();
    const match = content.match(/^ref:\s*refs\/heads\/(.+)$/);
    if (match) return match[1];
    return content.slice(0, 7); // detached HEAD, short sha
  } catch {
    return null;
  }
}

function getSfdxOrg(cwd) {
  const configPath = path.join(cwd, '.sfdx', 'sfdx-config.json');
  const json = readJsonSafe(configPath);
  if (json && typeof json.defaultusername === 'string' && json.defaultusername.length > 0) {
    return json.defaultusername.split('@')[0];
  }
  return null;
}

function main() {
  const raw = readStdin();
  let data = {};
  try {
    data = JSON.parse(raw);
  } catch {
    data = {};
  }

  const model = data.model || {};
  const workspace = data.workspace || {};
  const contextWindow = data.context_window || {};
  const rateLimits = data.rate_limits || null;
  const cost = data.cost || {};

  const cwd = workspace.current_dir || process.cwd();

  // Row 1: Gauges
  const ctxPct = contextWindow.used_percentage ?? 0;
  const ctxGauge = `[CTX ${fmtPct(ctxPct)}]`;

  let fiveHourGauge, sevenDayGauge;
  if (rateLimits && rateLimits.five_hour) {
    const pct = rateLimits.five_hour.used_percentage ?? 0;
    const resetStr = fmtResetTime(rateLimits.five_hour.resets_at);
    fiveHourGauge = `[5H ${fmtPct(pct)}${resetStr ? ' ' + resetStr : ''}]`;
  } else {
    fiveHourGauge = '[5H ?]';
  }
  if (rateLimits && rateLimits.seven_day) {
    const pct = rateLimits.seven_day.used_percentage ?? 0;
    const resetStr = fmtResetTime(rateLimits.seven_day.resets_at);
    sevenDayGauge = `[7D ${fmtPct(pct)}${resetStr ? ' ' + resetStr : ''}]`;
  } else {
    sevenDayGauge = '[7D ?]';
  }

  const row1 = `${ctxGauge} ${fiveHourGauge} ${sevenDayGauge}`;

  // Row 2: Tokens
  const totalInput = contextWindow.total_input_tokens ?? 0;
  const totalOutput = contextWindow.total_output_tokens ?? 0;
  const currentUsage = contextWindow.current_usage ?? null;

  let inSeg, outSeg, cacheSeg;
  if (currentUsage) {
    inSeg = `[IN ${fmtNumber(totalInput)} (${DIM}${fmtDelta(currentUsage.input_tokens)}${RESET})]`;
    outSeg = `[OUT ${fmtNumber(totalOutput)} (${DIM}${fmtDelta(currentUsage.output_tokens)}${RESET})]`;
    const written = currentUsage.cache_creation_input_tokens ?? 0;
    const read = currentUsage.cache_read_input_tokens ?? 0;
    cacheSeg = `[CACHE +${fmtNumber(written)} / ${fmtNumber(read)}]`;
  } else {
    inSeg = `[IN ${fmtNumber(totalInput)}]`;
    outSeg = `[OUT ${fmtNumber(totalOutput)}]`;
    cacheSeg = `[CACHE 0 / 0]`;
  }

  const row2 = `${inSeg} ${outSeg} ${cacheSeg}`;

  // Row 3: Session
  const modelName = model.display_name || 'Claude';
  const effort = getEffortLevel(cwd);
  const effortDisplay = effort ? effort.toUpperCase() : '?';
  const duration = fmtDuration(cost.total_duration_ms ?? 0);
  const row3 = `${modelName} · ${effortDisplay} · ${duration}`;

  // Row 4: Location
  const dirDisplay = homeRelative(cwd);
  const branch = getGitBranch(cwd);
  const sfdxOrg = getSfdxOrg(cwd);
  let row4 = dirDisplay;
  if (branch) row4 += ` · ${branch}`;
  if (sfdxOrg) row4 += ` · ${sfdxOrg}`;

  console.log(row1);
  console.log(row2);
  console.log(row3);
  console.log(row4);
}

main();
