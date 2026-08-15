# Repository Instructions for Agents

## Documentation Language

- Write every agent-facing Markdown file in English.
- This includes specifications, implementation plans, task reports, review notes, and operational instructions.
- Treat files under docs/superpowers as agent-facing canonical documents.
- Store Korean user-review briefing documents under docs/briefings/ko.
- A Korean briefing is never the implementation source of truth. It must link to or name its English canonical document.
- Give all progress updates, review summaries, decisions, and final handoffs to the user in Korean.

## Prototype Branch Boundary

- Use Prototyping as the integration base for prototype implementation.
- Use Development only for later full production.
- Never merge Prototyping wholesale into Development.
- Carry validated findings into English production specifications and port only explicitly reviewed reusable units.
