import { auth } from 'thepopebot/auth';
import { LlmsPage } from 'thepopebot/chat';

export default async function LlmsRoute() {
  const session = await auth();
  return <LlmsPage session={session} />;
}
