-- Minimal Lua test runner (no external deps)
-- Usage: lua tests/run.lua

local function listdir(path)
  local p = io.popen('dir /b "' .. path .. '"')
  if not p then return {} end
  local out = {}
  for name in p:lines() do
    table.insert(out, name)
  end
  p:close()
  table.sort(out)
  return out
end

local function ends_with(str, suffix)
  return str:sub(-#suffix) == suffix
end

local testsDir = "tests"
local failures = 0

for _, file in ipairs(listdir(testsDir)) do
  if ends_with(file, "_test.lua") then
    io.write("Running ", testsDir .. "/" .. file, "...\n")
    local ok, err = pcall(dofile, testsDir .. "/" .. file)
    if not ok then
      failures = failures + 1
      io.write("  FAIL: ", tostring(err), "\n")
    end
  end
end

if failures > 0 then
  io.write("\nFAILED ", failures, " test file(s).\n")
  os.exit(1)
end

io.write("\nOK\n")
