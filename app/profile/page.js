import { auth } from 'thepopebot/auth';
import { ProfileLayout } from 'thepopebot/chat';

export default async function ProfileRoute() {
  const session = await auth();
  return <ProfileLayout session={session} />;
}
