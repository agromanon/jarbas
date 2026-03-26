import { auth } from 'thepopebot/auth';
import { CodingAgentsPage } from 'thepopebot/chat';

export default async function CodingAgentsRoute() {
  const session = await auth();
  return <CodingAgentsPage session={session} />;
}
