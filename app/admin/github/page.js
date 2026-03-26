import { auth } from 'thepopebot/auth';
import { SettingsGitHubPage } from 'thepopebot/chat';

export default async function GitHubSettingsRoute() {
  const session = await auth();
  return <SettingsGitHubPage session={session} />;
}
