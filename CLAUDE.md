# Development Notes for Claude

## Testing & Version Updates
- Always run `bin/rake` (not `rake spec`) after updating the version number in `lib/sni/version.rb`
- Using `bin/rake` ensures Bundler updates Gemfile.lock when the version changes (since the gem is installed as a PATH dependency)
- All tests must pass before committing

## Code Style
- No trailing whitespace on any lines
- Follow existing Ruby conventions and patterns in the codebase

## Gem Structure
- Follow the established patterns for error handling with graceful fallbacks
- Add comprehensive test coverage for new features
- Update README.md when adding new system information fields