export interface DbTestTarget {
  url: string;
  backendUrl: string;
  projectRef: string;
  actorId: string;
}

const REF = /^[a-z0-9]{20}$/;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/** Pure guard. Never includes connection strings in thrown errors. */
export function assertDbTestTarget(env: NodeJS.ProcessEnv): DbTestTarget {
  const url = env.DATABASE_TEST_URL;
  const backendUrl = env.DATABASE_TEST_BACKEND_URL;
  const projectRef = env.DATABASE_TEST_PROJECT_REF;
  const devRef = env.DATABASE_DEV_PROJECT_REF;
  const allowlist = env.DATABASE_TEST_ALLOWED_REFS?.split(',').map((ref) => ref.trim()) ?? [];
  const actorId = env.DATABASE_TEST_ACTOR_ID;
  if (!url || !backendUrl || !projectRef || !devRef || !actorId ||
      !REF.test(projectRef) || !REF.test(devRef) || projectRef === devRef ||
      !allowlist.includes(projectRef) || !UUID.test(actorId) ||
      env.DATABASE_TEST_APPROVED !== 'YES') {
    throw new Error('DB integration target is not explicitly approved');
  }
  for (const candidate of [url, backendUrl]) {
    let parsed: URL;
    try { parsed = new URL(candidate); } catch { throw new Error('Invalid DB integration target'); }
    if (!['postgres:', 'postgresql:'].includes(parsed.protocol) ||
        parsed.hostname !== `db.${projectRef}.supabase.co` ||
        parsed.port !== '5432' || parsed.pathname !== '/postgres' ||
        parsed.searchParams.size !== 2 || parsed.searchParams.get('sslmode') !== 'require' ||
        parsed.searchParams.get('sslaccept') !== 'strict' ||
        !parsed.password || parsed.hash) {
      throw new Error('DB integration URL failed target or TLS validation');
    }
  }
  const admin = new URL(url);
  const backend = new URL(backendUrl);
  if (decodeURIComponent(admin.username) !== 'postgres' ||
      decodeURIComponent(backend.username) !== 'wms_backend' ||
      url === backendUrl) {
    throw new Error('DB integration roles are not isolated');
  }
  return { url, backendUrl, projectRef, actorId };
}
