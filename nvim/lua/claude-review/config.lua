local C = {}

C.model = nil -- e.g. "claude-sonnet-4-5-20250929"

C.default = [[
Focus on: bugs, logic errors, missing error handling, type issues, security concerns, race conditions, resource leaks.
Do NOT report style issues, naming conventions, or missing comments.
]]

C.projects = {
  ["mine-eiendommer-api"] = [[
## Go Conventions
- Use table-driven tests with `tt` as the loop variable
- Use `testify/assert` for assertions
- Use `t.Run(tt.name, ...)` for subtests
- Always check `err` returns — flag unchecked errors as BUG
- Use `context.Context` as first parameter in functions that do I/O
- Flag goroutines without cancellation or timeout as CONCERN

## Logging
 - Prefer logging using >>, like this:logrus.Errorf("Failed to xxx>> %v", err), or return res, fmt.Errorf("waterinsight GET /getHourlyConsumption failed >> %w", err)
 - All routes must log warnings using logrus: logrus.Warnf("Failed to xxx>> %v", err)


## Codebase Consistency
- Review changes against existing patterns in the repo (naming, error handling, structure)
- Flag deviations from established conventions in neighboring files as SUGGESTION
- If a new pattern is introduced, flag it as CONCERN unless it clearly improves on the existing approach
- Check that new types, interfaces, and function signatures align with the style used elsewhere in the package
- Flag inconsistent use of logging, response formatting, or middleware patterns compared to existing handlers

## Gin Framework
- Handlers must call `c.JSON()` or `c.AbortWithStatusJSON()` — flag missing responses as BUG
- Middleware should call `c.Next()` or `c.Abort()` — flag missing control flow as BUG
- Flag `c.Bind()` without error handling as BUG (use `ShouldBind*` variants)

## SQL / Database
- Flag SQL string concatenation as BUG (use parameterized queries)
- Flag missing `rows.Close()` after `db.Query()` as BUG (resource leak)
- Flag missing `tx.Rollback()` in error paths of transactions as BUG
- Flag `SELECT *` as SUGGESTION (prefer explicit columns)

## Error Handling
- Flag `_ = someFunc()` that returns error as CONCERN
- Flag naked returns in functions with named return values + error as CONCERN
- Flag `log.Fatal` in non-main packages as CONCERN (use error returns)
]],
}

return C
