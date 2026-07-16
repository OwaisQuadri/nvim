/* zcc: a single-token C compiler shim for tree-sitter on Windows.
 * Invokes `zig cc`, rewriting tree-sitter's host triple
 * (x86_64-pc-windows-msvc) to a gnu triple so zig uses its own bundled
 * mingw libc/headers -- no Visual Studio / Windows SDK required. */
#include <stdlib.h>
#include <string.h>
#include <process.h>

static char *rewrite(const char *a) {
    const char *msvc = "x86_64-pc-windows-msvc";
    const char *gnu  = "x86_64-windows-gnu";
    const char *p = strstr(a, msvc);
    if (!p) return (char *)a;
    size_t pre = (size_t)(p - a);
    size_t out = pre + strlen(gnu) + strlen(p + strlen(msvc)) + 1;
    char *r = (char *)malloc(out);
    memcpy(r, a, pre);
    strcpy(r + pre, gnu);
    strcat(r + pre, p + strlen(msvc));
    return r;
}

int main(int argc, char **argv) {
    const char **nv = (const char **)malloc(sizeof(char *) * (argc + 3));
    int n = 0;
    nv[n++] = "zig";
    nv[n++] = "cc";
    for (int i = 1; i < argc; i++) nv[n++] = rewrite(argv[i]);
    nv[n] = NULL;
    return (int)_spawnvp(_P_WAIT, "zig", nv);
}
