#!/usr/bin/env npx tsx
/**
 * db-query.ts — Test Query Master
 *
 * This is the MASTER INDEX for all database test/dev queries.
 * It is NOT production code — it exists solely for developer exploration.
 *
 * HOW IT WORKS:
 * - Each query lives in its own file under scripts/queries/
 * - Every query file is registered here with a name and description
 * - Run: npx tsx scripts/db-query.ts <query-name> [args...]
 * - Run: npx tsx scripts/db-query.ts --list  (to see all available queries)
 *
 * WHY THIS PATTERN:
 * - Keeps test/dev database code COMPLETELY separate from production code
 * - Every query uses the mongo core wrapper (src/core/db/) — no raw MongoDB
 * - Easy to see at a glance what queries exist and what they do
 * - Individual files are easy to review, modify, and delete
 * - Production code in src/ never touches this — clean separation
 *
 * RULES:
 * - EVERY query file MUST import from '@/core/db/index.js' (the wrapper)
 * - NEVER import 'mongodb' directly in query files
 * - NEVER copy query logic into production code — if you need it in prod,
 *   create a proper handler in src/handlers/
 * - Each query file exports: { name, description, run(args) }
 *
 * Install: npm install tsx -D (if not already installed)
 */

import { closePool } from '../src/core/db/index.js';

// ---------------------------------------------------------------------------
// Query registry — add new queries here
// ---------------------------------------------------------------------------

interface QueryModule {
  name: string;
  description: string;
  run: (args: string[]) => Promise<void>;
}

/**
 * Register all query files here.
 * Each entry maps a command name to its query module path.
 *
 * When Claude creates a new query for you, it will:
 * 1. Create a new file in scripts/queries/<name>.ts
 * 2. Add an entry to this registry
 *
 * Example:
 *   'user-lookup': () => import('./queries/user-lookup.js'),
 */
const queryRegistry: Record<string, () => Promise<{ default: QueryModule }>> = {
  // --- Example queries (remove or modify as needed) ---
  'example-find-user': () => import('./queries/example-find-user.js'),
  'example-count-docs': () => import('./queries/example-count-docs.js'),

  // --- Add your queries below this line ---
};

// ---------------------------------------------------------------------------
// CLI runner
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const command = args[0];

  // Show help
  if (!command || command === '--help' || command === '-h') {
    printUsage();
    return;
  }

  // List all queries
  if (command === '--list' || command === '-l') {
    await listQueries();
    return;
  }

  // Find and run the query
  const loader = queryRegistry[command];
  if (!loader) {
    console.error(`\n  Unknown query: "${command}"\n`);
    console.error('  Run with --list to see available queries.\n');
    process.exit(1);
  }

  try {
    const mod = await loader();
    const query = mod.default;
    console.log(`\n  Running: ${query.name}`);
    console.log(`  ${query.description}\n`);
    await query.run(args.slice(1));
  } catch (err) {
    console.error('\n  Query failed:', err);
    process.exit(1);
  } finally {
    await closePool();
  }
}

function printUsage(): void {
  console.log(`
  db-query — Test Query Master

  Usage:
    npx tsx scripts/db-query.ts <query-name> [args...]
    npx tsx scripts/db-query.ts --list

  Options:
    --list, -l     List all registered queries
    --help, -h     Show this help message

  Examples:
    npx tsx scripts/db-query.ts example-find-user test@example.com
    npx tsx scripts/db-query.ts example-count-docs users
    npx tsx scripts/db-query.ts --list
  `);
}

async function listQueries(): Promise<void> {
  console.log('\n  Available queries:\n');

  for (const [name, loader] of Object.entries(queryRegistry)) {
    try {
      const mod = await loader();
      console.log(`    ${name.padEnd(30)} ${mod.default.description}`);
    } catch {
      console.log(`    ${name.padEnd(30)} (failed to load)`);
    }
  }

  console.log('');
  await closePool();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
