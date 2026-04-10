# Global AI Assistant Instructions

## About Me

- **Role:** Principal (Data) Engineer

## Development Practices

### Test-Driven Development (TDD)

Always follow the Red-Green-Refactor cycle:
1. **Red** - Write a failing test first
2. **Green** - Write minimal code to make the test pass
3. **Refactor** - Clean up the code while keeping tests green

Never skip writing tests. Tests come before implementation.

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
  - Use conventional commit messages
  - Keep them simple and direct (e.g., "docs: update readme")
  - Do NOT list every file change or detailed action steps

## Security

- Treat security as a design concern, not a review step
- When touching auth, sessions, passwords, or data access: reason about it explicitly before writing code
- Prefer established library abstractions over manual implementations (e.g. use http4k lenses, not manual body parsing)
- Flag any design choice that trades security for convenience — do not silently make that tradeoff
- Never store or transmit secrets in plaintext; never put secrets in fallback/default values

## Workflow

1. Write a failing test
2. Implement minimal code to pass
3. Refactor if needed
4. Commit the working increment
5. Repeat

## Confirmation Before Action

- Always present a clear plan of what you intend to do
- Wait for explicit confirmation before implementing anything
- Do not proceed with code changes, file edits, or commands until the user says to go ahead

