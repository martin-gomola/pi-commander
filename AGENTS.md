# Pi-Commander

Docker Compose core infrastructure: reverse proxy, DNS, VPN, and DDNS.

Use `make` from the repo root. Service configs live in `docker/<service>/`. Validate YAML with `make test-syntax`.

## Code knowledge graph

This project has a knowledge graph. Use the code-review-graph MCP tools before Grep/Glob/Read when exploring code. The graph is faster and gives structural context (callers, dependents, test coverage) that file scanning cannot.

Use graph tools first for:

- Exploring code: `semantic_search_nodes` or `query_graph`
- Understanding impact: `get_impact_radius`
- Code review: `detect_changes` + `get_review_context`
- Finding relationships: `query_graph` with callers_of/callees_of/imports_of/tests_for
- Architecture questions: `get_architecture_overview` + `list_communities`

Fall back to Grep/Glob/Read only when the graph does not cover what you need.

The graph auto-updates on file changes. Use `detect_changes` for review, `get_affected_flows` for impact, and `query_graph` with pattern `tests_for` to check coverage.
