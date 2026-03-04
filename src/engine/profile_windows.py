debug_symbols = "no"
threads = "yes"

_DEBUG = 0

if _DEBUG:
  optimize = "none"
  lto = "none"
else:
  optimize = "speed"
  lto = "full"
