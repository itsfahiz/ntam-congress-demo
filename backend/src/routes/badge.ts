import { Router, type Response } from 'express';
import { z } from 'zod';
import {
  isValidBadgeSignature,
  lookupPublicBadge,
} from '../services/badge-service.js';

export const badgeVerifyRouter = Router();

const verifyQuery = z.strictObject({
  b: z.string().regex(/^NMC-[A-Z0-9-]{1,32}$/),
  s: z.string().regex(/^[a-f0-9]{64}$/i),
});

function escapeHtml(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function verificationPage({
  valid,
  fullName,
  badgeId,
}: {
  valid: boolean;
  fullName?: string;
  badgeId?: string;
}) {
  const status = valid ? 'Valid attendee' : 'Invalid badge';
  const detail = valid
    ? `<p class="name">${escapeHtml(fullName ?? '')}</p>
    <p class="badge">${escapeHtml(badgeId ?? '')}</p>`
    : `<p class="lede">This QR code is not a valid congress badge.</p>`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="referrer" content="no-referrer">
  <title>${status} · NTAM Congress</title>
  <style>
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px 20px;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #04122f;
      color: #f6f7fc;
    }
    main {
      width: 100%;
      max-width: 420px;
      padding: 28px 24px;
      border-radius: 18px;
      background: rgba(28, 74, 148, 0.35);
      border: 1px solid rgba(255, 255, 255, 0.18);
      text-align: center;
    }
    p { margin: 0; }
    .kicker {
      letter-spacing: 0.12em;
      text-transform: uppercase;
      font-size: 11px;
      font-weight: 700;
      color: rgba(255, 255, 255, 0.7);
    }
    h1 {
      margin: 14px 0 12px;
      font-size: 1.35rem;
      font-weight: 800;
    }
    .name { font-size: 1.1rem; font-weight: 700; }
    .badge { margin-top: 8px; color: #f0c14b; font-weight: 700; letter-spacing: 0.04em; }
    .lede { color: rgba(255, 255, 255, 0.82); line-height: 1.45; }
  </style>
</head>
<body>
  <main>
    <p class="kicker">NTAM Congress</p>
    <h1>${status}</h1>
    ${detail}
  </main>
</body>
</html>`;
}

function sendPage(res: Response, html: string) {
  res
    .status(200)
    .set({
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'no-referrer',
    })
    .send(html);
}

badgeVerifyRouter.get('/badge/verify', async (req, res) => {
  const parsed = verifyQuery.safeParse(req.query);
  if (!parsed.success) {
    sendPage(res, verificationPage({ valid: false }));
    return;
  }
  if (!isValidBadgeSignature(parsed.data.b, parsed.data.s)) {
    sendPage(res, verificationPage({ valid: false }));
    return;
  }
  let badge = null;
  try {
    badge = await lookupPublicBadge(parsed.data.b);
  } catch {
    sendPage(res, verificationPage({ valid: false }));
    return;
  }
  if (!badge) {
    sendPage(res, verificationPage({ valid: false }));
    return;
  }
  sendPage(
    res,
    verificationPage({
      valid: true,
      fullName: badge.fullName,
      badgeId: badge.badgeId,
    }),
  );
});
