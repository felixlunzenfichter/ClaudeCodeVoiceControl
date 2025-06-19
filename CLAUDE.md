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

Claude should ALWAYS explicitly state which TDD phase we are in:

#### 🔴 RED Phase - Test Writing
- User describes desired functionality through voice
- Claude writes the failing test first
- Run test to verify it fails appropriately
- State: "We are in the RED phase - writing a failing test"

#### 🟢 GREEN Phase - Implementation
- Write minimal implementation to pass the test
- Only write enough code to make the test pass
- No extra features or functionality
- Run test to verify it passes
- State: "We are in the GREEN phase - making the test pass"

#### 🔵 REFACTOR Phase - Cleanup
- Remove ALL comments from production code
- Remove any unused methods or code
- Keep only what is tested and necessary
- Tests must continue to pass
- State: "We are in the REFACTOR phase - cleaning up the code"

### Testing Infrastructure

#### Fast Unit Tests (Default)
```bash
xcodebuild test -project ClaudeCodeVoiceControl.xcodeproj -scheme ClaudeCodeVoiceControl -destination 'id=00008101-000359212650001E' -only-testing:ClaudeCodeVoiceControlTests/ClaudeCodeVoiceControlTests
```
- Use for most TDD cycles

#### Slow Integration Tests
```bash
xcodebuild test -project ClaudeCodeVoiceControl.xcodeproj -scheme ClaudeCodeVoiceControl -destination 'id=00008101-000359212650001E' -only-testing:ClaudeCodeVoiceControlTests/SlowIntegrationTests
```
- Use when validating integration features

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

