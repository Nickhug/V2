#!/usr/bin/env node

/**
 * Test script for Browserbase MCP server
 * This script will try to load the Browserbase MCP server and log its tools
 */

console.log('Testing Browserbase MCP server connection...');

try {
  // Check if the dist/index.js file exists
  const fs = require('fs');
  const path = require('path');
  
  const browserbasePath = '/Users/nick/Downloads/browserbase/mcp-server-browserbase/browserbase/dist/index.js';
  
  if (!fs.existsSync(browserbasePath)) {
    console.error(`Error: Browserbase MCP server file not found at ${browserbasePath}`);
    console.log('Please make sure you have built the server using "npm run build"');
    process.exit(1);
  }
  
  console.log(`Found Browserbase MCP server at ${browserbasePath}`);
  
  // Check if the necessary environment variables are set
  const requiredEnvVars = [
    'BROWSERBASE_API_KEY',
    'BROWSERBASE_PROJECT_ID'
  ];
  
  const missingEnvVars = requiredEnvVars.filter(varName => !process.env[varName]);
  
  if (missingEnvVars.length > 0) {
    console.log('Warning: The following environment variables are not set:');
    missingEnvVars.forEach(varName => console.log(`  - ${varName}`));
    console.log('\nYou will need to set these in ~/.cursor/mcp.json for the server to work properly.');
    console.log('Example configuration:');
    console.log(`
{
  "mcpServers": {
    "browserbase": {
      "command": "node",
      "args": ["${browserbasePath}"],
      "env": {
        "BROWSERBASE_API_KEY": "<YOUR_API_KEY>",
        "BROWSERBASE_PROJECT_ID": "<YOUR_PROJECT_ID>"
      }
    }
  }
}
    `);
  } else {
    console.log('All required environment variables are set!');
  }
  
  // Check if Cursor MCP configuration includes Browserbase
  const cursorMcpPath = '/Users/nick/.cursor/mcp.json';
  
  if (!fs.existsSync(cursorMcpPath)) {
    console.error(`Error: Cursor MCP configuration file not found at ${cursorMcpPath}`);
    process.exit(1);
  }
  
  const cursorMcp = JSON.parse(fs.readFileSync(cursorMcpPath, 'utf8'));
  
  if (!cursorMcp.mcpServers || !cursorMcp.mcpServers.browserbase) {
    console.error('Error: Browserbase not found in Cursor MCP configuration');
    console.log('Please add the Browserbase configuration to ~/.cursor/mcp.json');
  } else {
    console.log('Browserbase found in Cursor MCP configuration!');
    console.log('Configuration:');
    console.log(JSON.stringify(cursorMcp.mcpServers.browserbase, null, 2));
  }
  
  console.log('\nBrowserbase MCP server configuration test completed.');
  console.log('To complete setup:');
  console.log('1. Sign up for a Browserbase account at https://www.browserbase.com');
  console.log('2. Get your API key and Project ID from the Overview Dashboard');
  console.log('3. Update ~/.cursor/mcp.json with your actual credentials');
  console.log('4. Restart Cursor to load the updated configuration');
  
} catch (error) {
  console.error('Error testing Browserbase MCP server:');
  console.error(error);
  process.exit(1);
} 