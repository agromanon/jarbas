import { middleware as thepopebotMiddleware, config as thepopebotConfig } from 'thepopebot/middleware';
import { NextResponse } from 'next/server';

// Public paths that don't require authentication
const publicPaths = [
  '/api/telegram/weather',
  '/api/telegram/webhook/weather-bot',
  '/api/ping',
];

// Custom middleware that allows public paths
export async function middleware(request) {
  const { pathname } = request.nextUrl;

  // Check if this is a public path
  const isPublicPath = publicPaths.some(path => pathname.startsWith(path));

  if (isPublicPath) {
    // Allow public access
    return NextResponse.next();
  }

  // For all other paths, use thepopebot middleware
  return thepopebotMiddleware(request);
}

// Export thepopebot config
export const config = thepopebotConfig;
