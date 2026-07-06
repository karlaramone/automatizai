import { spawnSync } from 'node:child_process';

process.env.E2E_ENV = 'preview';

const result = spawnSync('yarn', ['playwright', 'test', ...process.argv.slice(2)], {
  stdio: 'inherit',
  shell: true,
});

process.exit(result.status ?? 1);
