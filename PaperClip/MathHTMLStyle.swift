let sharedStyle = """
<style>
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; background: transparent; }
  body {
    font: -apple-system-body;
    line-height: 1.65;
    overflow-wrap: anywhere;
    color: #1c1c1e;
    -webkit-text-size-adjust: 100%;
  }
  main { display: grid; gap: 20px; }
  section {
    padding: 16px;
    border-radius: 14px;
    background: rgba(255, 255, 255, 0.86);
  }
  .section-title {
    display: flex;
    align-items: center;
    gap: 10px;
    margin: 0 0 12px;
    font: -apple-system-title3;
    font-weight: 700;
  }
  .section-icon {
    display: inline-grid;
    place-items: center;
    width: 28px;
    height: 28px;
    border-radius: 8px;
    font-size: 17px;
    color: #2563eb;
    background: rgba(37, 99, 235, 0.12);
  }
  .recognition { box-shadow: 0 1px 0 rgba(0, 0, 0, 0.04); }
  .recognition .content { font-size: 1.03em; line-height: 1.85; }
  .embedded-content { font-size: 1em; line-height: 1.65; }
  h3 {
    margin: 0 0 7px;
    font: -apple-system-headline;
    font-weight: 600;
  }
  ol, ul { margin: 0; padding-left: 1.45em; }
  li + li { margin-top: 16px; }
  .answer { font-weight: 600; color: #075985; }
  .mistakes li::marker { color: #c2410c; }
  .katex-display {
    overflow-x: auto;
    overflow-y: hidden;
    padding: 6px 0;
  }
  @media (prefers-color-scheme: dark) {
    body { color: #ebebf5; }
    section { background: rgba(44, 44, 46, 0.86); }
    .section-icon {
      color: #93c5fd;
      background: rgba(96, 165, 250, 0.18);
    }
    .answer { color: #7dd3fc; }
    .mistakes li::marker { color: #fdba74; }
  }
</style>
"""
