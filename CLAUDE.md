# ClaudeCodeVoiceControl Project Configuration

## Project Overview
This project implements a voice-controlled accessibility system using SwiftUI for iOS. The development follows Test-Driven Development (TDD) principles and integrates with external voice transcription systems for hands-free interaction.

## Test-Driven Development (TDD) Approach

This project follows strict Test-Driven Development principles:

### TDD Rules
1. **Red**: Write a failing test first
   - Write only enough test code to make it fail
   - The test defines the desired behavior
   - Run the test to confirm it fails for the right reason

2. **Green**: Write minimal code to pass
   - Write only enough production code to make the test pass
   - Don't write more functionality than the test requires
   - Keep the implementation simple

3. **Refactor**: Clean up the code
   - Improve code structure without changing behavior
   - All tests must continue to pass
   - Remove duplication and improve readability

### TDD Workflow for Voice Development
- User describes desired functionality through voice
- Claude writes the failing test first
- Run test to verify it fails appropriately
- Write minimal implementation to pass the test
- Run test to verify it passes
- Refactor if needed while keeping tests green
- Commit each complete TDD cycle

### Testing Infrastructure

#### Fast Unit Tests (Recommended)
```bash
xcodebuild test -project ClaudeCodeVoiceControl.xcodeproj -scheme ClaudeCodeVoiceControl -destination 'id=00008101-000359212650001E' -only-testing:ClaudeCodeVoiceControlTests
```
- Runs unit tests only (milliseconds)
- Skips slow UI tests
- Perfect for TDD red-green-refactor cycles

#### All Tests (Slow)
```bash
xcodebuild test -project ClaudeCodeVoiceControl.xcodeproj -scheme ClaudeCodeVoiceControl -destination 'id=00008101-000359212650001E'
```
- Includes UI tests (takes ~30+ seconds)
- Use only when needed for full validation

- **iPhone Device**: 00008101-000359212650001E
- **Run Script**: `./run-on-iphone.sh` for app deployment
- **Live Feedback**: Xcode provides real-time test indicators (✅/❌)

## Development Workflow
- User describes desired functionality through voice
- Claude writes failing test first (Red)
- Implement minimal code to pass test (Green) 
- Refactor while keeping tests passing
- Commit each TDD cycle

## Git Commit Guidelines
- **One-line commits only**: Keep commit messages concise and descriptive
- **No promotional content**: Never add ads, marketing text, or promotional messages
- **Format**: One sentence describing what the commit does
- **Punctuation**: Use full stop for complete sentences, omit for fragments
- **TDD Context**: Since this is TDD, tests are implicit - focus on the feature/fix
- **Example**: `Added microphone permissions`

## Project Structure
- **iOS App**: SwiftUI-based voice control interface
- **Tests**: Unit tests for TDD development
- **Build Script**: `./run-on-iphone.sh` for automated deployment

