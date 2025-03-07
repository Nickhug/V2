const { Client } = require('pg');

async function queryDatabase() {
  const connectionString = 'postgresql://postgres:JetPlaysYT255@db.ubvxaqceclhgflosgvai.supabase.co:5432/postgres';
  
  const client = new Client({
    connectionString: connectionString,
  });

  try {
    await client.connect();
    console.log('Connected to database');
    
    // Query to list all tables
    const tablesQuery = `
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `;
    
    const tablesResult = await client.query(tablesQuery);
    
    console.log('\nTables in the database:');
    console.log('=====================');
    
    if (tablesResult.rows.length === 0) {
      console.log('No tables found');
    } else {
      for (const row of tablesResult.rows) {
        const tableName = row.table_name;
        console.log(`\n## Table: ${tableName}`);
        
        // Get column information for this table
        const columnsQuery = `
          SELECT column_name, data_type, is_nullable 
          FROM information_schema.columns 
          WHERE table_schema = 'public' AND table_name = $1
          ORDER BY ordinal_position;
        `;
        
        const columnsResult = await client.query(columnsQuery, [tableName]);
        
        console.log('Columns:');
        columnsResult.rows.forEach(column => {
          console.log(`  - ${column.column_name} (${column.data_type}, ${column.is_nullable === 'YES' ? 'nullable' : 'not nullable'})`);
        });
        
        // Get primary key information
        const pkQuery = `
          SELECT c.column_name
          FROM information_schema.table_constraints tc
          JOIN information_schema.constraint_column_usage AS ccu USING (constraint_schema, constraint_name)
          JOIN information_schema.columns AS c ON c.table_schema = tc.constraint_schema
            AND tc.table_name = c.table_name AND ccu.column_name = c.column_name
          WHERE constraint_type = 'PRIMARY KEY' AND tc.table_name = $1;
        `;
        
        const pkResult = await client.query(pkQuery, [tableName]);
        
        if (pkResult.rows.length > 0) {
          console.log('Primary Key:');
          pkResult.rows.forEach(pk => {
            console.log(`  - ${pk.column_name}`);
          });
        }
        
        console.log('---');
      }
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
    console.log('\nDisconnected from database');
  }
}

queryDatabase(); 