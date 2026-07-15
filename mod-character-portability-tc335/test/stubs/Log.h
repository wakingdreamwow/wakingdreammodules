// Test-only shim for AzerothCore's Log.h.
// AC's real logger uses fmt-style {} placeholders; the smoke test doesn't
// bother formatting — it just wants the code to compile and not crash. We
// swallow all variadic args and print a marker line.
#pragma once
#include <cstdio>

namespace wcpx_test { inline void _log_swallow(...) {} }

#define LOG_INFO(mod, ...)  do { std::printf("[INFO/%s] (msg suppressed)\n", mod); wcpx_test::_log_swallow(__VA_ARGS__); } while (0)
#define LOG_WARN(mod, ...)  do { std::printf("[WARN/%s] (msg suppressed)\n", mod); wcpx_test::_log_swallow(__VA_ARGS__); } while (0)
#define LOG_ERROR(mod, ...) do { std::fprintf(stderr, "[ERROR/%s] (msg suppressed)\n", mod); wcpx_test::_log_swallow(__VA_ARGS__); } while (0)
