import { auth } from 'thepopebot/auth';
import { CronsPage } from 'thepopebot/chat';

export default async function CronsSettingsRoute() {
  const session = await auth();
  return <CronsPage session={session} />;
}
