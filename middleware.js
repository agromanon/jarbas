/**
 * Custom Middleware Configuration
 *
 * This middleware configuration allows public access to specific webhook endpoints
 * while protecting other routes with authentication.
 */

import { middleware as thepopebotMiddleware, config as thepopebotConfig } from 'thepopebot/middleware';

// Define public paths that don't require authentication
const publicPaths = [
  '/api/telegram/weather',          // Weather webhook endpoint
  '/api/telegram/webhook/weather-bot',  // Weather-bot webhook endpoint
];

// Export custom middleware
export async function middleware(request) {
  const { pathname } = request.nextUrl;

  // Check if the path is public
  const isPublicPath = publicPaths.some(path => pathname.startsWith(path));

  if (isPublicPath) {
    // Allow public access
    return new Response(null, { status: 200 });
  }

  // Otherwise, use the thepopebot middleware
  return thepopebotMiddleware(request);
}

// Export the config
export const config = {
  ...thepopebotConfig,
  matcher: [
    // Exclude public paths from the matcher
    {
      source: '/((?!api/telegram/weather|api/telegram/webhook/weather-bot).*)*',
      missing: [
        () => false,
      ],
    },
  ],
};
