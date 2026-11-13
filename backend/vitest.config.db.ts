import { defineConfig } from 'vitest/config';
import { assertDbTestTarget } from './test/db-integration/target.js';

// Fail before loading any database test file. B7 never executes this config.
assertDbTestTarget(process.env);

export default defineConfig({
  test: {
    include: ['test/db-integration/**/*.dbtest.ts'],
    fileParallelism: false,
    testTimeout: 30_000,
    hookTimeout: 30_000,
  },
});
