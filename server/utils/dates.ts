/**
 * Safe date serialization utilities for the Neon serverless driver.
 *
 * The Neon driver may return timestamp columns as either Date objects or
 * ISO 8601 strings depending on the runtime environment. Code that calls
 * `.toISOString()` on these values will crash in production if the value
 * is already a string. These helpers normalise the value first.
 */

/** Convert a DB date value (Date | string | null) to an ISO string, or null. */
export function toISOStringSafe(value: unknown): string | null {
  if (value == null) return null;
  if (value instanceof Date) return value.toISOString();
  return String(value);
}

/** Convert a DB date value to a proper Date object, or null. */
export function toDateSafe(value: unknown): Date | null {
  if (value == null) return null;
  if (value instanceof Date) return value;
  const d = new Date(String(value));
  if (isNaN(d.getTime())) return null;
  return d;
}
