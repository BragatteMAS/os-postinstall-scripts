# Quick Project Assessment

> 📝 Answer these questions to help AI assistants understand your project better.  
> ⏱️ Estimated time: 5 minutes

## 1. Project Overview

### What does this project do?
A simple REST API for managing a todo list. Users can create, read, update, and delete tasks through HTTP endpoints.

### Who uses it?
Developers learning Node.js and Express, or teams needing a simple task management API for their applications.

### What's the current status?
Beta - Core functionality is complete but needs more testing and documentation.

## 2. Technical Stack

### What's the main programming language?
JavaScript (Node.js)

### What frameworks/libraries are core to the project?
- Express.js for the web framework
- MongoDB with Mongoose for data storage
- Jest for testing
- Joi for validation

### What databases or data stores do you use?
MongoDB for persistent storage, with optional Redis for caching.

## 3. Architecture & Patterns

### How is the codebase organized?
MVC pattern with separate folders for models, controllers, and routes. Middleware for authentication and validation.

### What are the main components/modules?
- User authentication module
- Task CRUD operations
- Input validation middleware
- Error handling middleware
- Database connection manager

### Any important design patterns used?
- Repository pattern for data access
- Middleware pattern for request processing
- Factory pattern for creating test data

## 4. Development Workflow

### How do you run the project locally?
```bash
npm install
npm run dev
```

### How do you run tests?
```bash
npm test
```

### How do you deploy?
Docker container deployed to Heroku or AWS ECS.

## 5. Current Challenges

### What's the biggest technical challenge right now?
Implementing proper rate limiting and caching to handle increased traffic.

### What would you like to improve?
- Add comprehensive API documentation
- Improve test coverage (currently at 70%)
- Implement better error handling
- Add request/response logging

### Any known issues or limitations?
- No pagination on task lists yet
- Authentication tokens don't refresh
- Some edge cases in validation need fixing

## 6. AI Assistance

### How can AI best help you with this project?
- Writing tests for edge cases
- Implementing new features following existing patterns
- Reviewing code for security vulnerabilities
- Generating API documentation
- Optimizing database queries

### What should AI avoid doing?
- Modifying the authentication system without careful review
- Changing the database schema
- Altering environment variable names

### Any specific coding standards to follow?
- Use ES6+ features
- Async/await over callbacks
- camelCase for variables, PascalCase for classes
- JSDoc comments for all public functions
- 2 spaces for indentation