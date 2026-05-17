// LOCAL-DEV STUB: Patched so the app runs without Google OAuth / Neon DB.
// When DATABASE_URL is missing, we expose a stubbed `auth` object so that
// imports don't crash. The frontend bypasses authentication in this mode.

import { betterAuth } from 'better-auth';
import { drizzleAdapter } from 'better-auth/adapters/drizzle';

const HAS_DB = Boolean(process.env.DATABASE_URL);
const HAS_GOOGLE =
  Boolean(process.env.GOOGLE_CLIENT_ID) && Boolean(process.env.GOOGLE_CLIENT_SECRET);

export const AUTH_DISABLED = !HAS_DB;

const LOCAL_USER = {
  id: 'local-user',
  email: 'local@dev.local',
  name: 'Local User',
  emailVerified: true,
  image: null,
};

function makeStubAuth() {
  // A minimal stand-in for the better-auth instance used elsewhere.
  // It implements just enough of the surface area the rest of the app touches.
  const notFound = () =>
    new Response(JSON.stringify({ error: 'Auth disabled in local dev' }), {
      status: 404,
      headers: { 'content-type': 'application/json' },
    });

  return {
    handler: async () => notFound(),
    api: {
      getSession: async () => ({
        user: LOCAL_USER,
        session: { id: 'local-session', userId: LOCAL_USER.id },
      }),
    },
  } as any;
}

function makeRealAuth() {
  // Lazy require so we only touch the DB adapter when DATABASE_URL exists.
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const db = require('@/lib/db').default;
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const schema = require('@/lib/schema');

  return betterAuth({
    socialProviders: HAS_GOOGLE
      ? {
          google: {
            clientId: process.env.GOOGLE_CLIENT_ID!,
            clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
          },
        }
      : undefined,
    database: drizzleAdapter(db, { provider: 'pg', schema }),
    secret: process.env.BETTER_AUTH_SECRET || 'local-dev-insecure-secret-change-me',
    baseURL: process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000',
    trustedOrigins: (
      process.env.TRUSTED_ORIGINS ||
      `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}`
    )
      .split(/,\s*/)
      .filter(Boolean),
    emailAndPassword: { enabled: true },
  });
}

export const auth = HAS_DB ? makeRealAuth() : makeStubAuth();
