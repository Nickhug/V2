# Setting Up MCP for Supabase SQL Access

This guide will help you set up Model Context Protocol (MCP) to allow Claude AI in Cursor to access and manipulate your Supabase database directly.

## Prerequisites

- Cursor Editor installed
- Node.js and npm installed
- A Supabase project with database access

## Step 1: Find Your Supabase Connection Details

1. Log in to your Supabase dashboard at https://app.supabase.com
2. Select your project
3. Go to Settings > Database 
4. Find the Connection String information
5. Note your:
   - Host: `[YOUR-PROJECT-REF].supabase.co`
   - Database name: `postgres`
   - Port: `5432`
   - User: `postgres`
   - Password: (your database password)

## Step 2: Install the MCP Server

Run the installation script:

```bash
chmod +x install-mcp-server.sh
./install-mcp-server.sh
```

## Step 3: Configure MCP

1. Edit the `.cursor/mcp.json` file with your Supabase connection details:

```json
{
  "mcpServers": {
    "supabase-sql": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "--connection-string",
        "postgresql://postgres:[YOUR-DB-PASSWORD]@[YOUR-PROJECT-REF].supabase.co:5432/postgres"
      ]
    }
  }
}
```

Replace:
- `[YOUR-DB-PASSWORD]` with your database password
- `[YOUR-PROJECT-REF]` with your project reference (from the host)

## Step 4: Enable MCP in Cursor

1. Open Cursor
2. Go to Settings > Features > MCP
3. Enable MCP
4. Add `supabase-sql` as a server
5. Click Save

## Step 5: Test the Connection

Ask Claude to run a simple SQL query:

```
Can you please show me the tables in my Supabase database?
```

Claude should now be able to execute SQL queries directly on your Supabase database.

## Security Considerations

- The MCP server has full access to your database, so be careful with the queries you allow
- Consider creating a read-only role for the MCP connection if you're concerned about data manipulation
- Always review SQL statements before allowing them to execute

## Troubleshooting

- If you encounter connection issues, verify your Supabase connection details
- Ensure your IP address is allowed in Supabase's database settings
- Check Cursor's console for MCP server errors 