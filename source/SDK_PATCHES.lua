-- [License] This file is dedicated to the public domain, and marked with CC0 1.0.
--           To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

-- This file contains bug fixes for bugs in the CoreLibs of Playdate SDK 2.0.3
-- If you import any of the libraries listed below in your app, make sure to import this
-- file after all other imports in your main file.
-- Affected libraries:
-- - CoreLibs/timer

local function printFix(bugDescription)
  print("[Fixing bug]: "..bugDescription)
end

if playdate.timer then
  printFix("Pausing a Timer doesn't work properly")
  function playdate.timer:start()
    self._lastTime = nil
    self.paused = false
  end
end
