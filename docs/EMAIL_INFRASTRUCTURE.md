# Email Infrastructure

**Current state:** Supabase Auth emails (signup confirmation, password
reset, etc.) are sent via **Titan Business Email** SMTP
(`smtp.titan.email`), configured directly in the Supabase dashboard
under Authentication → Settings → SMTP Settings, using the
`founder@aevoria.space` mailbox.

This replaces Supabase's default built-in mailer, which is
deliberately rate-limited to a handful of emails/hour and is only
meant for local development — it cannot support real user signups at
any volume.

## Known limitation

Titan is a general-purpose business mailbox, not a dedicated
transactional email service. It works, but transactional providers
(built specifically for high-volume auth/notification email) generally
offer better inbox deliverability, retry/bounce handling, and delivery
analytics than routing through a regular mailbox's SMTP.

## Deferred: migrate to a dedicated transactional provider

**Not urgent — revisit once signup volume grows enough that
deliverability actually matters.** Candidates, both with generous free
tiers:

- **Resend** — modern API, straightforward Next.js integration if we
  ever want to send transactional email directly from app code
  (receipts, marketplace notifications) rather than only through
  Supabase's built-in auth email flow.
- **Postmark** — long-established reputation specifically for
  transactional (not marketing) email deliverability.

Migration is just re-pointing Supabase's SMTP Settings to the new
provider's SMTP credentials — no application code changes required
for the auth-email path itself.
