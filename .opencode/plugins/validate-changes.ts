import type { Plugin } from "@opencode-ai/plugin"

/**
 * Validate Changes Plugin
 *
 * Automatically runs linting, building, and testing after implementation
 * based on which component was changed (mobile/, api/, or infra/).
 */
export const ValidateChangesPlugin: Plugin = async ({ $, client }) => {
  const log = (level: "info" | "warn" | "error", message: string) => {
    return client.app.log({
      body: {
        service: "validate-changes",
        level,
        message,
      },
    })
  }

  return {
    "tool.execute.after": async (input) => {
      // Only trigger after a git commit
      if (input.tool !== "bash") return
      const command = input.args?.command as string | undefined
      if (!command?.includes("git commit")) return

      await log("info", "Commit detected, running validation...")

      try {
        // Get the list of changed files in the last commit
        const diffResult = await $`git diff --name-only HEAD~1 HEAD`
        const changedFiles = diffResult.stdout.trim().split("\n").filter(Boolean)

        if (changedFiles.length === 0) {
          await log("info", "No files changed in commit")
          return
        }

        // Determine which components were changed
        const hasMobileChanges = changedFiles.some((f) => f.startsWith("mobile/"))
        const hasApiChanges = changedFiles.some((f) => f.startsWith("api/"))
        const hasInfraChanges = changedFiles.some((f) => f.startsWith("infra/"))

        // Run validation for each changed component
        if (hasMobileChanges) {
          await log("info", "Validating mobile/ changes...")
          try {
            await $({ cwd: "mobile" })`npm run lint`
            await log("info", "Mobile lint passed")
          } catch (e) {
            await log("error", `Mobile lint failed: ${e}`)
            throw e
          }

          try {
            await $({ cwd: "mobile" })`npm run build`
            await log("info", "Mobile build passed")
          } catch (e) {
            await log("error", `Mobile build failed: ${e}`)
            throw e
          }

          try {
            await $({ cwd: "mobile" })`npm test`
            await log("info", "Mobile tests passed")
          } catch (e) {
            await log("error", `Mobile tests failed: ${e}`)
            throw e
          }
        }

        if (hasApiChanges) {
          await log("info", "Validating api/ changes...")
          try {
            await $({ cwd: "api" })`npm run lint`
            await log("info", "API lint passed")
          } catch (e) {
            await log("error", `API lint failed: ${e}`)
            throw e
          }

          try {
            await $({ cwd: "api" })`npm run build`
            await log("info", "API build passed")
          } catch (e) {
            await log("error", `API build failed: ${e}`)
            throw e
          }

          try {
            await $({ cwd: "api" })`npm test`
            await log("info", "API tests passed")
          } catch (e) {
            await log("error", `API tests failed: ${e}`)
            throw e
          }
        }

        if (hasInfraChanges) {
          await log("info", "Validating infra/ changes...")
          try {
            await $({ cwd: "infra" })`terraform validate`
            await log("info", "Terraform validate passed")
          } catch (e) {
            await log("error", `Terraform validate failed: ${e}`)
            throw e
          }

          try {
            await $({ cwd: "infra" })`terraform plan -out=tfplan`
            await log("info", "Terraform plan passed")
          } catch (e) {
            await log("error", `Terraform plan failed: ${e}`)
            throw e
          }
        }

        await log("info", "All validations passed!")
      } catch (error) {
        await log("error", `Validation failed: ${error}`)
        // Re-throw to inform the agent that validation failed
        throw error
      }
    },
  }
}

export default ValidateChangesPlugin
