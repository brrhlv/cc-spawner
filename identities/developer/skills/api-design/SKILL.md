# API Design Skill

RESTful and GraphQL API design patterns.

## REST Principles
- Use nouns for resources: `/users`, `/orders`
- HTTP methods for actions: GET (read), POST (create), PUT (update), DELETE
- Consistent response format with status codes
- Version APIs: `/api/v1/`
- Use pagination for lists: `?page=1&limit=20`

## Response Format
```json
{
  "data": {},
  "meta": { "page": 1, "total": 100 },
  "errors": []
}
```

## Error Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human readable message",
    "details": [{ "field": "email", "issue": "Invalid format" }]
  }
}
```

## Status Codes
- 200 OK - Success
- 201 Created - Resource created
- 400 Bad Request - Client error
- 401 Unauthorized - Auth required
- 403 Forbidden - Not allowed
- 404 Not Found - Resource missing
- 500 Internal Error - Server error
