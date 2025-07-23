# Code Conventions & Standards

## Naming Conventions
- **Variables**: [style - e.g., camelCase, snake_case]
- **Functions**: [style]
- **Classes**: [style]
- **Files**: [style]
- **Constants**: [style - e.g., UPPER_SNAKE_CASE]

### Examples
```javascript
// Variables
const userName = 'John';
const isActive = true;

// Functions
function calculateTotal(items) { }
const handleClick = () => { };

// Classes
class UserService { }

// Constants
const MAX_RETRY_COUNT = 3;
```

## Code Style
### JavaScript/TypeScript
- Indentation: 2 spaces
- Line length: 80 characters
- Semicolons: [yes/no]
- Quotes: [single/double]

### Python
- Follow PEP 8
- Indentation: 4 spaces
- Line length: 79 characters
- Type hints: Required for public APIs

### [Other Languages]
- [Rules]

## File Organization
```
src/
├── components/     # UI components
├── services/       # Business logic
├── utils/          # Utility functions
├── types/          # Type definitions
└── tests/          # Test files
```

## Git Conventions
### Branch Naming
- Feature: `feature/description`
- Bugfix: `bugfix/description`
- Hotfix: `hotfix/description`
- Release: `release/version`

### Commit Messages
```
type(scope): subject

body

footer
```

Types: feat, fix, docs, style, refactor, test, chore

Examples:
- `feat(auth): add JWT authentication`
- `fix(api): handle null response correctly`
- `docs(readme): update installation steps`

## Testing Standards
- Minimum coverage: [X%]
- Test naming: `should_expectedBehavior_when_condition`
- Test structure: Arrange-Act-Assert (AAA)

### Example Test
```javascript
describe('UserService', () => {
  it('should return user data when valid ID provided', async () => {
    // Arrange
    const userId = '123';
    
    // Act
    const user = await userService.getUser(userId);
    
    // Assert
    expect(user).toBeDefined();
    expect(user.id).toBe(userId);
  });
});
```

## Documentation Standards
### Code Comments
- Use JSDoc for functions
- Explain "why", not "what"
- Keep comments up to date

### README Updates
- Update when adding features
- Include examples
- Keep installation steps current

### API Documentation
- Document all endpoints
- Include request/response examples
- Note authentication requirements

## Error Handling
- Always handle errors explicitly
- Use custom error classes
- Log errors with context
- Return user-friendly messages

### Example
```javascript
try {
  const result = await riskyOperation();
  return result;
} catch (error) {
  logger.error('Operation failed', { error, context });
  throw new CustomError('User-friendly message', error);
}
```

## Review Checklist
- [ ] Follows naming conventions
- [ ] Includes appropriate tests
- [ ] Updates documentation
- [ ] Handles errors properly
- [ ] No security vulnerabilities
- [ ] Performance considered
- [ ] Code is readable
- [ ] No unnecessary complexity