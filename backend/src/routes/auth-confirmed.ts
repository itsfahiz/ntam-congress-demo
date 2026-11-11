import { Router } from 'express';

export const authConfirmedRouter = Router();

const PAGE = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="referrer" content="no-referrer">
  <title>Email verified · NTAM Congress</title>
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
      margin: 14px 0 10px;
      font-size: 1.45rem;
      line-height: 1.3;
      font-weight: 800;
    }
    .lede {
      color: rgba(255, 255, 255, 0.82);
      font-size: 1rem;
      line-height: 1.45;
    }
  </style>
</head>
<body>
  <main>
    <p class="kicker">NTAM Congress</p>
    <h1>Email verified successfully</h1>
    <p class="lede">Return to the Congress app and sign in.</p>
  </main>
  <script>
    if (window.location.hash || window.location.search) {
      history.replaceState(null, "", window.location.pathname);
    }
  </script>
</body>
</html>
`;

authConfirmedRouter.get('/auth/confirmed', (_req, res) => {
  res
    .status(200)
    .set({
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'no-referrer',
    })
    .send(PAGE);
});
