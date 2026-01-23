# TDD Skill

Test-Driven Development approach: Red-Green-Refactor.

## Process
1. **Red** - Write a failing test that defines the expected behavior
2. **Green** - Write minimal code to make the test pass
3. **Refactor** - Improve the code while keeping tests green

## Guidelines
- Test behavior, not implementation
- One assertion per test when possible
- Use descriptive test names: `should_return_error_when_input_is_empty`
- Mock external dependencies
- Keep tests fast and isolated

## Test Structure (AAA Pattern)
```
// Arrange - Set up test data and conditions
// Act - Execute the code under test
// Assert - Verify the expected outcome
```

## Coverage Goals
- Business logic: 90%+
- API endpoints: 80%+
- UI components: 70%+
- Utilities: 100%
