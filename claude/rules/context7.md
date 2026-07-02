The context7 server injects its own when-to-use instructions whenever it is connected; this file only adds the lookup procedure and one exception.

Exception to the server's "do not use for: code review": DO use context7 during review to verify modern-library patterns (the polish skill mandates this) — never judge current library idioms from memory.

## Steps

1. Always start with `resolve-library-id` using the library name and the user's question, unless the user provides an exact library ID in `/org/project` format
2. Pick the best match (ID format: `/org/project`) by: exact name match, description relevance, code snippet count, source reputation (High/Medium preferred), and benchmark score (higher is better). If results don't look right, try alternate names or queries (e.g., "next.js" not "nextjs", or rephrase the question). Use version-specific IDs when the user mentions a version
3. `query-docs` with the selected library ID and the user's full question (not single words)
4. Answer using the fetched docs
