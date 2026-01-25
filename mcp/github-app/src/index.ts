#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { Octokit } from "@octokit/rest";
import { createAppAuth } from "@octokit/auth-app";
import * as fs from "fs";

// Environment variables
const GITHUB_APP_ID = process.env.GITHUB_APP_ID;
const GITHUB_APP_PRIVATE_KEY_PATH = process.env.GITHUB_APP_PRIVATE_KEY_PATH;
const GITHUB_APP_PRIVATE_KEY = process.env.GITHUB_APP_PRIVATE_KEY;
const GITHUB_APP_INSTALLATION_ID = process.env.GITHUB_APP_INSTALLATION_ID;

// Validate required environment variables
if (!GITHUB_APP_ID) {
  console.error("Error: GITHUB_APP_ID environment variable is required");
  process.exit(1);
}

if (!GITHUB_APP_INSTALLATION_ID) {
  console.error("Error: GITHUB_APP_INSTALLATION_ID environment variable is required");
  process.exit(1);
}

// Get private key from file or environment
let privateKey: string;
if (GITHUB_APP_PRIVATE_KEY) {
  privateKey = GITHUB_APP_PRIVATE_KEY;
} else if (GITHUB_APP_PRIVATE_KEY_PATH) {
  try {
    privateKey = fs.readFileSync(GITHUB_APP_PRIVATE_KEY_PATH, "utf-8");
  } catch (error) {
    console.error(`Error reading private key from ${GITHUB_APP_PRIVATE_KEY_PATH}:`, error);
    process.exit(1);
  }
} else {
  console.error("Error: Either GITHUB_APP_PRIVATE_KEY or GITHUB_APP_PRIVATE_KEY_PATH must be set");
  process.exit(1);
}

// Create authenticated Octokit instance
const octokit = new Octokit({
  authStrategy: createAppAuth,
  auth: {
    appId: GITHUB_APP_ID,
    privateKey: privateKey,
    installationId: Number(GITHUB_APP_INSTALLATION_ID),
  },
});

// Create MCP server
const server = new Server(
  {
    name: "github-app-mcp",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define available tools
const tools = [
  {
    name: "create_pull_request",
    description: "Create a new pull request in a repository",
    inputSchema: {
      type: "object" as const,
      properties: {
        owner: { type: "string", description: "Repository owner (user or organization)" },
        repo: { type: "string", description: "Repository name" },
        title: { type: "string", description: "Pull request title" },
        body: { type: "string", description: "Pull request description" },
        head: { type: "string", description: "Branch containing the changes" },
        base: { type: "string", description: "Branch to merge into (e.g., main)" },
        draft: { type: "boolean", description: "Create as draft PR", default: false },
      },
      required: ["owner", "repo", "title", "head", "base"],
    },
  },
  {
    name: "get_pull_request",
    description: "Get details of a specific pull request",
    inputSchema: {
      type: "object" as const,
      properties: {
        owner: { type: "string", description: "Repository owner" },
        repo: { type: "string", description: "Repository name" },
        pull_number: { type: "number", description: "Pull request number" },
      },
      required: ["owner", "repo", "pull_number"],
    },
  },
  {
    name: "list_pull_requests",
    description: "List pull requests in a repository",
    inputSchema: {
      type: "object" as const,
      properties: {
        owner: { type: "string", description: "Repository owner" },
        repo: { type: "string", description: "Repository name" },
        state: { type: "string", enum: ["open", "closed", "all"], default: "open" },
        head: { type: "string", description: "Filter by head branch (format: user:branch)" },
        base: { type: "string", description: "Filter by base branch" },
      },
      required: ["owner", "repo"],
    },
  },
  {
    name: "search_pull_requests",
    description: "Search for pull requests across repositories",
    inputSchema: {
      type: "object" as const,
      properties: {
        query: { type: "string", description: "Search query (GitHub search syntax)" },
      },
      required: ["query"],
    },
  },
  {
    name: "list_pr_comments",
    description: "List review comments on a pull request",
    inputSchema: {
      type: "object" as const,
      properties: {
        owner: { type: "string", description: "Repository owner" },
        repo: { type: "string", description: "Repository name" },
        pull_number: { type: "number", description: "Pull request number" },
      },
      required: ["owner", "repo", "pull_number"],
    },
  },
  {
    name: "create_pr_comment",
    description: "Create a comment on a pull request",
    inputSchema: {
      type: "object" as const,
      properties: {
        owner: { type: "string", description: "Repository owner" },
        repo: { type: "string", description: "Repository name" },
        pull_number: { type: "number", description: "Pull request number" },
        body: { type: "string", description: "Comment body" },
      },
      required: ["owner", "repo", "pull_number", "body"],
    },
  },
  {
    name: "create_issue",
    description: "Create a new issue in a repository",
    inputSchema: {
      type: "object" as const,
      properties: {
        owner: { type: "string", description: "Repository owner" },
        repo: { type: "string", description: "Repository name" },
        title: { type: "string", description: "Issue title" },
        body: { type: "string", description: "Issue body" },
        labels: { type: "array", items: { type: "string" }, description: "Labels to add" },
        assignees: { type: "array", items: { type: "string" }, description: "Users to assign" },
      },
      required: ["owner", "repo", "title"],
    },
  },
  {
    name: "get_issue",
    description: "Get details of a specific issue",
    inputSchema: {
      type: "object" as const,
      properties: {
        owner: { type: "string", description: "Repository owner" },
        repo: { type: "string", description: "Repository name" },
        issue_number: { type: "number", description: "Issue number" },
      },
      required: ["owner", "repo", "issue_number"],
    },
  },
  {
    name: "create_issue_comment",
    description: "Create a comment on an issue or pull request",
    inputSchema: {
      type: "object" as const,
      properties: {
        owner: { type: "string", description: "Repository owner" },
        repo: { type: "string", description: "Repository name" },
        issue_number: { type: "number", description: "Issue or PR number" },
        body: { type: "string", description: "Comment body" },
      },
      required: ["owner", "repo", "issue_number", "body"],
    },
  },
  {
    name: "get_repository",
    description: "Get repository information",
    inputSchema: {
      type: "object" as const,
      properties: {
        owner: { type: "string", description: "Repository owner" },
        repo: { type: "string", description: "Repository name" },
      },
      required: ["owner", "repo"],
    },
  },
  {
    name: "list_branches",
    description: "List branches in a repository",
    inputSchema: {
      type: "object" as const,
      properties: {
        owner: { type: "string", description: "Repository owner" },
        repo: { type: "string", description: "Repository name" },
      },
      required: ["owner", "repo"],
    },
  },
  {
    name: "get_file_contents",
    description: "Get contents of a file from a repository",
    inputSchema: {
      type: "object" as const,
      properties: {
        owner: { type: "string", description: "Repository owner" },
        repo: { type: "string", description: "Repository name" },
        path: { type: "string", description: "Path to the file" },
        ref: { type: "string", description: "Branch, tag, or commit SHA" },
      },
      required: ["owner", "repo", "path"],
    },
  },
];

// Register tools handler
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "create_pull_request": {
        const { owner, repo, title, body, head, base, draft } = args as any;
        const response = await octokit.pulls.create({
          owner,
          repo,
          title,
          body: body || "",
          head,
          base,
          draft: draft || false,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                {
                  number: response.data.number,
                  url: response.data.html_url,
                  state: response.data.state,
                  title: response.data.title,
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case "get_pull_request": {
        const { owner, repo, pull_number } = args as any;
        const response = await octokit.pulls.get({
          owner,
          repo,
          pull_number,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                {
                  number: response.data.number,
                  url: response.data.html_url,
                  state: response.data.state,
                  title: response.data.title,
                  body: response.data.body,
                  head: response.data.head.ref,
                  base: response.data.base.ref,
                  mergeable: response.data.mergeable,
                  draft: response.data.draft,
                  user: response.data.user?.login,
                  created_at: response.data.created_at,
                  updated_at: response.data.updated_at,
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case "list_pull_requests": {
        const { owner, repo, state, head, base } = args as any;
        const response = await octokit.pulls.list({
          owner,
          repo,
          state: state || "open",
          head,
          base,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                response.data.map((pr) => ({
                  number: pr.number,
                  title: pr.title,
                  state: pr.state,
                  url: pr.html_url,
                  head: pr.head.ref,
                  base: pr.base.ref,
                  user: pr.user?.login,
                  draft: pr.draft,
                })),
                null,
                2
              ),
            },
          ],
        };
      }

      case "search_pull_requests": {
        const { query } = args as any;
        const response = await octokit.search.issuesAndPullRequests({
          q: `${query} is:pr`,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                response.data.items.map((item) => ({
                  number: item.number,
                  title: item.title,
                  state: item.state,
                  url: item.html_url,
                  repository: item.repository_url.split("/").slice(-2).join("/"),
                  user: item.user?.login,
                })),
                null,
                2
              ),
            },
          ],
        };
      }

      case "list_pr_comments": {
        const { owner, repo, pull_number } = args as any;
        // Get both review comments and issue comments
        const [reviewComments, issueComments] = await Promise.all([
          octokit.pulls.listReviewComments({ owner, repo, pull_number }),
          octokit.issues.listComments({ owner, repo, issue_number: pull_number }),
        ]);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                {
                  review_comments: reviewComments.data.map((c) => ({
                    id: c.id,
                    body: c.body,
                    user: c.user?.login,
                    path: c.path,
                    line: c.line,
                    created_at: c.created_at,
                  })),
                  issue_comments: issueComments.data.map((c) => ({
                    id: c.id,
                    body: c.body,
                    user: c.user?.login,
                    created_at: c.created_at,
                  })),
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case "create_pr_comment": {
        const { owner, repo, pull_number, body } = args as any;
        const response = await octokit.issues.createComment({
          owner,
          repo,
          issue_number: pull_number,
          body,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                {
                  id: response.data.id,
                  url: response.data.html_url,
                  body: response.data.body,
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case "create_issue": {
        const { owner, repo, title, body, labels, assignees } = args as any;
        const response = await octokit.issues.create({
          owner,
          repo,
          title,
          body,
          labels,
          assignees,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                {
                  number: response.data.number,
                  url: response.data.html_url,
                  title: response.data.title,
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case "get_issue": {
        const { owner, repo, issue_number } = args as any;
        const response = await octokit.issues.get({
          owner,
          repo,
          issue_number,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                {
                  number: response.data.number,
                  url: response.data.html_url,
                  state: response.data.state,
                  title: response.data.title,
                  body: response.data.body,
                  user: response.data.user?.login,
                  labels: response.data.labels.map((l) =>
                    typeof l === "string" ? l : l.name
                  ),
                  assignees: response.data.assignees?.map((a) => a.login),
                  created_at: response.data.created_at,
                  updated_at: response.data.updated_at,
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case "create_issue_comment": {
        const { owner, repo, issue_number, body } = args as any;
        const response = await octokit.issues.createComment({
          owner,
          repo,
          issue_number,
          body,
        });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                {
                  id: response.data.id,
                  url: response.data.html_url,
                  body: response.data.body,
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case "get_repository": {
        const { owner, repo } = args as any;
        const response = await octokit.repos.get({ owner, repo });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                {
                  name: response.data.name,
                  full_name: response.data.full_name,
                  description: response.data.description,
                  url: response.data.html_url,
                  default_branch: response.data.default_branch,
                  private: response.data.private,
                  language: response.data.language,
                  stargazers_count: response.data.stargazers_count,
                  forks_count: response.data.forks_count,
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case "list_branches": {
        const { owner, repo } = args as any;
        const response = await octokit.repos.listBranches({ owner, repo });
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(
                response.data.map((b) => ({
                  name: b.name,
                  protected: b.protected,
                })),
                null,
                2
              ),
            },
          ],
        };
      }

      case "get_file_contents": {
        const { owner, repo, path, ref } = args as any;
        const response = await octokit.repos.getContent({
          owner,
          repo,
          path,
          ref,
        });
        
        if (Array.isArray(response.data)) {
          // Directory listing
          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(
                  response.data.map((item) => ({
                    name: item.name,
                    path: item.path,
                    type: item.type,
                  })),
                  null,
                  2
                ),
              },
            ],
          };
        } else if (response.data.type === "file" && "content" in response.data) {
          // File content
          const content = Buffer.from(response.data.content, "base64").toString("utf-8");
          return {
            content: [
              {
                type: "text",
                text: content,
              },
            ],
          };
        } else {
          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(response.data, null, 2),
              },
            ],
          };
        }
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error: any) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("GitHub App MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
