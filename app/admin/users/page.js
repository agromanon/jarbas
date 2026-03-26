import { auth } from 'thepopebot/auth';
import { SettingsUsersPage } from 'thepopebot/chat';

export default async function UsersSettingsRoute() {
  const session = await auth();
  return <SettingsUsersPage session={session} />;
}
