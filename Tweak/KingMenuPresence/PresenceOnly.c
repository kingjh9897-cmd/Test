// Diagnostic framework: intentionally no constructor, no UI, no hooks.
// It exists only to test whether the mere presence/loading of an extra framework
// triggers the app's integrity/security checks.

__attribute__((visibility("default")))
int KingMenuPresenceMarker(void) {
    return 1;
}
