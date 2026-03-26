import { auth } from 'thepopebot/auth';
import { TriggersPage } from 'thepopebot/chat';

export default async function TriggersSettingsRoute() {
  const session = await auth();
  return <TriggersPage session={session} />;
}
