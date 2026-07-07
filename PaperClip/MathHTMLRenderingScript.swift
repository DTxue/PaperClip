let renderingScript = """
<script>
  (() => {
    const reportHeight = () => {
      const target = document.querySelector('main') || document.body;
      const measuredHeight = target.getBoundingClientRect().height;
      window.webkit.messageHandlers.paperClipHeight.postMessage(
        Math.max(1, Math.ceil(measuredHeight))
      );
    };
    const render = () => {
      if (window.renderMathInElement) {
        renderMathInElement(document.body, {
          delimiters: [
            {left: '$$', right: '$$', display: true},
            {left: '$', right: '$', display: false},
            {left: '\\\\(', right: '\\\\)', display: false},
            {left: '\\\\[', right: '\\\\]', display: true}
          ],
          throwOnError: false
        });
      }
      reportHeight();
    };
    new ResizeObserver(reportHeight).observe(document.querySelector('main') || document.body);
    document.addEventListener('DOMContentLoaded', render);
    window.addEventListener('load', render);
    setTimeout(render, 250);
    setTimeout(render, 1200);
  })();
</script>
"""
