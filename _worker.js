export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const host = url.hostname.toLowerCase();
    const isRituSubdomain = host.startsWith("ritudesigner") || host.startsWith("ritudesinger");

    // 1. If on the Ritu Designer subdomain:
    if (isRituSubdomain) {
      // If root, index, or /ritu-designer, serve the ritu-designer asset (no .html to prevent Cloudflare 307 redirects)
      if (url.pathname === "/" || url.pathname === "" || url.pathname === "/index.html" || url.pathname === "/ritu-designer" || url.pathname === "/ritu-designer.html") {
        const targetUrl = new URL(request.url);
        targetUrl.pathname = "/ritu-designer";
        return env.ASSETS.fetch(new Request(targetUrl.toString(), request));
      }
      // Otherwise serve assets (css, js, images)
      return env.ASSETS.fetch(request);
    }

    // 2. If on main domain (shirajlife.com) visiting old URL -> Redirect to subdomain
    if (url.pathname === "/ritu-designer" || url.pathname === "/ritu-designer.html") {
      return Response.redirect("https://ritudesigner.shirajlife.com/", 301);
    }

    // Default: serve all other static files and pages
    return env.ASSETS.fetch(request);
  }
};
