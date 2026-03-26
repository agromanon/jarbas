import { auth } from 'thepopebot/auth';
import { SettingsChatPage } from 'thepopebot/chat';

export default async function ChatSettingsRoute() {
  const session = await auth();
  return <SettingsChatPage session={session} />;
}
