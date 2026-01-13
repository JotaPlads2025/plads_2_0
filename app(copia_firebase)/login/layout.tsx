
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Iniciar Sesión | Plads Pro',
  description: 'Inicia sesión en tu cuenta de Plads Pro.',
};

export default function LoginLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return <>{children}</>;
}
