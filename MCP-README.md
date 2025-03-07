# Model Context Protocol (MCP) Setup for Supabase

This project uses Cursor's Model Context Protocol (MCP) to enable direct SQL access to the Supabase database.

## Configuration

The MCP is configured in the `.cursor/mcp.json` file, which contains:

```json
{
  "mcpServers": {
    "supabase-sql": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "--connection-string",
        "postgresql://postgres:PASSWORD@PROJECT-REF.supabase.co:5432/postgres"
      ]
    }
  }
}
```

## How to Use

1. The MCP server is installed locally in the project.
2. When you start Cursor, the MCP server will be available to use.
3. You can query the database directly through Claude by asking SQL-related questions.

## Example Queries

```sql
-- List all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Examine a specific table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'YOUR_TABLE_NAME';

-- Check Row Level Security (RLS) policies
SELECT * FROM pg_policies;
```

## Troubleshooting

If you encounter connection issues:

1. Verify the connection string in `mcp.json` is correct
2. Ensure your Supabase project is online
3. Check that your IP address is allowed in Supabase

To restart the MCP server, run:
```bash
npx @modelcontextprotocol/server-postgres --connection-string "YOUR_CONNECTION_STRING"
``` 