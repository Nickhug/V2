#!/bin/bash

# Install the Postgres MCP server package
npm install -g @modelcontextprotocol/server-postgres

# Display installation success message
echo "✅ MCP Postgres server installed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit .cursor/mcp.json to add your Supabase connection details"
echo "2. In Cursor, go to Settings > Features > MCP"
echo "3. Enable MCP and add supabase-sql as a server"
echo "4. Use Claude to execute SQL queries on your database" 