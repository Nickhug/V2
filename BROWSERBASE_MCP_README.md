# Browserbase MCP Integration for Cursor

This document explains how to use the Browserbase MCP integration with Cursor to enable browser automation capabilities.

## Setup Steps

1. **Browserbase Account Setup**:
   - Sign up for a Browserbase account at [browserbase.com](https://www.browserbase.com)
   - Get your API key and Project ID from the Overview Dashboard
   - These credentials are required for authentication

2. **Configuration**:
   - The Browserbase MCP server is already built and configured in your Cursor setup
   - Located at: `/Users/nick/Downloads/browserbase/mcp-server-browserbase/browserbase/dist/index.js`
   - Update `/Users/nick/.cursor/mcp.json` with your actual API key and Project ID

3. **Using Browserbase**:
   - Restart Cursor to load the updated MCP configuration
   - The Browserbase tools will be available in Claude's toolset

## Available Tools

- **browserbase_create_session**: Create a new cloud browser session
- **browserbase_navigate**: Navigate to any URL in the browser
- **browserbase_screenshot**: Capture screenshots of pages or elements
- **browserbase_click**: Click elements on the page
- **browserbase_fill**: Fill out input fields
- **browserbase_evaluate**: Execute JavaScript in the browser console
- **browserbase_get_content**: Extract content from the page
- **browserbase_parallel_sessions**: Create multiple browser sessions

## Example Workflow

1. Create a browser session: `browserbase_create_session`
2. Navigate to a website: `browserbase_navigate` with URL
3. Take a screenshot: `browserbase_screenshot`
4. Extract content: `browserbase_get_content`
5. Interact with elements: `browserbase_click` or `browserbase_fill`
6. Execute custom JavaScript: `browserbase_evaluate`

## Resources

- [Browserbase Documentation](https://docs.browserbase.com/)
- [MCP GitHub Repository](https://github.com/browserbase/mcp-server-browserbase) 