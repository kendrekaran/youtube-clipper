import { drizzle } from 'drizzle-orm/postgres-js'
import postgres from 'postgres'

const connectionString = process.env.DATABASE_URL || ""

// In local-dev mode without DATABASE_URL, export a placeholder that throws
// only when actually used. The auth module avoids touching this when
// DATABASE_URL is absent.
const client = connectionString
  ? postgres(connectionString, { prepare: false })
  : (new Proxy({}, {
      get() {
        throw new Error('DATABASE_URL not set — DB access is disabled in local-dev mode.');
      },
    }) as unknown as ReturnType<typeof postgres>);

const db = connectionString
  ? drizzle(client)
  : (new Proxy({}, {
      get() {
        throw new Error('DATABASE_URL not set — DB access is disabled in local-dev mode.');
      },
    }) as unknown as ReturnType<typeof drizzle>);

export default db;
