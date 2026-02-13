/**
 * Example query: Count documents in a collection
 *
 * Usage: npx tsx scripts/db-query.ts example-count-docs <collection>
 *
 * This is a TEST query — not production code.
 * Uses the mongo core wrapper exclusively.
 */

import { count } from '../../src/core/db/index.js';

export default {
  name: 'example-count-docs',
  description: 'Count documents in any collection',

  async run(args: string[]): Promise<void> {
    const collection = args[0];
    if (!collection) {
      console.error('  Usage: example-count-docs <collection>');
      process.exit(1);
    }

    const total = await count(collection);
    console.log(`  Collection "${collection}" has ${total} documents.`);
  },
};
