import { auth } from 'thepopebot/auth';
import { JobsPage } from 'thepopebot/chat';

export default async function JobsSettingsRoute() {
  const session = await auth();
  return <JobsPage session={session} />;
}
