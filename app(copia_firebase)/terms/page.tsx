'use client';

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';

export default function TermsOfServicePage() {
  return (
    <div className="max-w-4xl mx-auto">
      <Card>
        <CardHeader>
          <CardTitle className="font-headline text-3xl">
            Términos y Condiciones (Versión de Demostración)
          </CardTitle>
          <CardDescription>
            Última actualización: [Fecha Actual]
          </CardDescription>
        </CardHeader>
        <CardContent className="prose prose-sm max-w-none text-foreground dark:prose-invert">
          <h2>Aviso Importante</h2>
          <p className="font-semibold text-destructive">
            Este documento es una plantilla utilizada únicamente con fines de demostración y desarrollo para el prototipo de Plads Pro. No constituye un acuerdo legalmente vinculante. Si esta aplicación pasa a una fase de producción con usuarios reales, se redactará y se comunicará un nuevo anexo con términos y condiciones formales y validados legalmente.
          </p>

          <h2>1. Aceptación de los Términos</h2>
          <p>
            Al acceder y utilizar el prototipo de Plads Pro (el "Servicio"), aceptas cumplir con estos términos y condiciones de demostración. Si no estás de acuerdo, no utilices el Servicio.
          </p>

          <h2>2. Propósito del Servicio</h2>
          <p>
            Este Servicio es un prototipo en fase de desarrollo. Su único propósito es demostrar la funcionalidad y recoger feedback. Los datos introducidos pueden no ser persistentes y la funcionalidad puede cambiar sin previo aviso.
          </p>

          <h2>3. Cuentas de Usuario</h2>
          <p>
            Para utilizar el Servicio, debes autenticarte utilizando una cuenta de Google. Eres responsable de mantener la seguridad de tu cuenta. Cualquier dato asociado a tu cuenta durante esta fase de demostración puede ser eliminado en cualquier momento.
          </p>

          <h2>4. Uso Aceptable</h2>
          <p>
            Te comprometes a no utilizar el Servicio para ningún propósito ilegal o no autorizado. Aceptas no generar contenido que sea ofensivo, dañino o que viole los derechos de otros.
          </p>

          <h2>5. Limitación de Responsabilidad</h2>
          <p>
            El Servicio se proporciona "tal cual", sin garantías de ningún tipo. Plads Pro no será responsable de ninguna pérdida de datos, interrupción del servicio o cualquier otro daño que pueda ocurrir durante el uso de este prototipo.
          </p>

          <h2>6. Propiedad Intelectual</h2>
          <p>
            La marca "Plads Pro" y el diseño de la aplicación son propiedad de sus respectivos dueños. No se te concede ninguna licencia para usar la marca o el diseño fuera del contexto del uso de este prototipo.
          </p>

          <h2>7. Terminación</h2>
          <p>
            Nos reservamos el derecho de suspender o terminar tu acceso al Servicio en cualquier momento, sin previo aviso, por cualquier motivo, incluido el incumplimiento de estos Términos.
          </p>

          <h2>8. Cambios a los Términos</h2>
          <p>
            Como se mencionó anteriormente, estos son términos de demostración. Si la aplicación pasa a producción, estos términos serán reemplazados por un documento formal y se te notificará sobre los cambios.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
