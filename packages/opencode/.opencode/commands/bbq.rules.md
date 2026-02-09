---
description: Set up project house rules — the foundational principles for development
---

# Establish the House Rules

Create or update the project's House Rules document that defines core principles and standards.

## Instructions

### 1. Check for Existing House Rules

Check if `.opencode/HOUSE_RULES.md` already exists:
- If it exists, read it and offer to update/extend it
- If not, copy the template from `.opencode/templates/HOUSE_RULES.md`

### 2. Gather Project Context

If this is a new House Rules document, ask the user:

> What is the name of this project?

Use the answer to replace `[PROJECT_NAME]` in the header.

### 3. Gather Core Principles

Ask the user iteratively about their project's principles. For each principle, ask:

> What is a core principle or rule for this project?
> (Examples: "Test-first development", "All APIs must be versioned", "No direct database access from controllers")
>
> Type "done" when you have no more principles to add.

For each principle provided:
1. Ask for a short name (e.g., "Test-First", "API Versioning")
2. Ask for the description/details
3. Add it to the document

Continue prompting until the user says "done" or indicates they're finished.

### 4. Gather Additional Sections

Ask the user if they have additional standards to document:

> Do you have any of these to add?
> - Technology constraints (required stack, forbidden dependencies)
> - Security requirements
> - Performance standards
> - Code review requirements
> - Deployment policies
>
> Type "done" if you have nothing to add, or describe what you'd like to include.

Continue gathering until the user is done.

### 5. Set Governance Rules

Ask the user:

> How should these rules be enforced? For example:
> - All PRs must comply
> - Exceptions require team approval
> - Amendments require documentation
>
> Or press enter to use the default: "All PRs/reviews must verify compliance. Amendments require documentation and team approval."

### 6. Finalize the Document

1. Replace all placeholder sections with the gathered content
2. Remove any unused `[PLACEHOLDER]` sections
3. Remove the HTML comments (examples)
4. Set the version to `1.0.0`
5. Set the ratification date to today
6. Write the final document to `.opencode/HOUSE_RULES.md`

### 7. Confirm

Tell the user:

```
House Rules established at .opencode/HOUSE_RULES.md

Principles documented:
- [Principle 1 name]
- [Principle 2 name]
- ...

These rules will guide all development in this project.

All `/bbq.*` commands will load and apply these rules when this file is present.
```
