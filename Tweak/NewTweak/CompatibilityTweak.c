#include <stdint.h>

// Export the exact symbol name expected from the working libloader.
// Returning zero is safe for common pointer/integer/bool return conventions;
// callers that treat it as void simply ignore the return value.
__attribute__((visibility("default")))
uintptr_t KingCompatibilityEntry(void) __asm__("iBWuJnPubwtWJIGVxT");

uintptr_t KingCompatibilityEntry(void) {
    return (uintptr_t)0;
}
