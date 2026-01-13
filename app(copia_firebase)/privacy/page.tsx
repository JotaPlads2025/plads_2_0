'use client';

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';

export default function PrivacyPolicyPage() {
  return (
    <div className="max-w-4xl mx-auto">
      <Card>
        <CardHeader>
          <CardTitle className="font-headline text-3xl">
            Política de Privacidad (Versión de Demostración)
          </CardTitle>
          <CardDescription>
            Última actualización: [Fecha Actual]
          </CardDescription>
        </CardHeader>
        <CardContent className="prose prose-sm max-w-none text-foreground dark:prose-invert">
          <h2>Aviso Importante</h2>
          <p className="font-semibold text-destructive">
            Este documento es una plantilla utilizada únicamente con fines de demostración y desarrollo para el prototipo de Plads Pro. No constituye un acuerdo legalmente vinculante. Si esta aplicación pasa a una fase de producción con usuarios reales, se redactará y se comunicará un nuevo anexo con una política de privacidad formal y validada legalmente.
          </p>
          
          <h2>1. Introducción</h2>
          <p>
            Bienvenido a Plads Pro. Esta política de privacidad explica cómo recopilamos, usamos y protegemos tu información personal cuando utilizas nuestro servicio de autenticación a través de Google.
          </p>

          <h2>2. Información que Recopilamos</h2>
          <p>
            Al iniciar sesión con tu cuenta de Google, solicitamos acceso a la siguiente información básica de tu perfil:
          </p>
          <ul>
            <li>
              <strong>Nombre completo:</strong> Para personalizar tu experiencia y dirigirnos a ti correctamente.
            </li>
            <li>
              <strong>Dirección de correo electrónico:</strong> Para identificarte de forma única en nuestro sistema y comunicarnos contigo.
            </li>
            <li>
              <strong>Foto de perfil:</strong> Para mostrarla en tu perfil de usuario dentro de la aplicación.
            </li>
            <li>
              <strong>Identificador único de Google (User ID):</strong> Para vincular tu cuenta de Google con tu cuenta de Plads Pro.
            </li>
          </ul>
          <p>
            No solicitamos ni almacenamos información sensible como contraseñas, datos de pago (fuera de los procesadores de pago seguros) o acceso a tus documentos de Google Drive.
          </p>

          <h2>3. Cómo Usamos tu Información</h2>
          <p>
            Utilizamos la información recopilada para:
          </p>
          <ul>
            <li>Crear y gestionar tu cuenta de usuario en Plads Pro.</li>
            <li>Proporcionar y mejorar nuestros servicios.</li>
            <li>Personalizar el contenido y la experiencia del usuario.</li>
            <li>Comunicarnos contigo sobre tu cuenta o actualizaciones del servicio.</li>
          </ul>

          <h2>4. Cómo Protegemos tu Información</h2>
          <p>
            Tomamos medidas razonables para proteger tu información personal. Utilizamos los servicios de autenticación seguros de Firebase y Google para gestionar las credenciales de inicio de sesión, lo que significa que nunca almacenamos tu contraseña.
          </p>
          
          <h2>5. Intercambio de Información</h2>
          <p>
            No vendemos, alquilamos ni compartimos tu información personal con terceros con fines de marketing. Tu información solo se utiliza para el funcionamiento interno de la aplicación Plads Pro.
          </p>

          <h2>6. Cambios a esta Política</h2>
          <p>
            Como se mencionó anteriormente, esta es una política de demostración. Si la aplicación pasa a producción, esta política será reemplazada por un documento formal y se te notificará sobre los cambios.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
