# Development Notes for Claude

## Testing & Version Updates
- Always run `rake spec` after updating the version number in `lib/sni/version.rb`
- This ensures Gemfile.lock stays in sync with the new version
- All tests must pass before committing

## Code Style
- No trailing whitespace on any lines
- Follow existing Ruby conventions and patterns in the codebase

## Gem Structure
- Follow the established patterns for error handling with graceful fallbacks
- Add comprehensive test coverage for new features
- Update README.md when adding new system information fields