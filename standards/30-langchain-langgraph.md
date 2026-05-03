# LangChain & LangGraph

Reads on top of [`20-python.md`](20-python.md) (or [`10-javascript-node.md`](10-javascript-node.md) if using LangChain JS). LLM applications have failure modes that ordinary code doesn't — these rules exist because of them.

## Models

- **Pin model IDs explicitly.** `claude-sonnet-4-6`, `gpt-4o-2024-08-06`. Never floating tags like `gpt-4` or `latest` — behavior changes silently and breaks evals.
- Model IDs come from `config`, not hardcoded throughout the code. One place to upgrade.
- Default to the smallest model that meets the eval bar. Escalate per-task only when needed.
- Document the model choice and date in the project README — model selection is an architectural decision.

## Prompts

- **Prompts live in separate files**, not inlined as multi-line strings.
  - `prompts/<task_name>.md` for human-readable prompts
  - Loaded via a small loader; tracked under version control
- Treat prompt changes like code changes — review them, write evals against them.
- No secrets, internal URLs, customer data, or PII in prompt text.
- Use a templating system (LangChain `ChatPromptTemplate`, Jinja, or similar). Don't `f"..."`-format user input into prompts — that's the LLM equivalent of SQL injection.
- Keep system prompts short and specific. Long preambles waste tokens and confuse the model.

## Calls

- **Always set a timeout.** `client.with_options(timeout=30)`. A hung call blocks an entire request.
- **Always set retries** with exponential backoff for transient failures. Cap at 3 attempts unless you have a reason.
- **Log token usage** per call: input tokens, output tokens, model, latency. Aggregate to a cost dashboard.
- **Stream** for any user-facing UX. Non-streaming only for backend jobs.
- **Structured output** via `with_structured_output` / function calling / JSON mode — never regex parsing of natural-language responses.

## Tracing & evaluation

- **LangSmith tracing on** in staging and production. Off in unit tests (use `LANGCHAIN_TRACING_V2=false`).
- Every project has at least a smoke-test eval set (10–50 examples) checked into the repo.
- Evals run in CI on prompt or model changes. A regression is a blocker, not a discussion.
- Trace IDs surface to user-facing error messages so they can be looked up.

## Caching

- Use `SQLiteCache` for dev, `RedisCache` (or your platform's equivalent) for prod where calls are deterministic.
- Cache by (model, prompt, params) tuple. Don't cache across users when output depends on user-specific context.

## Tools (function calling)

- Tool input schemas are Pydantic models, not free-form dicts.
- Validate tool inputs before executing. The LLM hallucinates arguments.
- Tool execution is sandboxed where possible — no shell exec, no SQL string concat, no unbounded HTTP.
- Tool errors return a structured message to the LLM, not a stack trace, so it can recover.
- Idempotent tools where possible — the LLM may call them twice.

## LangGraph

- Name every node and edge. Anonymous lambdas in graphs are unreviewable.
- Use **typed state** (`TypedDict` or Pydantic) for the graph state — not free dicts.
- Use **checkpointers** for any agent that runs longer than a single request (PostgresSaver, RedisSaver). Without them, recovery from failure is impossible.
- Cap iterations on cyclic graphs (`recursion_limit`) — the model can loop forever otherwise.
- Conditional edges return a constant string from a small enum, not a computed value, so the graph is statically inspectable.

## Memory & retention

- Be explicit about retention. Document: what is stored, where, for how long, how it's deleted.
- Don't store raw user messages in long-term memory by default — extract structured facts.
- Embeddings of user content are user data and inherit the same retention rules.
- For RAG: index sources are versioned. When source documents change, re-embed; never silently mix versions.

## Cost & rate limiting

- Per-user rate limits on LLM-backed endpoints. A runaway client should not exhaust the org's API quota.
- Per-request token budgets. Truncate context at a sane limit; refuse rather than silently dropping the system prompt.
- Cost monitoring: dashboards for $/day and $/user. Alert on anomalies.

## Don't do

- Use deprecated `LLMChain` / `RetrievalQA` etc. — use LCEL (`prompt | model | parser`) or LangGraph
- Pipe user input straight into a prompt without escaping/templating
- Trust LLM output as ground truth without validation (especially for tool args, code generation, SQL)
- Hide LLM errors and silently return empty responses — surface them
- Bake your API keys into the prompt or expose them via `model.dict()` in logs
- Run agents without an iteration cap
- Ship without an eval set
