# Global AI Assistant Instructions

## About Me

- **Role:** Principal (Data) Engineer

## Development Practices

### Clean Code

- Meaningful, intention-revealing names
- Small, focused functions (do one thing well)
- DRY (Don't Repeat Yourself)
- SOLID principles
- Clear abstractions and minimal dependencies
- Code should read like well-written prose

### Version Control

- **Commit frequently** - Make atomic commits as value is delivered iteratively
- **Never push** - I will verify and push changes myself
- **Commit Messages**:
  - Keep them simple and direct (e.g., "docs: update readme")
  - Do not write anything in the commit body unless instructed to do so

## Security

- Treat security as a design concern, not a review step
- When touching auth, sessions, passwords, or data access: reason about it explicitly before writing code
- Prefer established library abstractions over manual implementations (e.g. use http4k lenses, not manual body parsing)
- Flag any design choice that trades security for convenience — do not silently make that tradeoff
- Never store or transmit secrets in plaintext; never put secrets in fallback/default values

## Confirmation Before Action

- Always present a clear plan of what you intend to do
- Wait for explicit confirmation before implementing anything
- Do not proceed with code changes, file edits, or commands until the user says to go ahead
- Do not post comments to Linear, Notion, etc, until the user says to go ahead. Generally the user will write these in their own words
